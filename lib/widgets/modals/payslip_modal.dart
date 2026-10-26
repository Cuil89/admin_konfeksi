import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/pdf_service.dart';
import '../app_card.dart';
import '../badges.dart';

class PayslipModal extends StatelessWidget {
  const PayslipModal({
    super.key,
    required this.store,
    required this.line,
  });

  final AppStore store;
  final PayrollLine line;

  static Future<void> show(
    BuildContext context,
    AppStore store,
    PayrollLine line,
  ) {
    return showDialog(
      context: context,
      builder: (context) => PayslipModal(store: store, line: line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = line.employee;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          AppIcons.fileText,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Slip Gaji Karyawan', style: AppText.sectionTitle),
                          Text(
                            'Periode: ${store.periodLabel}',
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Bio Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Row(
                          children: [
                            InitialsAvatar(
                              initials: Fmt.initials(e.name),
                              size: 44,
                              backgroundColor: AppColors.emerald100,
                              textColor: AppColors.primary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: AppText.bodyStrong),
                                  Text(
                                    '${e.id} · ${e.department} · ${e.position}',
                                    style: AppText.tiny,
                                  ),
                                  Text(
                                    'Bergabung sejak: ${Fmt.date(e.joinDate)}',
                                    style: AppText.tiny.copyWith(color: AppColors.textSubtle),
                                  ),
                                ],
                              ),
                            ),
                            PayrollStatusBadge(status: e.status),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Earnings (Penghasilan)
                      const Text(
                        'PENGHASILAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _itemRow('Gaji Pokok', Fmt.rupiah(e.baseSalary)),
                      _itemRow('Tunjangan', Fmt.rupiah(e.allowance)),
                      const Divider(height: 18),
                      _itemRow(
                        'Total Penghasilan Bruto',
                        Fmt.rupiah(line.gross),
                        isBold: true,
                      ),

                      const SizedBox(height: 20),

                      // Deductions (Potongan)
                      const Text(
                        'POTONGAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rose600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _itemRow('BPJS Kesehatan (1%)', Fmt.rupiah(e.bpjsKesehatan, forceNegative: true)),
                      _itemRow('BPJS Ketenagakerjaan (3%)', Fmt.rupiah(e.bpjsKetenagakerjaan, forceNegative: true)),
                      _itemRow('PPh 21', Fmt.rupiah(e.pph21, forceNegative: true)),
                      if (line.loanDeduction > 0)
                        _itemRow('Potongan Kasbon / Bon', Fmt.rupiah(line.loanDeduction, forceNegative: true)),
                      if (e.otherDeduction > 0)
                        _itemRow('Potongan Lainnya', Fmt.rupiah(e.otherDeduction, forceNegative: true)),
                      const Divider(height: 18),
                      _itemRow(
                        'Total Potongan',
                        '−${Fmt.rupiah(line.deduction)}',
                        isBold: true,
                        color: AppColors.rose600,
                      ),

                      const SizedBox(height: 20),

                      // Net Salary Box (Gaji Bersih)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL GAJI BERSIH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Take Home Pay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              Fmt.rupiah(line.net),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanggal gajian: ${Fmt.date(store.payday)}',
                    style: AppText.tiny,
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                        ),
                        icon: const Icon(AppIcons.print, size: 16),
                        label: const Text('Cetak / Unduh PDF'),
                        onPressed: () {
                          PdfService.printOrSharePayslip(
                            employee: e,
                            line: line,
                            companyName: store.settings.companyName,
                            periodLabel: store.periodLabel,
                            payday: store.payday,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.text2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? (isBold ? AppColors.textStrong : AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
