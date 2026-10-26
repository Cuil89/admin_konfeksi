import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';

abstract final class CsvService {
  /// Exports payroll lines to CSV formatted with UTF-8 BOM for Microsoft Excel.
  static Future<String> generatePayrollCsv({
    required List<PayrollLine> lines,
    required String periodLabel,
  }) async {
    final buffer = StringBuffer();

    // Excel UTF-8 BOM
    buffer.write('\uFEFF');

    // CSV Header
    buffer.writeln(
      'ID;Nama;Departemen;Jabatan;Gaji Pokok;Tunjangan;BPJS Kesehatan;BPJS Ketenagakerjaan;PPh 21;Potongan Bon;Potongan Lain;Total Potongan;Gaji Bersih;Status',
    );

    for (final l in lines) {
      final e = l.employee;
      buffer.writeln([
        _escape(e.id),
        _escape(e.name),
        _escape(e.department),
        _escape(e.position),
        e.baseSalary,
        e.allowance,
        e.bpjsKesehatan,
        e.bpjsKetenagakerjaan,
        e.pph21,
        l.loanDeduction,
        e.otherDeduction,
        l.deduction,
        l.net,
        _escape(l.status.label),
      ].join(';'));
    }

    return buffer.toString();
  }

  /// Exports loan records to CSV
  static Future<String> generateLoansCsv({
    required List<Loan> loans,
    required List<Employee> employees,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('ID Bon;ID Karyawan;Nama Karyawan;Departemen;Jumlah Bon;Potongan;Sisa Hutang;Status;Sinkron Payroll');

    for (final loan in loans) {
      final emp = employees.firstWhere(
        (e) => e.id == loan.employeeId,
        orElse: () => Employee(
          id: loan.employeeId,
          name: loan.employeeId,
          department: '-',
          position: '-',
          email: '',
          phone: '',
          joinDate: DateTime.now(),
          baseSalary: 0,
          allowance: 0,
          bpjsKesehatan: 0,
          bpjsKetenagakerjaan: 0,
          pph21: 0,
        ),
      );

      buffer.writeln([
        _escape(loan.id),
        _escape(loan.employeeId),
        _escape(emp.name),
        _escape(emp.department),
        loan.amount,
        loan.deduction,
        loan.remaining,
        _escape(loan.statusLabel),
        loan.syncToPayroll ? 'Ya' : 'Tidak',
      ].join(';'));
    }

    return buffer.toString();
  }

  static Future<void> shareCsv(String csvContent, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent, encoding: utf8);

    final params = ShareParams(
      files: [XFile(file.path)],
      subject: 'Ekspor Data $filename',
    );
    await SharePlus.instance.share(params);
  }

  static String _escape(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
