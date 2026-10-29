import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum PayrollStatus {
  paid('Sudah dibayar'),
  ready('Siap dibayar'),
  review('Perlu ditinjau');

  const PayrollStatus(this.label);
  final String label;

  static PayrollStatus parse(Object? v) => PayrollStatus.values
      .firstWhere((e) => e.name == v, orElse: () => PayrollStatus.review);
}

enum AttendanceStatus {
  present('Hadir'),
  late('Terlambat'),
  leave('Izin'),
  sick('Sakit'),
  vacation('Cuti'),
  absent('Tanpa keterangan');

  const AttendanceStatus(this.label);
  final String label;

  bool get isPresent => this == present || this == late;

  static AttendanceStatus parse(Object? v) => AttendanceStatus.values
      .firstWhere((e) => e.name == v, orElse: () => AttendanceStatus.present);
}

enum ReimbursementStatus {
  pending('Menunggu'),
  approved('Disetujui'),
  rejected('Ditolak');

  const ReimbursementStatus(this.label);
  final String label;

  static ReimbursementStatus parse(Object? v) => ReimbursementStatus.values
      .firstWhere((e) => e.name == v, orElse: () => ReimbursementStatus.pending);
}

const kDepartments = [
  'Operasional',
  'Produksi / Jahit',
  'Potong (Cutting)',
  'Finishing & QC',
  'Teknologi',
  'Produk',
  'Pemasaran',
];

const kReimbursementCategories = [
  'Transportasi',
  'Makan',
  'Kesehatan',
  'Perjalanan dinas',
  'Peralatan kerja',
  'Lainnya',
];

// Safe JSON readers – never trust persisted data blindly.
int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;

DateTime _date(Object? v, DateTime fallback) =>
    v is String ? (DateTime.tryParse(v) ?? fallback) : fallback;

// ---------------------------------------------------------------------------
// Employee (incl. payroll components for the running period)
// ---------------------------------------------------------------------------

@immutable
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.position,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.baseSalary,
    required this.allowance,
    required this.bpjsKesehatan,
    required this.bpjsKetenagakerjaan,
    required this.pph21,
    this.otherDeduction = 0,
    this.status = PayrollStatus.review,
    this.active = true,
    this.paidAt,
    this.reviewNote,
    this.dailyRate,
    this.paymentMethod = 'Transfer Bank',
    this.bankAccount,
  });

  final String id;
  final String name;
  final String department;
  final String position;
  final String email;
  final String phone;
  final DateTime joinDate;
  final int baseSalary;
  final int allowance;
  final int bpjsKesehatan;
  final int bpjsKetenagakerjaan;
  final int pph21;
  final int otherDeduction;
  final PayrollStatus status;
  final bool active;
  final DateTime? paidAt;
  final String? reviewNote;
  final int? dailyRate;
  final String paymentMethod;
  final String? bankAccount;

  /// Gaji absensi per hari (default: baseSalary / 25 hari kerja atau Rp150.000).
  int get effectiveDailyRate => (dailyRate != null && dailyRate! > 0)
      ? dailyRate!
      : (baseSalary > 0 ? (baseSalary ~/ 25) : 150000);

  /// PPh 21 + BPJS + other (excluding kasbon/loan instalments).
  int get statutoryDeduction =>
      bpjsKesehatan + bpjsKetenagakerjaan + pph21 + otherDeduction;

  int get gross => baseSalary + allowance;

  String get subtitle => '$id · $department';

  Employee copyWith({
    String? name,
    String? department,
    String? position,
    String? email,
    String? phone,
    DateTime? joinDate,
    int? baseSalary,
    int? allowance,
    int? bpjsKesehatan,
    int? bpjsKetenagakerjaan,
    int? pph21,
    int? otherDeduction,
    PayrollStatus? status,
    bool? active,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? reviewNote,
    bool clearReviewNote = false,
    int? dailyRate,
    String? paymentMethod,
    String? bankAccount,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        department: department ?? this.department,
        position: position ?? this.position,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        joinDate: joinDate ?? this.joinDate,
        baseSalary: baseSalary ?? this.baseSalary,
        allowance: allowance ?? this.allowance,
        bpjsKesehatan: bpjsKesehatan ?? this.bpjsKesehatan,
        bpjsKetenagakerjaan: bpjsKetenagakerjaan ?? this.bpjsKetenagakerjaan,
        pph21: pph21 ?? this.pph21,
        otherDeduction: otherDeduction ?? this.otherDeduction,
        status: status ?? this.status,
        active: active ?? this.active,
        paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
        reviewNote: clearReviewNote ? null : (reviewNote ?? this.reviewNote),
        dailyRate: dailyRate ?? this.dailyRate,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        bankAccount: bankAccount ?? this.bankAccount,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'position': position,
        'email': email,
        'phone': phone,
        'joinDate': joinDate.toIso8601String(),
        'baseSalary': baseSalary,
        'allowance': allowance,
        'bpjsKesehatan': bpjsKesehatan,
        'bpjsKetenagakerjaan': bpjsKetenagakerjaan,
        'pph21': pph21,
        'otherDeduction': otherDeduction,
        'status': status.name,
        'active': active,
        'paidAt': paidAt?.toIso8601String(),
        'reviewNote': reviewNote,
        'dailyRate': dailyRate,
        'paymentMethod': paymentMethod,
        'bankAccount': bankAccount,
      };

  factory Employee.fromJson(Map<String, Object?> j) => Employee(
        id: _str(j['id']),
        name: _str(j['name']),
        department: _str(j['department'], kDepartments.first),
        position: _str(j['position']),
        email: _str(j['email']),
        phone: _str(j['phone']),
        joinDate: _date(j['joinDate'], DateTime(2024)),
        baseSalary: _int(j['baseSalary']),
        allowance: _int(j['allowance']),
        bpjsKesehatan: _int(j['bpjsKesehatan']),
        bpjsKetenagakerjaan: _int(j['bpjsKetenagakerjaan']),
        pph21: _int(j['pph21']),
        otherDeduction: _int(j['otherDeduction']),
        status: PayrollStatus.parse(j['status']),
        active: j['active'] != false,
        paidAt: j['paidAt'] is String ? DateTime.tryParse(j['paidAt'] as String) : null,
        reviewNote: j['reviewNote'] is String ? j['reviewNote'] as String : null,
        dailyRate: j['dailyRate'] != null ? _int(j['dailyRate']) : null,
        paymentMethod: _str(j['paymentMethod'], 'Transfer Bank'),
        bankAccount: j['bankAccount'] is String ? j['bankAccount'] as String : null,
      );
}

