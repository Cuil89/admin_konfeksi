import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/seed.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import '../widgets/app_card.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final totals = store.totals;
        final lines = store.payrollLines;

        // Group by department
        final deptTotals = <String, int>{};
        for (final l in lines) {
          deptTotals[l.employee.department] =
              (deptTotals[l.employee.department] ?? 0) + l.net;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 28,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Laporan & Analitik', style: AppText.pageTitle),
                              SizedBox(height: 4),
                              Text(
                                'Rekapitulasi biaya penggajian, pajak, dan distribusi per departemen.',
                                style: AppText.small,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                ),
                                icon: const Icon(AppIcons.export, size: 16),
                                label: const Text('Unduh CSV'),
                                onPressed: () async {
                                  final csv = await CsvService.generatePayrollCsv(
                                    lines: lines,
                                    periodLabel: store.periodLabel,
                                  );
                                  await CsvService.shareCsv(csv, 'Laporan_${store.periodLabel}.csv');
                                },
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                ),
                                icon: const Icon(AppIcons.print, size: 16),
                                label: const Text('Cetak Rekap PDF'),
                                onPressed: () {
                                  PdfService.printOrShareReport(
                                    lines: lines,
                                    companyName: store.settings.companyName,
                                    periodLabel: store.periodLabel,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Department Breakdown Card
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Distribusi Penggajian per Departemen', style: AppText.sectionTitle),
                            const SizedBox(height: 16),
                            ...deptTotals.entries.map((entry) {
                              final ratio = totals.net == 0 ? 0.0 : entry.value / totals.net;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: AppText.bodyStrong),
                                        Text(
                                          '${Fmt.rupiah(entry.value)} (${(ratio * 100).toStringAsFixed(1)}%)',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ratio,
                                        backgroundColor: AppColors.slate100,
                                        color: AppColors.primary,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Historical Trend (5 closed periods)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tren Penggajian Bersih (Bulan ke Bulan)', style: AppText.sectionTitle),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...Seed.netHistory.map((h) {
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.borderStrong),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${Fmt.monthsShort[h.month - 1]} ${h.year}', style: AppText.small),
                                          const SizedBox(height: 6),
                                          Text(
                                            Fmt.compact(h.net),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textStrong,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('Lunas', style: TextStyle(fontSize: 11, color: AppColors.primary700, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    );
                                  }),
                                  // Current period
                                  Container(
                                    width: 140,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.emerald200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Okt 2026', style: AppText.small.copyWith(color: AppColors.primary700)),
                                        const SizedBox(height: 6),
                                        Text(
                                          Fmt.compact(totals.net),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Berjalan', style: TextStyle(fontSize: 11, color: AppColors.primary700, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
