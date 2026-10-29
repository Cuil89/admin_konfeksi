import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import 'models.dart';
import 'secure_vault.dart';
import 'seed.dart';

/// Thrown when a business rule rejects an operation. [message] is safe to
/// show to the user.
class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

@immutable
class PayrollTotals {
  const PayrollTotals({
    required this.base,
    required this.allowance,
    required this.deduction,
    required this.count,
    required this.paidCount,
    required this.readyCount,
    required this.reviewCount,
    required this.paidAmount,
    required this.readyAmount,
    required this.reviewAmount,
    required this.departments,
  });

  final int base;
  final int allowance;
  final int deduction;
  final int count;
  final int paidCount;
  final int readyCount;
  final int reviewCount;
  final int paidAmount;
  final int readyAmount;
  final int reviewAmount;
  final int departments;

  int get gross => base + allowance;
  int get net => gross - deduction;
  int get unpaidAmount => readyAmount + reviewAmount;
  double get paidRatio => count == 0 ? 0 : paidCount / count;
  double get baseRatio => gross == 0 ? 0 : base / gross;
  double get allowanceRatio => gross == 0 ? 0 : allowance / gross;
}

/// Single source of truth for the app. All mutations go through here so that
/// business rules (payroll ↔ kasbon sync, validation, audit trail and
/// encrypted persistence) are enforced in one place.
class AppStore extends ChangeNotifier {
  AppStore(this._vault);

  static const _storageKey = 'payrole.data.v1';
  static const _schemaVersion = 1;
  static const maxMoney = 10000000000; // Rp10 miliar – sanity cap
  static const _maxAudit = 300;

  final SecureVault _vault;
  Timer? _saveTimer;

  bool _ready = false;
  bool get isReady => _ready;

  List<Employee> _employees = [];
  List<Loan> _loans = [];
  List<AttendanceRecord> _attendance = [];
  List<Reimbursement> _reimbursements = [];
  List<AuditEntry> _audit = [];
  List<KonveksiRecord> _konveksiRecords = List.of(Seed.konveksiRecords());
  AppSettings _settings = const AppSettings();
  int _periodYear = Seed.periodYear;
  int _periodMonth = Seed.periodMonth;
  DateTime _lastUpdated = Seed.lastUpdated;

  // ------------------------------------------------------------------ getters
  List<Employee> get employees => List.unmodifiable(_employees);
  List<Employee> get activeEmployees =>
      _employees.where((e) => e.active).toList(growable: false);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<Reimbursement> get reimbursements => List.unmodifiable(_reimbursements);
  List<AuditEntry> get audit => List.unmodifiable(_audit);
  List<KonveksiRecord> get konveksiRecords => List.unmodifiable(_konveksiRecords);
  AppSettings get settings => _settings;
  DateTime get lastUpdated => _lastUpdated;
  int get periodYear => _periodYear;
  int get periodMonth => _periodMonth;

  int get konveksiTotalNet => _konveksiRecords.fold(0, (s, r) => s + r.netWage);
  int get konveksiTotalGross => _konveksiRecords.fold(0, (s, r) => s + r.grossWage);
  int get konveksiTotalBase => _konveksiRecords.fold(0, (s, r) => s + r.baseWage);
  int get konveksiTotalOvertime => _konveksiRecords.fold(0, (s, r) => s + r.overtime);
  int get konveksiTotalLoanDeduction => _konveksiRecords.fold(0, (s, r) => s + r.loanDeduction);
  int get konveksiTotalRemainingLoan => _konveksiRecords.fold(0, (s, r) => s + r.remainingLoan);
  double get konveksiTotalDays => _konveksiRecords.fold(0.0, (s, r) => s + r.days);
  List<CashDenomination> get konveksiCashDenominations =>
      CashBreakdown.totalBreakdown(_konveksiRecords.map((r) => r.netWage));

  String _currentRole = 'Pemilik';
  String get currentRole => _currentRole;
  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  String get periodLabel => Fmt.monthYear(_periodYear, _periodMonth);
  DateTime get periodStart => DateTime(_periodYear, _periodMonth, 1);
  DateTime get periodEnd => DateTime(_periodYear, _periodMonth + 1, 0);
  DateTime get payday => DateTime(_periodYear, _periodMonth, _settings.payday);