/// Calculated payroll line for one employee in the running period.
@immutable
class PayrollLine {
  const PayrollLine({
    required this.employee,
    required this.loanDeduction,
  });

  final Employee employee;
  final int loanDeduction;

  int get base => employee.baseSalary;
  int get allowance => employee.allowance;
  int get gross => base + allowance;
  int get statutory => employee.statutoryDeduction;
  int get deduction => statutory + loanDeduction;

  /// Gaji bersih = gaji pokok + tunjangan − potongan
  int get net => gross - deduction;
  PayrollStatus get status => employee.status;
}

/// Calculated weekly payroll line with daily attendance wage and subtotal.
@immutable
class WeeklyPayrollLine {
  const WeeklyPayrollLine({
    required this.employee,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.daysPresent,
    required this.dailyRate,
    required this.dailyWageTotal,
    required this.weeklyAllowance,
    required this.weeklyLoanDeduction,
    required this.subtotalNet,
  });

  final Employee employee;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int daysPresent;
  final int dailyRate;
  final int dailyWageTotal; // daysPresent * dailyRate
  final int weeklyAllowance; // allowance / 4
  final int weeklyLoanDeduction; // installment
  final int subtotalNet; // dailyWageTotal + weeklyAllowance - weeklyLoanDeduction
}

// ---------------------------------------------------------------------------
// Loan / Kasbon
// ---------------------------------------------------------------------------

@immutable
class Loan {
  const Loan({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.deduction,
    required this.createdAt,
    this.syncToPayroll = false,
    this.note = '',
  });

  final String id;
  final String employeeId;

  /// Jumlah bon.
  final int amount;

  /// Potongan (dipotong dari gaji).
  final int deduction;
  final bool syncToPayroll;
  final String note;
  final DateTime createdAt;

  /// Sisa hutang = jumlah bon − potongan (never negative).
  int get remaining => (amount - deduction).clamp(0, amount);
  bool get isPaidOff => remaining == 0;
  String get statusLabel => isPaidOff ? 'Lunas' : 'Belum lunas';

