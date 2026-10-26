import '../core/format.dart';
import 'models.dart';

/// Initial demo dataset (Nusa Digital, periode Oktober 2026).
/// Totals: pokok Rp80.000.000 · tunjangan Rp12.000.000 · potongan Rp4.000.000
/// · bersih Rp88.000.000.
abstract final class Seed {
  static const periodYear = 2026;
  static const periodMonth = 10;
  static final lastUpdated = DateTime(2026, 10, 23, 9, 41);

  static List<Employee> employees() => [
        Employee(
          id: 'ND-001',
          name: 'Aditya Pratama',
          department: 'Teknologi',
          position: 'Senior Software Engineer',
          email: 'aditya.pratama@nusadigital.id',
          phone: '081234560001',
          joinDate: DateTime(2021, 3, 1),
          baseSalary: 14000000,
          allowance: 2000000,
          bpjsKesehatan: 140000,
          bpjsKetenagakerjaan: 420000,
          pph21: 190000,
          status: PayrollStatus.paid,
          paidAt: DateTime(2026, 10, 22, 10, 15),
        ),
        Employee(
          id: 'ND-002',
          name: 'Nadia Rahma',
          department: 'Produk',
          position: 'Product Manager',
          email: 'nadia.rahma@nusadigital.id',
          phone: '081234560002',
          joinDate: DateTime(2021, 8, 16),
          baseSalary: 12000000,
          allowance: 2000000,
          bpjsKesehatan: 120000,
          bpjsKetenagakerjaan: 360000,
          pph21: 170000,
          status: PayrollStatus.paid,
          paidAt: DateTime(2026, 10, 22, 10, 15),
        ),
        Employee(
          id: 'ND-003',
          name: 'Budi Santoso',
          department: 'Teknologi',
          position: 'Software Engineer',
          email: 'budi.santoso@nusadigital.id',
          phone: '081234560003',
          joinDate: DateTime(2022, 1, 10),
          baseSalary: 11000000,
          allowance: 1500000,
          bpjsKesehatan: 110000,
          bpjsKetenagakerjaan: 330000,
          pph21: 160000,
          status: PayrollStatus.paid,
          paidAt: DateTime(2026, 10, 22, 10, 15),
        ),
        Employee(
          id: 'ND-004',
          name: 'Citra Lestari',
          department: 'Pemasaran',
          position: 'Marketing Lead',
          email: 'citra.lestari@nusadigital.id',
          phone: '081234560004',
          joinDate: DateTime(2022, 5, 2),
          baseSalary: 10000000,
          allowance: 1500000,
          bpjsKesehatan: 100000,
          bpjsKetenagakerjaan: 300000,
          pph21: 100000,
          status: PayrollStatus.paid,
          paidAt: DateTime(2026, 10, 22, 10, 15),
        ),
        Employee(
          id: 'ND-005',
          name: 'Fajar Hidayat',
          department: 'Operasional',
          position: 'Operations Supervisor',
          email: 'fajar.hidayat@nusadigital.id',
          phone: '081234560005',
          joinDate: DateTime(2022, 9, 19),
          baseSalary: 9000000,
          allowance: 1500000,
          bpjsKesehatan: 90000,
          bpjsKetenagakerjaan: 270000,
          pph21: 90000,
          status: PayrollStatus.paid,
          paidAt: DateTime(2026, 10, 22, 10, 15),
        ),
        Employee(
          id: 'ND-006',
          name: 'Salsabila Putri',
          department: 'Produk',
          position: 'Product Designer',
          email: 'salsabila.putri@nusadigital.id',
          phone: '081234560006',
          joinDate: DateTime(2023, 2, 6),
          baseSalary: 9000000,
          allowance: 1500000,
          bpjsKesehatan: 90000,
          bpjsKetenagakerjaan: 270000,
          pph21: 90000,
          status: PayrollStatus.ready,
        ),
        Employee(
          id: 'ND-007',
          name: 'Rizky Ramadhan',
          department: 'Pemasaran',
          position: 'Digital Marketing Specialist',
          email: 'rizky.ramadhan@nusadigital.id',
          phone: '081234560007',
          joinDate: DateTime(2023, 7, 3),
          baseSalary: 8000000,
          allowance: 1000000,
          bpjsKesehatan: 80000,
          bpjsKetenagakerjaan: 240000,
          pph21: 30000,
          status: PayrollStatus.ready,
        ),
        Employee(
          id: 'ND-008',
          name: 'Dimas Saputra',
          department: 'Operasional',
          position: 'Operations Staff',
          email: 'dimas.saputra@nusadigital.id',
          phone: '081234560008',
          joinDate: DateTime(2024, 4, 15),
          baseSalary: 7000000,
          allowance: 1000000,
          bpjsKesehatan: 70000,
          bpjsKetenagakerjaan: 180000,
          pph21: 0,
          status: PayrollStatus.review,
          reviewNote:
              'BPJS Ketenagakerjaan lebih kecil dari estimasi dan cicilan bon belum masuk potongan.',
        ),
      ];