  Employee? employeeById(String id) {
    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  int loanDeductionFor(String employeeId) => _loans
      .where((l) => l.employeeId == employeeId && l.syncToPayroll)
      .fold(0, (sum, l) => sum + l.deduction);

  PayrollLine lineFor(Employee e) =>
      PayrollLine(employee: e, loanDeduction: loanDeductionFor(e.id));

  List<PayrollLine> get payrollLines =>
      activeEmployees.map(lineFor).toList(growable: false);

  PayrollTotals get totals => totalsOf(payrollLines);

  PayrollTotals totalsOf(List<PayrollLine> lines) {
    var base = 0, allowance = 0, deduction = 0;
    var paidC = 0, readyC = 0, reviewC = 0;
    var paidA = 0, readyA = 0, reviewA = 0;
    final depts = <String>{};
    for (final l in lines) {
      base += l.base;
      allowance += l.allowance;
      deduction += l.deduction;
      depts.add(l.employee.department);
      switch (l.status) {
        case PayrollStatus.paid:
          paidC++;
          paidA += l.net;
        case PayrollStatus.ready:
          readyC++;
          readyA += l.net;
        case PayrollStatus.review:
          reviewC++;
          reviewA += l.net;
      }
    }
    return PayrollTotals(
      base: base,
      allowance: allowance,
      deduction: deduction,
      count: lines.length,
      paidCount: paidC,
      readyCount: readyC,
      reviewCount: reviewC,
      paidAmount: paidA,
      readyAmount: readyA,
      reviewAmount: reviewA,
      departments: depts.length,
    );
  }

  int get loanOutstanding => _loans.fold(0, (s, l) => s + l.remaining);
  int get loanDebtorCount =>
      _loans.map((l) => l.employeeId).toSet().length;

  /// Kalkulasi sub total gaji per minggu berdasarkan kehadiran harian.
  List<WeeklyPayrollLine> weeklyPayrollLines({int weekIndex = 1}) {
    final year = _periodYear;
    final month = _periodMonth;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;

    final int startDay;
    final int endDay;
    switch (weekIndex) {
      case 1:
        startDay = 1;
        endDay = math.min(7, lastDayOfMonth);
        break;
      case 2:
        startDay = 8;
        endDay = math.min(14, lastDayOfMonth);
        break;
      case 3:
        startDay = 15;
        endDay = math.min(21, lastDayOfMonth);
        break;
      case 4:
        startDay = 22;
        endDay = math.min(28, lastDayOfMonth);
        break;
      case 5:
      default:
        startDay = 29;
        endDay = lastDayOfMonth;
        break;
    }

    final startDate = DateTime(year, month, startDay);
    final endDate = DateTime(year, month, endDay);

    final result = <WeeklyPayrollLine>[];
    for (final emp in activeEmployees) {
      var presentDays = 0;
      for (var d = startDay; d <= endDay; d++) {
        final dateKey = Fmt.isoDay(DateTime(year, month, d));
        final rec = _attendance.firstWhere(
          (r) => r.employeeId == emp.id && r.day == dateKey,
          orElse: () => AttendanceRecord(
            employeeId: emp.id,
            day: dateKey,
            status: AttendanceStatus.present,
          ),
        );
        if (rec.status.isPresent) {
          presentDays++;
        }
      }

      final dailyRate = emp.effectiveDailyRate;
      final dailyWageTotal = presentDays * dailyRate;
      final weeklyAllowance = (emp.allowance / 4).round();
      final totalLoanDed = loanDeductionFor(emp.id);
      final weeklyLoanDed = (totalLoanDed / 4).round();
      final subtotalNet = dailyWageTotal + weeklyAllowance - weeklyLoanDed;

      result.add(WeeklyPayrollLine(
        employee: emp,
        weekNumber: weekIndex,
        startDate: startDate,
        endDate: endDate,
        daysPresent: presentDays,
        dailyRate: dailyRate,
        dailyWageTotal: dailyWageTotal,
        weeklyAllowance: weeklyAllowance,
        weeklyLoanDeduction: weeklyLoanDed,
        subtotalNet: subtotalNet,
      ));
    }
    return result;
  }

  List<AttendanceRecord> attendanceFor(DateTime day) {
    final key = Fmt.isoDay(day);
    return _attendance.where((r) => r.day == key).toList(growable: false);
  }

  int absentCount(DateTime day) =>
      attendanceFor(day).where((r) => !r.status.isPresent).length;

  /// Previous recorded working day before [day] (skips weekends / no-data).
  DateTime? previousRecordedDay(DateTime day) {
    var d = Fmt.dayOnly(day);
    for (var i = 0; i < 14; i++) {
      d = d.subtract(const Duration(days: 1));
      if (attendanceFor(d).isNotEmpty) return d;
    }
    return null;
  }

  // ---------------------------------------------------------------- lifecycle
  Future<void> load({DateTime? now}) async {
    var loaded = false;
    try {
      final raw = await _vault.read(_storageKey);
      // Guard against absurdly large / tampered payloads.
      if (raw != null && raw.isNotEmpty && raw.length < 4 * 1024 * 1024) {
        _decode(jsonDecode(raw));
        loaded = true;
      }
    } catch (e) {
      // Never log payload contents (salary data is sensitive).
      debugPrint('Payrole: stored data unreadable, reseeding (${e.runtimeType})');
    }
    if (!loaded) {
      _seed(now ?? DateTime.now());
      _scheduleSave();
    }
    _ready = true;
    notifyListeners();
  }

  void _seed(DateTime now) {
    _employees = Seed.employees();
    _loans = Seed.loans();
    _reimbursements = Seed.reimbursements();
    _attendance = Seed.attendance(_employees, now);
    _konveksiRecords = List.of(Seed.konveksiRecords());
    _settings = const AppSettings();
    _periodYear = Seed.periodYear;
    _periodMonth = Seed.periodMonth;
    _lastUpdated = Seed.lastUpdated;
    _audit = [
      AuditEntry(
        at: Seed.lastUpdated,
        action: 'Data awal dimuat',
        detail: 'Periode ${Fmt.monthYear(Seed.periodYear, Seed.periodMonth)}',
      ),
    ];
  }

  void _decode(Object? json) {
    if (json is! Map) throw const FormatException('root');
    final m = json.cast<String, Object?>();
    List<T> list<T>(String key, T Function(Map<String, Object?>) f) {
      final v = m[key];
      if (v is! List) return <T>[];
      return v
          .whereType<Map>()
          .map((e) => f(e.cast<String, Object?>()))
          .toList();
    }

    final employees = list('employees', Employee.fromJson)
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
    if (employees.isEmpty) throw const FormatException('employees');
    _employees = employees;
    _loans = list('loans', Loan.fromJson);
    _attendance = list('attendance', AttendanceRecord.fromJson);
    _reimbursements = list('reimbursements', Reimbursement.fromJson);
    _audit = list('audit', AuditEntry.fromJson);
    final konveksi = list('konveksi', KonveksiRecord.fromJson);
    _konveksiRecords = konveksi.isNotEmpty ? konveksi : List.of(Seed.konveksiRecords());
    final s = m['settings'];
    _settings = s is Map
        ? AppSettings.fromJson(s.cast<String, Object?>())
        : const AppSettings();
    _periodYear = (m['periodYear'] as num?)?.toInt() ?? Seed.periodYear;
    _periodMonth =
        ((m['periodMonth'] as num?)?.toInt() ?? Seed.periodMonth).clamp(1, 12);
    _lastUpdated =
        DateTime.tryParse(m['lastUpdated'] as String? ?? '') ?? Seed.lastUpdated;
  }

  Map<String, Object?> _encode() => {
        'v': _schemaVersion,
        'periodYear': _periodYear,
        'periodMonth': _periodMonth,
        'lastUpdated': _lastUpdated.toIso8601String(),
        'settings': _settings.toJson(),
        'employees': _employees.map((e) => e.toJson()).toList(),
        'loans': _loans.map((e) => e.toJson()).toList(),
        'attendance': _attendance.map((e) => e.toJson()).toList(),
        'reimbursements': _reimbursements.map((e) => e.toJson()).toList(),
        'audit': _audit.map((e) => e.toJson()).toList(),
        'konveksi': _konveksiRecords.map((k) => k.toJson()).toList(),
      };

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), flush);
  }

  /// Persists immediately (also called when the app goes to background).
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_ready) return;
    try {
      await _vault.write(_storageKey, jsonEncode(_encode()));
    } catch (e) {
      debugPrint('Payrole: failed to persist (${e.runtimeType})');
    }
  }

  void _commit(String action, String detail) {
    _lastUpdated = DateTime.now();
    _audit.insert(0, AuditEntry(at: _lastUpdated, action: action, detail: detail));
    if (_audit.length > _maxAudit) _audit.removeRange(_maxAudit, _audit.length);
    notifyListeners();
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------- utilities
  /// Strips control characters & trims – defends exports (CSV/PDF) and UI
  /// from injected control sequences.
  static String sanitize(String input, {int maxLength = 120}) {
    final cleaned = input
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F\u200B-\u200F\u202A-\u202E]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
  }

  static void _money(int v, String field, {bool allowZero = true}) {
    if (v < 0 || (!allowZero && v == 0)) {
      throw ValidationException('$field harus lebih dari 0.');
    }
    if (v > maxMoney) {
      throw ValidationException('$field melebihi batas wajar.');
    }
  }

  static int estimateBpjsKesehatan(int base) =>
      math.min(base, 12000000) ~/ 100; // 1% karyawan, plafon Rp12 jt

  static int estimateBpjsKetenagakerjaan(int base) =>
      (base * 2 ~/ 100) + (math.min(base, 10547400) ~/ 100); // JHT 2% + JP 1%

  String _nextId(String prefix, Iterable<String> existing) {
    var max = 0;
    for (final id in existing) {
      if (!id.startsWith('$prefix-')) continue;
      final n = int.tryParse(id.substring(prefix.length + 1)) ?? 0;
      if (n > max) max = n;
    }
    return '$prefix-${(max + 1).toString().padLeft(3, '0')}';
  }

  Employee _require(String id) {
    final e = employeeById(id);
    if (e == null) throw const ValidationException('Karyawan tidak ditemukan.');
    return e;
  }

  void _replaceEmployee(Employee e) {
    final i = _employees.indexWhere((x) => x.id == e.id);
    if (i >= 0) _employees[i] = e;
  }

  // ------------------------------------------------------------------ payroll
  void setPayrollStatus(String id, PayrollStatus status) {
    final e = _require(id);
    if (e.status == status) return;
    if (status == PayrollStatus.paid && e.status == PayrollStatus.review) {
      throw ValidationException(
          'Gaji ${e.name} perlu ditinjau sebelum dibayarkan.');
    }
    if (status == PayrollStatus.paid && lineFor(e).net < 0) {
      throw ValidationException('Gaji bersih ${e.name} tidak valid (negatif).');
    }
    _replaceEmployee(e.copyWith(
      status: status,
      paidAt: status == PayrollStatus.paid ? DateTime.now() : null,
      clearPaidAt: status != PayrollStatus.paid,
      clearReviewNote: status != PayrollStatus.review,
    ));
    _commit('Status payroll diubah', '${e.name}: ${e.status.label} → ${status.label}');
  }

  /// Approves a reviewed employee so it becomes payable.
  void approveReview(String id) {
    final e = _require(id);
    if (e.status != PayrollStatus.review) return;
    _replaceEmployee(e.copyWith(status: PayrollStatus.ready, clearReviewNote: true));
    _commit('Payroll ditinjau', '${e.name} disetujui → Siap dibayar');
  }

  void flagForReview(String id, {String? note}) {
    final e = _require(id);
    if (e.status == PayrollStatus.paid) {
      throw const ValidationException('Gaji yang sudah dibayar tidak bisa ditandai ulang.');
    }
    _replaceEmployee(e.copyWith(
      status: PayrollStatus.review,
      reviewNote: note == null ? null : sanitize(note, maxLength: 200),
    ));
    _commit('Payroll ditandai', '${e.name} → Perlu ditinjau');
  }

  /// Pays all [ids] that are `Siap dibayar`. Returns the number processed.
  int processPayroll(Iterable<String> ids) {
    final now = DateTime.now();
    var count = 0;
    var amount = 0;
    for (final id in ids.toSet()) {
      final e = employeeById(id);
      if (e == null || !e.active || e.status != PayrollStatus.ready) continue;
      final net = lineFor(e).net;
      if (net < 0) continue;
      _replaceEmployee(e.copyWith(status: PayrollStatus.paid, paidAt: now));
      count++;
      amount += net;
    }
    if (count > 0) {
      _commit('Payroll diproses', '$count karyawan · ${Fmt.rupiah(amount)}');
    }
    return count;
  }

  void updateComponents(
    String id, {
    required int baseSalary,
    required int allowance,
    required int bpjsKesehatan,
    required int bpjsKetenagakerjaan,
    required int pph21,
    required int otherDeduction,
    bool markReady = false,
  }) {
    final e = _require(id);
    if (e.status == PayrollStatus.paid) {
      throw const ValidationException(
          'Komponen gaji terkunci karena sudah dibayarkan.');
    }
    _money(baseSalary, 'Gaji pokok', allowZero: false);
    _money(allowance, 'Tunjangan');
    _money(bpjsKesehatan, 'BPJS Kesehatan');
    _money(bpjsKetenagakerjaan, 'BPJS Ketenagakerjaan');
    _money(pph21, 'PPh 21');
    _money(otherDeduction, 'Potongan lain');
    final net = baseSalary +
        allowance -
        bpjsKesehatan -
        bpjsKetenagakerjaan -
        pph21 -
        otherDeduction -
        loanDeductionFor(id);
    if (net < 0) {
      throw const ValidationException('Total potongan melebihi gaji bruto.');
    }
    _replaceEmployee(e.copyWith(
      baseSalary: baseSalary,
      allowance: allowance,
      bpjsKesehatan: bpjsKesehatan,
      bpjsKetenagakerjaan: bpjsKetenagakerjaan,
      pph21: pph21,
      otherDeduction: otherDeduction,
      status: markReady ? PayrollStatus.ready : null,
      clearReviewNote: markReady,
    ));
    _commit('Komponen gaji diubah',
        '${e.name}: bersih ${Fmt.rupiah(net)}${markReady ? ' · Siap dibayar' : ''}');
  }

  // -------------------------------------------------------------- kasbon/bon
  void _validateLoan({
    required Employee employee,
    required int amount,
    required int deduction,
    required bool sync,
    Loan? existing,
  }) {
    _money(amount, 'Jumlah bon', allowZero: false);
    if (amount > 1000000000) {
      throw const ValidationException('Jumlah bon maksimal Rp1.000.000.000.');
    }
    _money(deduction, 'Potongan');
    if (deduction > amount) {
      throw const ValidationException('Potongan tidak boleh melebihi jumlah bon.');
    }
    final affectsPayroll = sync || (existing?.syncToPayroll ?? false);
    if (affectsPayroll && employee.status == PayrollStatus.paid) {
      final changed = existing == null ||
          existing.deduction != deduction ||
          existing.syncToPayroll != sync;
      if (changed) {
        throw ValidationException(
            'Gaji ${employee.name} sudah dibayar. Potongan tidak bisa disinkronkan pada periode ini.');
      }
    }
    if (sync) {
      final otherLoans = loanDeductionFor(employee.id) -
          ((existing?.syncToPayroll ?? false) ? existing!.deduction : 0);
      final net = employee.gross - employee.statutoryDeduction - otherLoans - deduction;
      if (net < 0) {
        throw ValidationException(
            'Potongan membuat gaji bersih ${employee.name} negatif.');
      }
    }
  }

  Loan addLoan({
    required String employeeId,
    required int amount,
    required int deduction,
    required bool syncToPayroll,
    String note = '',
  }) {
    final e = _require(employeeId);
    if (!e.active) throw const ValidationException('Karyawan tidak aktif.');
    _validateLoan(
        employee: e, amount: amount, deduction: deduction, sync: syncToPayroll);
    final loan = Loan(
      id: _nextId('BON', _loans.map((l) => l.id)),
      employeeId: employeeId,
      amount: amount,
      deduction: deduction,
      syncToPayroll: syncToPayroll,
      note: sanitize(note),
      createdAt: DateTime.now(),
    );
    _loans.insert(0, loan);
    _commit('Bon dicatat',
        '${e.name}: ${Fmt.rupiah(amount)}${syncToPayroll ? ' · potong gaji ${Fmt.rupiah(deduction)}' : ''}');
    return loan;
  }

  void updateLoan(
    String loanId, {
    required int amount,
    required int deduction,
    required bool syncToPayroll,
    String? note,
  }) {
    final i = _loans.indexWhere((l) => l.id == loanId);
    if (i < 0) throw const ValidationException('Data bon tidak ditemukan.');
    final loan = _loans[i];
    final e = _require(loan.employeeId);
    _validateLoan(
      employee: e,
      amount: amount,
      deduction: deduction,
      sync: syncToPayroll,
      existing: loan,
    );
    _loans[i] = loan.copyWith(
      amount: amount,
      deduction: deduction,
      syncToPayroll: syncToPayroll,
      note: note == null ? null : sanitize(note),
    );
    _commit('Bon diperbarui',
        '${e.name}: potongan ${Fmt.rupiah(deduction)} · sisa ${Fmt.rupiah(_loans[i].remaining)}');
  }

  void setLoanSync(String loanId, bool sync) {
    final loan = _loans.firstWhere((l) => l.id == loanId,
        orElse: () => throw const ValidationException('Data bon tidak ditemukan.'));
    updateLoan(loanId,
        amount: loan.amount, deduction: loan.deduction, syncToPayroll: sync);
  }

  /// Settles the loan: potongan = jumlah bon → sisa 0 → status Lunas.
  void payOffLoan(String loanId, {required bool viaPayroll}) {
    final loan = _loans.firstWhere((l) => l.id == loanId,
        orElse: () => throw const ValidationException('Data bon tidak ditemukan.'));
    updateLoan(loanId,
        amount: loan.amount,
        deduction: loan.amount,
        syncToPayroll: viaPayroll);
  }

  void deleteLoan(String loanId) {
    final i = _loans.indexWhere((l) => l.id == loanId);
    if (i < 0) return;
    final loan = _loans[i];
    final e = employeeById(loan.employeeId);
    if (loan.syncToPayroll && e?.status == PayrollStatus.paid) {
      throw const ValidationException(
          'Bon ini sudah terpotong pada gaji yang dibayarkan dan tidak bisa dihapus.');
    }
    _loans.removeAt(i);
    _commit('Bon dihapus', '${e?.name ?? loan.employeeId}: ${Fmt.rupiah(loan.amount)}');
  }

  // ---------------------------------------------------------------- employees
  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static final _phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

  void _validateEmployeeFields(String name, String email, String phone) {
    if (name.length < 3) throw const ValidationException('Nama minimal 3 karakter.');
    if (!_emailRe.hasMatch(email)) {
      throw const ValidationException('Format email tidak valid.');
    }
    if (!_phoneRe.hasMatch(phone)) {
      throw const ValidationException('Nomor telepon 8–15 digit.');
    }
    final dup = _employees.where((e) => e.email.toLowerCase() == email.toLowerCase());
    if (dup.length > 1) throw const ValidationException('Email sudah digunakan.');
  }

  Employee addEmployee({
    required String name,
    required String department,
    required String position,
    required String email,
    required String phone,
    required DateTime joinDate,
    required int baseSalary,
    required int allowance,
    int? dailyRate,
    String paymentMethod = 'Transfer Bank',
    String? bankAccount,
  }) {
    final n = sanitize(name, maxLength: 60);
    final em = sanitize(email, maxLength: 80).toLowerCase();
    final ph = phone.replaceAll(RegExp(r'[\s-]'), '');
    _validateEmployeeFields(n, em, ph);
    if (_employees.any((e) => e.email.toLowerCase() == em)) {
      throw const ValidationException('Email sudah digunakan.');
    }
    if (!kDepartments.contains(department)) {
      throw const ValidationException('Departemen tidak valid.');
    }
    _money(baseSalary, 'Gaji pokok', allowZero: false);
    _money(allowance, 'Tunjangan');
    if (dailyRate != null && dailyRate > 0) {
      _money(dailyRate, 'Gaji harian');
    }
    final e = Employee(
      id: _nextId('ND', _employees.map((e) => e.id)),
      name: n,
      department: department,
      position: sanitize(position, maxLength: 60),
      email: em,
      phone: ph,
      joinDate: joinDate,
      baseSalary: baseSalary,
      allowance: allowance,
      bpjsKesehatan: estimateBpjsKesehatan(baseSalary),
      bpjsKetenagakerjaan: estimateBpjsKetenagakerjaan(baseSalary),
      pph21: 0,
      status: PayrollStatus.review,
      reviewNote: 'Karyawan baru – lengkapi PPh 21 sebelum dibayarkan.',
      dailyRate: dailyRate,
      paymentMethod: paymentMethod,
      bankAccount: bankAccount != null ? sanitize(bankAccount, maxLength: 60) : null,
    );
    _employees.add(e);
    _commit('Karyawan ditambahkan', '${e.name} (${e.id})');
    return e;
  }

  void updateEmployee(
    String id, {
    required String name,
    required String department,
    required String position,
    required String email,
    required String phone,
    required DateTime joinDate,
    required int baseSalary,
    required int allowance,
    int? dailyRate,
    String? paymentMethod,
    String? bankAccount,
  }) {
    final e = _require(id);
    final n = sanitize(name, maxLength: 60);
    final em = sanitize(email, maxLength: 80).toLowerCase();
    final ph = phone.replaceAll(RegExp(r'[\s-]'), '');
    _validateEmployeeFields(n, em, ph);
    if (_employees.any((x) => x.id != id && x.email.toLowerCase() == em)) {
      throw const ValidationException('Email sudah digunakan.');
    }
    final salaryChanged = baseSalary != e.baseSalary || allowance != e.allowance;
    if (salaryChanged && e.status == PayrollStatus.paid) {
      throw const ValidationException(
          'Gaji periode ini sudah dibayar – perubahan gaji tidak diizinkan.');
    }
    _money(baseSalary, 'Gaji pokok', allowZero: false);
    _money(allowance, 'Tunjangan');
    if (dailyRate != null && dailyRate > 0) {
      _money(dailyRate, 'Gaji harian');
    }
    if (salaryChanged &&
        baseSalary + allowance - e.statutoryDeduction - loanDeductionFor(id) < 0) {
      throw const ValidationException('Gaji baru lebih kecil dari total potongan.');
    }
    _replaceEmployee(e.copyWith(
      name: n,
      department: kDepartments.contains(department) ? department : e.department,
      position: sanitize(position, maxLength: 60),
      email: em,
      phone: ph,
      joinDate: joinDate,
      baseSalary: baseSalary,
      allowance: allowance,
      dailyRate: dailyRate,
      paymentMethod: paymentMethod ?? e.paymentMethod,
      bankAccount: bankAccount != null ? sanitize(bankAccount, maxLength: 60) : e.bankAccount,
    ));
    _commit('Data karyawan diubah', '${e.name} (${e.id})');
  }

  void setEmployeeActive(String id, bool active) {
    final e = _require(id);
    if (e.active == active) return;
    if (!active && e.status == PayrollStatus.paid) {
      // Allowed, but the employee leaves the running payroll list.
    }
    _replaceEmployee(e.copyWith(active: active));
    _commit(active ? 'Karyawan diaktifkan' : 'Karyawan dinonaktifkan', e.name);
  }

  void deleteEmployee(String id) {
    final e = _require(id);
    if (e.status == PayrollStatus.paid) {
      throw const ValidationException(
          'Karyawan sudah menerima gaji periode ini. Nonaktifkan saja.');
    }
    if (_loans.any((l) => l.employeeId == id && !l.isPaidOff)) {
      throw const ValidationException('Karyawan masih memiliki bon yang belum lunas.');
    }
    _employees.removeWhere((x) => x.id == id);
    _loans.removeWhere((l) => l.employeeId == id);
    _attendance.removeWhere((r) => r.employeeId == id);
    _reimbursements.removeWhere((r) => r.employeeId == id);
    _commit('Karyawan dihapus', '${e.name} (${e.id})');
  }

  // --------------------------------------------------------------- attendance
  void setAttendance(String employeeId, DateTime day, AttendanceStatus status) {
    final e = _require(employeeId);
    final key = Fmt.isoDay(day);
    final now = DateTime.now();
    final nowTime = '${Fmt.two(now.hour)}:${Fmt.two(now.minute)}';
    final i = _attendance.indexWhere((r) => r.employeeId == employeeId && r.day == key);
    final present = status.isPresent;
    if (i >= 0) {
      final r = _attendance[i];
      _attendance[i] = present
          ? r.copyWith(status: status, checkIn: r.checkIn ?? nowTime)
          : r.copyWith(status: status, clearTimes: true);
    } else {
      _attendance.add(AttendanceRecord(
        employeeId: employeeId,
        day: key,
        status: status,
        checkIn: present ? nowTime : null,
      ));
    }
    _commit('Kehadiran diubah', '${e.name} · ${Fmt.date(day)}: ${status.label}');
  }

  void markAllPresent(DateTime day) {
    final key = Fmt.isoDay(day);
    var added = 0;
    for (final e in activeEmployees) {
      if (_attendance.any((r) => r.employeeId == e.id && r.day == key)) continue;
      _attendance.add(AttendanceRecord(
        employeeId: e.id,
        day: key,
        status: AttendanceStatus.present,
        checkIn: '08:00',
      ));
      added++;
    }
    if (added > 0) _commit('Kehadiran massal', '$added karyawan hadir · ${Fmt.date(day)}');
  }

  // ------------------------------------------------------------ reimbursement
  Reimbursement addReimbursement({
    required String employeeId,
    required String category,
    required String description,
    required int amount,
    required DateTime date,
  }) {
    final e = _require(employeeId);
    _money(amount, 'Nominal', allowZero: false);
    if (amount > 100000000) {
      throw const ValidationException('Nominal reimbursement maksimal Rp100.000.000.');
    }
    final desc = sanitize(description, maxLength: 120);
    if (desc.length < 3) throw const ValidationException('Keterangan minimal 3 karakter.');
    final r = Reimbursement(
      id: _nextId('RB', _reimbursements.map((r) => r.id)),
      employeeId: employeeId,
      category: kReimbursementCategories.contains(category) ? category : 'Lainnya',
      description: desc,
      amount: amount,
      date: date,
    );
    _reimbursements.insert(0, r);
    _commit('Reimbursement diajukan', '${e.name}: ${Fmt.rupiah(amount)}');
    return r;
  }

  void setReimbursementStatus(String id, ReimbursementStatus status) {
    final i = _reimbursements.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = _reimbursements[i];
    _reimbursements[i] = r.copyWith(status: status);
    final name = employeeById(r.employeeId)?.name ?? r.employeeId;
    _commit('Reimbursement ${status.label.toLowerCase()}', '$name: ${Fmt.rupiah(r.amount)}');
  }

  void deleteReimbursement(String id) {
    final i = _reimbursements.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = _reimbursements.removeAt(i);
    _commit('Reimbursement dihapus', '${r.id} · ${Fmt.rupiah(r.amount)}');
  }

  // ----------------------------------------------------------------- settings
  void updateSettings(AppSettings s) {
    final name = sanitize(s.companyName, maxLength: 60);
    if (name.length < 2) throw const ValidationException('Nama perusahaan terlalu pendek.');
    _settings = s.copyWith(
      companyName: name,
      payday: s.payday.clamp(1, 28),
      autoLockMinutes: s.autoLockMinutes.clamp(1, 60),
    );
    _commit('Pengaturan diubah', 'Preferensi aplikasi diperbarui');
  }

  void logSecurityEvent(String action, String detail) => _commit(action, detail);

  // -------------------------------------------------------- konveksi notebook
  void updateKonveksiRecord(KonveksiRecord record) {
    final i = _konveksiRecords.indexWhere((r) => r.id == record.id);
    if (i >= 0) {
      _konveksiRecords[i] = record;
      _commit('Catatan konveksi diubah', '${record.name}: ${Fmt.rupiah(record.netWage)}');
    }
  }

  String addKonveksiRecord({
    required String name,
    required double days,
    required int dailyRate,
    int overtime = 40000,
    int loanDeduction = 0,
    int remainingLoan = 0,
    String department = 'Produksi / Jahit',
    String phone = '',
    String notes = '',
  }) {
    final id = _nextId('KV', _konveksiRecords.map((r) => r.id));
    final rec = KonveksiRecord(
      id: id,
      name: sanitize(name),
      days: days,
      dailyRate: dailyRate,
      overtime: overtime,
      loanDeduction: loanDeduction,
      remainingLoan: remainingLoan,
      department: department,
      phone: phone,
      notes: sanitize(notes),
    );
    _konveksiRecords.add(rec);
    _commit('Karyawan konveksi ditambah', '${rec.name} (${rec.id})');
    return id;
  }

  void deleteKonveksiRecord(String id) {
    final i = _konveksiRecords.indexWhere((r) => r.id == id);
    if (i >= 0) {
      final name = _konveksiRecords[i].name;
      _konveksiRecords.removeAt(i);
      _commit('Karyawan konveksi dihapus', name);
    }
  }

  void resetKonveksiToPhoto() {
    _konveksiRecords = List.of(Seed.konveksiRecords());
    _commit('Buku konveksi direset', '18 data karyawan dipulihkan sesuai foto catatan');
  }

  Future<void> resetDemo() async {
    _seed(DateTime.now());
    _commit('Data direset', 'Data demo dipulihkan');
    await flush();
  }
}