  Loan copyWith({
    int? amount,
    int? deduction,
    bool? syncToPayroll,
    String? note,
  }) =>
      Loan(
        id: id,
        employeeId: employeeId,
        amount: amount ?? this.amount,
        deduction: deduction ?? this.deduction,
        syncToPayroll: syncToPayroll ?? this.syncToPayroll,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'amount': amount,
        'deduction': deduction,
        'syncToPayroll': syncToPayroll,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Loan.fromJson(Map<String, Object?> j) => Loan(
        id: _str(j['id']),
        employeeId: _str(j['employeeId']),
        amount: _int(j['amount']),
        deduction: _int(j['deduction']),
        syncToPayroll: j['syncToPayroll'] == true,
        note: _str(j['note']),
        createdAt: _date(j['createdAt'], DateTime(2026, 10, 1)),
      );
}

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.employeeId,
    required this.day,
    required this.status,
    this.checkIn,
    this.checkOut,
  });

  final String employeeId;

  /// yyyy-MM-dd
  final String day;
  final AttendanceStatus status;
  final String? checkIn;
  final String? checkOut;

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    String? checkIn,
    String? checkOut,
    bool clearTimes = false,
  }) =>
      AttendanceRecord(
        employeeId: employeeId,
        day: day,
        status: status ?? this.status,
        checkIn: clearTimes ? null : (checkIn ?? this.checkIn),
        checkOut: clearTimes ? null : (checkOut ?? this.checkOut),
      );

  Map<String, Object?> toJson() => {
        'e': employeeId,
        'd': day,
        's': status.name,
        'i': checkIn,
        'o': checkOut,
      };

  factory AttendanceRecord.fromJson(Map<String, Object?> j) => AttendanceRecord(
        employeeId: _str(j['e']),
        day: _str(j['d']),
        status: AttendanceStatus.parse(j['s']),
        checkIn: j['i'] is String ? j['i'] as String : null,
        checkOut: j['o'] is String ? j['o'] as String : null,
      );
}

// ---------------------------------------------------------------------------
// Reimbursement
// ---------------------------------------------------------------------------

@immutable
class Reimbursement {
  const Reimbursement({
    required this.id,
    required this.employeeId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.status = ReimbursementStatus.pending,
  });

  final String id;
  final String employeeId;
  final String category;
  final String description;
  final int amount;
  final DateTime date;
  final ReimbursementStatus status;

  Reimbursement copyWith({ReimbursementStatus? status}) => Reimbursement(
        id: id,
        employeeId: employeeId,
        category: category,
        description: description,
        amount: amount,
        date: date,
        status: status ?? this.status,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'status': status.name,
      };

  factory Reimbursement.fromJson(Map<String, Object?> j) => Reimbursement(
        id: _str(j['id']),
        employeeId: _str(j['employeeId']),
        category: _str(j['category'], 'Lainnya'),
        description: _str(j['description']),
        amount: _int(j['amount']),
        date: _date(j['date'], DateTime(2026, 10, 1)),
        status: ReimbursementStatus.parse(j['status']),
      );
}

// ---------------------------------------------------------------------------
// Audit log + settings
// ---------------------------------------------------------------------------

@immutable
class AuditEntry {
  const AuditEntry({required this.at, required this.action, required this.detail});

  final DateTime at;
  final String action;
  final String detail;

  Map<String, Object?> toJson() =>
      {'at': at.toIso8601String(), 'a': action, 'd': detail};

  factory AuditEntry.fromJson(Map<String, Object?> j) => AuditEntry(
        at: _date(j['at'], DateTime(2026)),
        action: _str(j['a']),
        detail: _str(j['d']),
      );
}

@immutable
class AppSettings {
  const AppSettings({
    this.companyName = 'Nusa Digital',
    this.payday = 25,
    this.autoLockMinutes = 5,
    this.secureScreen = true,
  });

  final String companyName;
  final int payday;
  final int autoLockMinutes;
  final bool secureScreen;

  AppSettings copyWith({
    String? companyName,
    int? payday,
    int? autoLockMinutes,
    bool? secureScreen,
  }) =>
      AppSettings(
        companyName: companyName ?? this.companyName,
        payday: payday ?? this.payday,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        secureScreen: secureScreen ?? this.secureScreen,
      );

  Map<String, Object?> toJson() => {
        'companyName': companyName,
        'payday': payday,
        'autoLockMinutes': autoLockMinutes,
        'secureScreen': secureScreen,
      };

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
        companyName: _str(j['companyName'], 'Nusa Digital'),
        payday: _int(j['payday'], 25).clamp(1, 28),
        autoLockMinutes: _int(j['autoLockMinutes'], 5).clamp(1, 60),
        secureScreen: j['secureScreen'] != false,
      );
}
