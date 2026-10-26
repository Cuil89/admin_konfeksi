import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';
import '../widgets/sidebar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.store,
    required this.onNavigateToTab,
  });

  final AppStore store;
  final ValueChanged<AppTab> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final totals = store.totals;
        final lines = store.payrollLines;
        final audit = store.audit;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1120;

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
                              Text('Ringkasan', style: AppText.pageTitle),
                              SizedBox(height: 4),
                              Text(
                                'Pantau aktivitas HR, kehadiran, dan status penggajian secara real-time.',
                                style: AppText.small,
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(AppIcons.payroll, size: 16),
                            label: const Text('Buka Penggajian'),
                            onPressed: () => onNavigateToTab(AppTab.payroll),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Period Bar
                      _buildPeriodBar(),
                      const SizedBox(height: 20),

                      // 4 Stat Cards as specified in prompt:
                      // 1. Total Karyawan: 104 karyawan ("100 karyawan aktif · 4 departemen")
                      // 2. Karyawan Tidak Hadir (Hari ini): 4 karyawan ("-2 orang Hari ini")
                      // 3. Total Gaji Bulan Ini: Rp61.550.000 ("100 dari 4 karyawan telah menerima gaji")
                      // 4. Belum dibayarkan: Rp26.450.000 ("2 siap dibayar · 1 perlu ditinjau")
                      _buildStatCards(isMobile, isTablet),
                      const SizedBox(height: 24),

                      // 2-Column Component Summary
                      _buildTwoColumnSection(totals, isMobile),
                      const SizedBox(height: 28),

                      // Quick Table Preview & Recent Activity
                      _buildBottomGrid(lines, audit, isMobile),
                      const SizedBox(height: 32),
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

  Widget _buildPeriodBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Periode penggajian', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.calendar, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      store.periodLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textStrong),
                    ),
                    const SizedBox(width: 4),
                    const Icon(AppIcons.chevronDown, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              Text(
                '01 Okt ${store.periodYear} – 31 Okt ${store.periodYear}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Tanggal gajian: ${store.settings.payday} Okt ${store.periodYear}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.emerald200, width: 0.8),
                ),
                child: const Text(
                  'Periode berjalan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(bool isMobile, bool isTablet) {
    final crossCount = isMobile ? 1 : (isTablet ? 2 : 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((crossCount - 1) * 16)) / crossCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: Total Karyawan -> 104 karyawan ("100 karyawan aktif · 4 departemen")
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Karyawan',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(AppIcons.employees, size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('104 karyawan', style: AppText.statValue),
                    const SizedBox(height: 6),
                    const Text('100 karyawan aktif · 4 departemen', style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

            // Card 2: Karyawan Tidak Hadir (Hari ini) -> 4 karyawan ("-2 orang Hari ini")
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Karyawan Tidak Hadir (Hari ini)',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.rose50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(AppIcons.attendance, size: 16, color: AppColors.rose600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('4 karyawan', style: AppText.statValue),
                    const SizedBox(height: 6),
                    const Text('-2 orang Hari ini', style: TextStyle(fontSize: 11.5, color: AppColors.emerald700, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

            // Card 3: Total Gaji Bulan Ini -> Rp61.550.000 ("100 dari 4 karyawan telah menerima gaji")
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Gaji Bulan Ini',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(AppIcons.checkCircle, size: 16, color: AppColors.primary700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Fmt.rupiah(store.totals.paidAmount), style: AppText.statValue),
                    ),
                    const SizedBox(height: 6),
                    const Text('100 dari 4 karyawan telah menerima gaji', style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),

            // Card 4: Belum dibayarkan -> Rp26.450.000 ("2 siap dibayar · 1 perlu ditinjau")
            SizedBox(
              width: itemWidth,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Belum dibayarkan',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(AppIcons.clock, size: 16, color: AppColors.amber700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Fmt.rupiah(store.totals.unpaidAmount), style: AppText.statValue),
                    ),
                    const SizedBox(height: 6),
                    Text('${store.totals.readyCount} siap dibayar · ${store.totals.reviewCount} perlu ditinjau', style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTwoColumnSection(PayrollTotals t, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingle = constraints.maxWidth < 900;

        final leftCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Ringkasan komponen gaji',
                      style: AppText.sectionTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total bruto ${Fmt.rupiah(t.gross)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 14,
                  color: AppColors.emeraldSoft,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: t.gross == 0 ? 0 : (t.base / t.gross).clamp(0.0, 1.0),
                    child: Container(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _compItem('Gaji pokok', Fmt.rupiah(t.base), '${Fmt.percent(t.baseRatio, decimals: 0)} dari gaji bruto')),
                  Expanded(child: _compItem('Tunjangan', Fmt.rupiah(t.allowance), '${Fmt.percent(t.allowanceRatio, decimals: 0)} dari gaji bruto')),
                  Expanded(child: _compItem('Potongan', '−${Fmt.rupiah(t.deduction)}', 'PPh 21, BPJS & lainnya')),
                ],
              ),
            ],
          ),
        );

        final rightCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Status pembayaran',
                      style: AppText.sectionTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('62,5%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(8, (index) {
                  Color c = index < 5 ? AppColors.primary : (index < 7 ? AppColors.emeraldMist : AppColors.amberSegment);
                  return Expanded(
                    child: Container(
                      height: 12,
                      margin: EdgeInsets.only(right: index == 7 ? 0 : 4),
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              _statBarRow('Sudah dibayar', '5 karyawan', 'Rp61.550.000', AppColors.primary),
              const SizedBox(height: 6),
              _statBarRow('Siap dibayar', '2 karyawan', 'Rp18.700.000', AppColors.emeraldSoft),
              const SizedBox(height: 6),
              _statBarRow('Perlu ditinjau', '1 karyawan', 'Rp7.750.000', AppColors.amber700),
            ],
          ),
        );

        if (isSingle) {
          return Column(
            children: [
              leftCard,
              const SizedBox(height: 16),
              rightCard,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftCard),
              const SizedBox(width: 16),
              Expanded(child: rightCard),
            ],
          );
        }
      },
    );
  }

  Widget _compItem(String title, String amount, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.tiny),
        const SizedBox(height: 4),
        Text(amount, style: AppText.bodyStrong),
        Text(sub, style: AppText.tiny),
      ],
    );
  }

  Widget _statBarRow(String title, String count, String amount, Color dotColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppText.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(count, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textStrong)),
      ],
    );
  }

  Widget _buildBottomGrid(List<PayrollLine> lines, List<AuditEntry> audit, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingle = constraints.maxWidth < 900;

        final quickListCard = AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Daftar Payroll Cepat',
                        style: AppText.sectionTitle,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => onNavigateToTab(AppTab.payroll),
                    child: const Text('Lihat Semua →'),
                  ),
                ],
              ),
              const Divider(),
              ...lines.take(5).map((l) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      InitialsAvatar(initials: Fmt.initials(l.employee.name), size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.employee.name,
                                style: AppText.bodyStrong,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('${l.employee.id} · ${l.employee.department}',
                                style: AppText.tiny,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Fmt.rupiah(l.net),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          PayrollStatusBadge(status: l.status),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );

        final auditCard = AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aktivitas & Audit Trail Keamanan',
                  style: AppText.sectionTitle),
              const SizedBox(height: 12),
              const Divider(),
              if (audit.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada log aktivitas.', style: AppText.small),
                )
              else
                ...audit.take(5).map((a) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.action,
                                  style: AppText.bodyStrong,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(a.detail,
                                  style: AppText.tiny,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(Fmt.dateTime(a.at), style: AppText.tiny),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );

        if (isSingle) {
          return Column(
            children: [
              quickListCard,
              const SizedBox(height: 16),
              auditCard,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: quickListCard),
              const SizedBox(width: 16),
              Expanded(child: auditCard),
            ],
          );
        }
      },
    );
  }
}