  static List<Loan> loans() => [
        Loan(
          id: 'BON-001',
          employeeId: 'ND-008',
          amount: 1500000,
          deduction: 250000,
          note: 'Biaya pengobatan keluarga',
          createdAt: DateTime(2026, 9, 12),
        ),
        Loan(
          id: 'BON-002',
          employeeId: 'ND-005',
          amount: 800000,
          deduction: 200000,
          note: 'Perbaikan kendaraan',
          createdAt: DateTime(2026, 9, 20),
        ),
        Loan(
          id: 'BON-003',
          employeeId: 'ND-004',
          amount: 500000,
          deduction: 250000,
          note: 'Keperluan pribadi',
          createdAt: DateTime(2026, 10, 2),
        ),
        Loan(
          id: 'BON-004',
          employeeId: 'ND-006',
          amount: 300000,
          deduction: 300000,
          note: 'Uang muka laptop',
          createdAt: DateTime(2026, 8, 28),
        ),
      ];

  static List<Reimbursement> reimbursements() => [
        Reimbursement(
          id: 'RB-001',
          employeeId: 'ND-002',
          category: 'Kesehatan',
          description: 'Rawat jalan & obat',
          amount: 1200000,
          date: DateTime(2026, 10, 21),
        ),
        Reimbursement(
          id: 'RB-002',
          employeeId: 'ND-004',
          category: 'Perjalanan dinas',
          description: 'Tiket & hotel event Surabaya',
          amount: 2450000,
          date: DateTime(2026, 10, 18),
        ),
        Reimbursement(
          id: 'RB-003',
          employeeId: 'ND-008',
          category: 'Transportasi',
          description: 'Kunjungan gudang mitra',
          amount: 220000,
          date: DateTime(2026, 10, 20),
        ),
        Reimbursement(
          id: 'RB-004',
          employeeId: 'ND-001',
          category: 'Transportasi',
          description: 'Taksi lembur rilis aplikasi',
          amount: 350000,
          date: DateTime(2026, 10, 9),
          status: ReimbursementStatus.approved,
        ),
        Reimbursement(
          id: 'RB-005',
          employeeId: 'ND-005',
          category: 'Makan',
          description: 'Makan tim shift malam',
          amount: 180000,
          date: DateTime(2026, 10, 7),
          status: ReimbursementStatus.approved,
        ),
        Reimbursement(
          id: 'RB-006',
          employeeId: 'ND-007',
          category: 'Peralatan kerja',
          description: 'Ring light untuk konten',
          amount: 650000,
          date: DateTime(2026, 10, 5),
          status: ReimbursementStatus.rejected,
        ),
      ];

  /// Net payroll history for the trend chart (last 5 closed periods).
  static const netHistory = <({int year, int month, int net})>[
    (year: 2026, month: 5, net: 84200000),
    (year: 2026, month: 6, net: 84900000),
    (year: 2026, month: 7, net: 85600000),
    (year: 2026, month: 8, net: 86100000),
    (year: 2026, month: 9, net: 86800000),
  ];

  /// Generates deterministic attendance for the last ~2 working weeks
  /// relative to [today], so the module always has fresh data.
  static List<AttendanceRecord> attendance(
    List<Employee> employees,
    DateTime today,
  ) {
    final out = <AttendanceRecord>[];
    final base = Fmt.dayOnly(today);
    for (var offset = 0; offset < 14; offset++) {
      final day = base.subtract(Duration(days: offset));
      final isWeekend = day.weekday >= DateTime.saturday;
      if (isWeekend && offset != 0) continue;
      for (var i = 0; i < employees.length; i++) {
        out.add(_record(employees[i].id, i, offset, day));
      }
    }
    return out;
  }

  static AttendanceRecord _record(String id, int i, int offset, DateTime day) {
    final key = Fmt.isoDay(day);
    // Today: Rizky sakit, Dimas izin, Budi terlambat.
    // Yesterday-ish: 3 absences → dashboard shows a positive trend.
    AttendanceStatus status = AttendanceStatus.present;
    final h = (i * 7 + offset * 13) % 23;
    if (offset == 0) {
      if (i == 6) status = AttendanceStatus.sick;
      if (i == 7) status = AttendanceStatus.leave;
      if (i == 2) status = AttendanceStatus.late;
    } else if (offset == 1 || (offset == 3 && day.weekday == DateTime.friday)) {
      if (i == 6 || i == 7) status = AttendanceStatus.leave;
      if (i == 3) status = AttendanceStatus.vacation;
    } else {
      if (h == 3) status = AttendanceStatus.late;
      if (h == 11) status = AttendanceStatus.sick;
      if (h == 17) status = AttendanceStatus.leave;
    }
    String? checkIn;
    String? checkOut;
    if (status == AttendanceStatus.present) {
      checkIn = '07:${(45 + h).clamp(45, 59).toString().padLeft(2, '0')}';
      checkOut = offset == 0 ? null : '17:${Fmt.two((h * 2) % 60)}';
    } else if (status == AttendanceStatus.late) {
      checkIn = '08:${Fmt.two(15 + h % 30)}';
      checkOut = offset == 0 ? null : '17:${Fmt.two(30 + h % 25)}';
    }
    return AttendanceRecord(
      employeeId: id,
      day: key,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
    );
  }
}
