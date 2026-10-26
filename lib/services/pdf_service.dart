import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../data/models.dart';

abstract final class PdfService {
  /// Generates a high-precision, clean, emerald-themed Payslip PDF.
  static Future<Uint8List> generatePayslip({
    required Employee employee,
    required PayrollLine line,
    required String companyName,
    required String periodLabel,
    required DateTime payday,
  }) async {
    final pdf = pw.Document();

    final primaryEmerald = PdfColor.fromHex('065F46');
    final darkEmerald = PdfColor.fromHex('044E3B');
    final slate50 = PdfColor.fromHex('F8FAFC');
    final slate200 = PdfColor.fromHex('E2E8F0');
    final slate700 = PdfColor.fromHex('334155');
    final slate900 = PdfColor.fromHex('0F172A');
    final textMuted = PdfColor.fromHex('64748B');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: primaryEmerald,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'payrole .',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          companyName,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'SLIP GAJI KARYAWAN',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Periode: $periodLabel',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          'Tanggal Gajian: ${Fmt.date(payday)}',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Employee Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: slate50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: slate200),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _metaRow('Nama Karyawan', employee.name),
                          _metaRow('ID Karyawan', employee.id),
                          _metaRow('Jabatan', employee.position),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _metaRow('Departemen', employee.department),
                          _metaRow('Status Payroll', employee.status.label),
                          _metaRow('Tanggal Bergabung', Fmt.date(employee.joinDate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Earnings & Deductions Tables
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Penghasilan
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: slate200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENGHASILAN',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: darkEmerald,
                            ),
                          ),
                          pw.Divider(color: slate200, height: 16),
                          _moneyRow('Gaji Pokok', employee.baseSalary),
                          _moneyRow('Tunjangan Tetap', employee.allowance),
                          pw.Divider(color: slate200, height: 16),
                          _moneyRow('Total Penghasilan Bruto', line.gross, isBold: true),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 16),

                  // Potongan
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: slate200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'POTONGAN',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red800,
                            ),
                          ),
                          pw.Divider(color: slate200, height: 16),
                          _moneyRow('BPJS Kesehatan (1%)', employee.bpjsKesehatan),
                          _moneyRow('BPJS Ketenagakerjaan (3%)', employee.bpjsKetenagakerjaan),
                          _moneyRow('PPh 21', employee.pph21),
                          if (line.loanDeduction > 0)
                            _moneyRow('Potongan Bon / Kasbon', line.loanDeduction),
                          if (employee.otherDeduction > 0)
                            _moneyRow('Potongan Lainnya', employee.otherDeduction),
                          pw.Divider(color: slate200, height: 16),
                          _moneyRow('Total Potongan', line.deduction, isBold: true, isNegative: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Total Net Pay Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: darkEmerald,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL GAJI BERSIH (TAKE HOME PAY)',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Gaji Bruto - Total Potongan',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      Fmt.rupiah(line.net),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures & Notes
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Penerima,',
                        style: pw.TextStyle(fontSize: 10, color: slate700),
                      ),
                      pw.SizedBox(height: 48),
                      pw.Text(
                        employee.name,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: slate900,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Finance & HR Admin,',
                        style: pw.TextStyle(fontSize: 10, color: slate700),
                      ),
                      pw.SizedBox(height: 48),
                      pw.Text(
                        'Anita Putri',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: slate900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),
              pw.Divider(color: slate200),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dokumen resmi digenerate otomatis oleh sistem Payrole HRIS.',
                    style: pw.TextStyle(fontSize: 8, color: textMuted),
                  ),
                  pw.Text(
                    'Dicetak pada: ${Fmt.dateTime(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: textMuted),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a full Payroll Summary Report PDF for all active employees.
  static Future<Uint8List> generatePayrollReport({
    required List<PayrollLine> lines,
    required String companyName,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    final primaryEmerald = PdfColor.fromHex('065F46');
    final slate200 = PdfColor.fromHex('E2E8F0');
    final slate700 = PdfColor.fromHex('334155');

    var totalBase = 0;
    var totalAllowance = 0;
    var totalDeduction = 0;
    var totalNet = 0;

    for (final l in lines) {
      totalBase += l.base;
      totalAllowance += l.allowance;
      totalDeduction += l.deduction;
      totalNet += l.net;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN REKAPITULASI PENGGAJIAN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryEmerald,
                    ),
                  ),
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(fontSize: 12, color: slate700),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Periode: $periodLabel',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Total Karyawan: ${lines.length}',
                    style: pw.TextStyle(fontSize: 10, color: slate700),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: slate200, width: 0.5),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryEmerald),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: [
              'No',
              'ID',
              'Nama Karyawan',
              'Departemen',
              'Gaji Pokok',
              'Tunjangan',
              'Potongan',
              'Gaji Bersih',
              'Status',
            ],
            data: [
              for (var i = 0; i < lines.length; i++)
                [
                  '${i + 1}',
                  lines[i].employee.id,
                  lines[i].employee.name,
                  lines[i].employee.department,
                  Fmt.rupiah(lines[i].base),
                  Fmt.rupiah(lines[i].allowance),
                  Fmt.rupiah(lines[i].deduction),
                  Fmt.rupiah(lines[i].net),
                  lines[i].status.label,
                ],
            ],
          ),

          pw.SizedBox(height: 12),

          // Summary Totals
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryEmerald),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('Total Pokok', Fmt.rupiah(totalBase)),
                _summaryItem('Total Tunjangan', Fmt.rupiah(totalAllowance)),
                _summaryItem('Total Potongan', Fmt.rupiah(totalDeduction)),
                _summaryItem('Total Bersih', Fmt.rupiah(totalNet), isHighlight: true),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrSharePayslip({
    required Employee employee,
    required PayrollLine line,
    required String companyName,
    required String periodLabel,
    required DateTime payday,
  }) async {
    final bytes = await generatePayslip(
      employee: employee,
      line: line,
      companyName: companyName,
      periodLabel: periodLabel,
      payday: payday,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Slip_Gaji_${employee.name.replaceAll(' ', '_')}_$periodLabel.pdf',
    );
  }

  static Future<void> printOrShareReport({
    required List<PayrollLine> lines,
    required String companyName,
    required String periodLabel,
  }) async {
    final bytes = await generatePayrollReport(
      lines: lines,
      companyName: companyName,
      periodLabel: periodLabel,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Laporan_Payroll_$periodLabel.pdf',
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9.5, color: PdfColor.fromHex('64748B')),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 9.5)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _moneyRow(String label, int amount,
      {bool isBold = false, bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromHex('334155'),
            ),
          ),
          pw.Text(
            isNegative ? '-${Fmt.rupiah(amount)}' : Fmt.rupiah(amount),
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isNegative ? PdfColors.red800 : PdfColor.fromHex('0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value,
      {bool isHighlight = false}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('64748B')),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight
                ? PdfColor.fromHex('065F46')
                : PdfColor.fromHex('0F172A'),
          ),
        ),
      ],
    );
  }
}
