import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';
import '../widgets/modals/add_loan_modal.dart';
import '../widgets/modals/edit_components_modal.dart';
import '../widgets/modals/payslip_modal.dart';
import '../widgets/modals/process_payroll_modal.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key, required this.store});

  final AppStore store;

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  String _searchQuery = '';
  String _departmentFilter = 'Semua';
  String _statusFilter = 'Semua';

  final Set<String> _selectedPayrollIds = {};
  final Set<String> _selectedLoanIds = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final totals = widget.store.totals;
        final lines = widget.store.payrollLines;
        final loans = widget.store.loans;

        // Apply filters
        final filteredLines = lines.where((l) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesQuery = query.isEmpty ||
              l.employee.name.toLowerCase().contains(query) ||
              l.employee.id.toLowerCase().contains(query);

          final matchesDept = _departmentFilter == 'Semua' ||
              l.employee.department == _departmentFilter;

          final matchesStatus = _statusFilter == 'Semua' ||
              l.status.name == _statusFilter;

          return matchesQuery && matchesDept && matchesStatus;
        }).toList();

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
                      // Header Section
                      _buildHeader(context, isMobile),
                      const SizedBox(height: 20),

                      // Period Bar
                      _buildPeriodBar(isMobile),
                      const SizedBox(height: 20),

                      // 4 Stat Cards
                      _buildStatCards(totals, isMobile, isTablet),
                      const SizedBox(height: 20),

                      // 2-Column Component Summary & Payment Status
                      _buildTwoColumnSummary(totals, lines, isMobile),
                      const SizedBox(height: 28),

                      // Table: Payroll Karyawan
                      _buildPayrollTable(filteredLines, totals, isMobile),
                      const SizedBox(height: 32),

                      // Table: Bon dan Hutang Karyawan
                      _buildLoansTable(loans, isMobile),
                      const SizedBox(height: 32),

                      // Footer Copyright
                      _buildFooter(),
                      const SizedBox(height: 24),
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

  // ---------------------------------------------------------------------------
  // A. Header Section
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penggajian', style: AppText.pageTitle),
            SizedBox(height: 4),
            Text(
              'Kelola gaji dengan akurat. Pastikan tim dibayar tepat waktu.',
              style: AppText.small,
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            // Export Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text2,
                side: const BorderSide(color: AppColors.borderStrong),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(AppIcons.export, size: 16),
              label: const Text('Ekspor laporan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () => _showExportMenu(context),
            ),

            // Process Payroll Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(AppIcons.process, size: 16),
              label: const Text('Proses payroll', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () => ProcessPayrollModal.show(context, widget.store),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // B. Period Bar
  // ---------------------------------------------------------------------------
  Widget _buildPeriodBar(bool isMobile) {
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
              const Text(
                'Periode penggajian',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
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
                      widget.store.periodLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(AppIcons.chevronDown, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
              Text(
                '01 Okt ${widget.store.periodYear} – 31 Okt ${widget.store.periodYear}',
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
                'Tanggal gajian: ${widget.store.settings.payday} Okt ${widget.store.periodYear}',
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. 4 Stat Cards
  // ---------------------------------------------------------------------------
  Widget _buildStatCards(PayrollTotals t, bool isMobile, bool isTablet) {
    final crossCount = isMobile ? 1 : (isTablet ? 2 : 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((crossCount - 1) * 16)) / crossCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: Total gaji bersih (Emerald solid)
            SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A065F46),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Total gaji bersih',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFD1FAE5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(AppIcons.payroll, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.rupiah(t.net),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gaji yang diterima seluruh karyawan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFA7F3D0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Karyawan dalam payroll
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
                            'Karyawan dalam payroll',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(AppIcons.employees, size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${t.count} karyawan',
                      style: AppText.statValue,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t.count} karyawan aktif · ${t.departments} departemen',
                      style: AppText.tiny,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Card 3: Sudah dibayarkan
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
                            'Sudah dibayarkan',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(AppIcons.checkCircle, size: 16, color: AppColors.primary700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.rupiah(t.paidAmount),
                        style: AppText.statValue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t.paidCount} dari ${t.count} karyawan telah menerima gaji',
                      style: AppText.tiny,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Card 4: Belum dibayarkan
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.amber50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(AppIcons.clock, size: 16, color: AppColors.amber700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Fmt.rupiah(t.unpaidAmount),
                        style: AppText.statValue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t.readyCount} siap dibayar · ${t.reviewCount} perlu ditinjau',
                      style: AppText.tiny,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // D. 2-Column Component Summary & Payment Status
  // ---------------------------------------------------------------------------
  Widget _buildTwoColumnSummary(PayrollTotals t, List<PayrollLine> lines, bool isMobile) {
    final paidPercent = t.count == 0 ? 0.0 : (t.paidCount / t.count * 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSingleColumn = constraints.maxWidth < 900;

        final leftCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Ringkasan komponen gaji',
                    style: AppText.sectionTitle,
                  ),
                  Text(
                    'Total bruto ${Fmt.rupiah(t.gross)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Horizontal Proportional Bar
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
              const SizedBox(height: 18),

              // 3 Columns Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Gaji pokok', style: AppText.tiny, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.rupiah(t.base), style: AppText.bodyStrong)),
                        Text(
                          '${Fmt.percent(t.baseRatio, decimals: 0)} dari gaji bruto',
                          style: AppText.tiny,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, color: AppColors.emeraldSoft),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Tunjangan', style: AppText.tiny, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.rupiah(t.allowance), style: AppText.bodyStrong)),
                        Text(
                          '${Fmt.percent(t.allowanceRatio, decimals: 0)} dari gaji bruto',
                          style: AppText.tiny,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, color: AppColors.textSubtle),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Potongan', style: AppText.tiny, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('−${Fmt.rupiah(t.deduction)}', style: AppText.bodyStrong)),
                        const Text('PPh 21, BPJS & lainnya', style: AppText.tiny, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              // Footer of Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Gaji bruto − potongan = total gaji bersih',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Fmt.rupiah(t.net),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final rightCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Status pembayaran',
                    style: AppText.sectionTitle,
                  ),
                  Text(
                    '${paidPercent.toStringAsFixed(1).replaceAll('.', ',')}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 8-Segment Bar
              Row(
                children: List.generate(t.count.clamp(1, 100), (index) {
                  Color segmentColor;
                  if (index < t.paidCount) {
                    segmentColor = AppColors.primary;
                  } else if (index < t.paidCount + t.readyCount) {
                    segmentColor = AppColors.emeraldMist;
                  } else {
                    segmentColor = AppColors.amberSegment;
                  }

                  return Expanded(
                    child: Container(
                      height: 12,
                      margin: EdgeInsets.only(right: index == t.count - 1 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: segmentColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Rows Details
              _statusRow(
                dotColor: AppColors.primary,
                title: 'Sudah dibayar',
                count: t.paidCount,
                amount: t.paidAmount,
              ),
              const SizedBox(height: 8),
              _statusRow(
                dotColor: AppColors.emeraldSoft,
                title: 'Siap dibayar',
                count: t.readyCount,
                amount: t.readyAmount,
              ),
              const SizedBox(height: 8),
              _statusRow(
                dotColor: AppColors.amber700,
                title: 'Perlu ditinjau',
                count: t.reviewCount,
                amount: t.reviewAmount,
              ),

              const SizedBox(height: 14),

              // Yellow Info Alert Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amber50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                ),
                child: const Row(
                  children: [
                    Icon(AppIcons.info, size: 15, color: AppColors.amber700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Periksa potongan Dimas sebelum memproses payroll.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.amber700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isSingleColumn) {
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

  Widget _statusRow({
    required Color dotColor,
    required String title,
    required int count,
    required int amount,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count karyawan',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          Fmt.rupiah(amount),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textStrong,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // E. Table "Payroll karyawan"
  // ---------------------------------------------------------------------------
  Widget _buildPayrollTable(List<PayrollLine> lines, PayrollTotals t, bool isMobile) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Payroll karyawan', style: AppText.sectionTitle),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${lines.length} karyawan',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Terakhir diperbarui ${Fmt.updatedAt(widget.store.lastUpdated)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                ),
              ],
            ),
          ),

          const Divider(),

          // Filters Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Field
                SizedBox(
                  width: isMobile ? double.infinity : 280,
                  height: 38,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(AppIcons.search, size: 16),
                      hintText: 'Cari nama atau ID karyawan...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Department Dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderStrong),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _departmentFilter,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                          items: ['Semua', ...kDepartments].map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d == 'Semua' ? 'Semua departemen' : d),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _departmentFilter = val);
                          },
                        ),
                      ),
                    ),

                    // Status Dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderStrong),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                          items: [
                            const DropdownMenuItem(value: 'Semua', child: Text('Semua status')),
                            const DropdownMenuItem(value: 'paid', child: Text('Sudah dibayar')),
                            const DropdownMenuItem(value: 'ready', child: Text('Siap dibayar')),
                            const DropdownMenuItem(value: 'review', child: Text('Perlu ditinjau')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _statusFilter = val);
                          },
                        ),
                      ),
                    ),

                    // Atur Kolom Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text2,
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(AppIcons.adjust, size: 14),
                      label: const Text('Atur kolom', style: TextStyle(fontSize: 12)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Table Rows with Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 960),
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                headingTextStyle: AppText.tableHead,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 64,
                horizontalMargin: 20,
                columnSpacing: 24,
                columns: [
                  DataColumn(
                    label: Checkbox(
                      value: lines.isNotEmpty && _selectedPayrollIds.length == lines.length,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPayrollIds.addAll(lines.map((l) => l.employee.id));
                          } else {
                            _selectedPayrollIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const DataColumn(label: Text('KARYAWAN')),
                  const DataColumn(label: Text('GAJI POKOK')),
                  const DataColumn(label: Text('TUNJANGAN')),
                  const DataColumn(label: Text('POTONGAN')),
                  const DataColumn(label: Text('GAJI BERSIH')),
                  const DataColumn(label: Text('STATUS')),
                  const DataColumn(label: SizedBox(width: 24)),
                ],
                rows: [
                  ...lines.map((l) {
                    final isReview = l.status == PayrollStatus.review;
                    final isChecked = _selectedPayrollIds.contains(l.employee.id);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isReview) return const Color(0xFFFFFDF5); // bg-amber-50/40
                        if (isChecked) return AppColors.emerald50.withValues(alpha: 0.4);
                        return null;
                      }),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedPayrollIds.add(l.employee.id);
                                } else {
                                  _selectedPayrollIds.remove(l.employee.id);
                                }
                              });
                            },
                          ),
                        ),
                        // Employee Cell
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InitialsAvatar(
                                initials: Fmt.initials(l.employee.name),
                                size: 34,
                                backgroundColor: isReview ? AppColors.amber100 : AppColors.slate100,
                                textColor: isReview ? AppColors.amber700 : AppColors.text2,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l.employee.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  Text(
                                    '${l.employee.id} · ${l.employee.department}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(Fmt.rupiah(l.base), style: AppText.money)),
                        DataCell(Text(Fmt.rupiah(l.allowance), style: AppText.money)),
                        DataCell(
                          Text(
                            Fmt.rupiah(l.deduction),
                            style: AppText.money.copyWith(
                              color: l.deduction > 0 ? AppColors.text2 : AppColors.textSubtle,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            Fmt.rupiah(l.net),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                        DataCell(PayrollStatusBadge(status: l.status)),
                        // Action Menu
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(AppIcons.more, size: 18, color: AppColors.textMuted),
                            onSelected: (action) => _handlePayrollAction(action, l),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'slip',
                                child: Row(
                                  children: [
                                    Icon(AppIcons.fileText, size: 16),
                                    SizedBox(width: 8),
                                    Text('Lihat slip gaji'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(AppIcons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit komponen gaji'),
                                  ],
                                ),
                              ),
                              if (l.status == PayrollStatus.review)
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: Row(
                                    children: [
                                      Icon(AppIcons.checkCircle, size: 16, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Setujui & Siapkan'),
                                    ],
                                  ),
                                ),
                              if (l.status == PayrollStatus.ready)
                                const PopupMenuItem(
                                  value: 'flag',
                                  child: Row(
                                    children: [
                                      Icon(AppIcons.info, size: 16, color: AppColors.amber700),
                                      SizedBox(width: 8),
                                      Text('Tandai perlu ditinjau'),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          const Divider(),

          // Table Total Summary Footer Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 960),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    const SizedBox(width: 48), // checkbox width
                    const SizedBox(
                      width: 200,
                      child: Text(
                        'Total penggajian',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        Fmt.rupiah(t.base),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        Fmt.rupiah(t.allowance),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        Fmt.rupiah(t.deduction),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        Fmt.rupiah(t.net),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(),

          // Table Pagination Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Menampilkan ${lines.length} dari ${lines.length} karyawan',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.emerald200),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F. Table "Bon dan hutang karyawan"
  // ---------------------------------------------------------------------------
  Widget _buildLoansTable(List<Loan> loans, bool isMobile) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 320 : 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text('Bon dan hutang karyawan', style: AppText.sectionTitle),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${loans.length} karyawan',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pantau karyawan yang punya bon atau hutang agar potongan gaji bisa diperbarui sebelum payroll diproses.',
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),

                // Green button "Catat bon baru"
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(AppIcons.add, size: 16),
                  label: const Text('Catat bon baru', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  onPressed: () => AddLoanModal.show(context, widget.store),
                ),
              ],
            ),
          ),

          const Divider(),

          // Table Rows
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                headingTextStyle: AppText.tableHead,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 62,
                horizontalMargin: 20,
                columnSpacing: 24,
                columns: [
                  DataColumn(
                    label: Checkbox(
                      value: loans.isNotEmpty && _selectedLoanIds.length == loans.length,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLoanIds.addAll(loans.map((l) => l.id));
                          } else {
                            _selectedLoanIds.clear();
                          }
                        });
                      },
                    ),
                  ),
                  const DataColumn(label: Text('KARYAWAN')),
                  const DataColumn(label: Text('JUMLAH BON')),
                  const DataColumn(label: Text('POTONGAN')),
                  const DataColumn(label: Text('SISA HUTANG')),
                  const DataColumn(label: Text('STATUS')),
                  const DataColumn(label: SizedBox(width: 24)),
                ],
                rows: loans.map((loan) {
                  final emp = widget.store.employeeById(loan.employeeId);
                  final name = emp?.name ?? loan.employeeId;
                  final dept = emp?.department ?? '-';
                  final isChecked = _selectedLoanIds.contains(loan.id);

                  return DataRow(
                    selected: isChecked,
                    cells: [
                      DataCell(
                        Checkbox(
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedLoanIds.add(loan.id);
                              } else {
                                _selectedLoanIds.remove(loan.id);
                              }
                            });
                          },
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InitialsAvatar(
                              initials: Fmt.initials(name),
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textStrong,
                                  ),
                                ),
                                Text(
                                  '${loan.employeeId} · $dept',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(Fmt.rupiah(loan.amount), style: AppText.money)),
                      DataCell(Text(Fmt.rupiah(loan.deduction), style: AppText.money)),
                      DataCell(
                        Text(
                          Fmt.rupiah(loan.remaining),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                      DataCell(LoanStatusBadge(isPaidOff: loan.isPaidOff)),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(AppIcons.more, size: 18, color: AppColors.textMuted),
                          onSelected: (action) => _handleLoanAction(action, loan),
                          itemBuilder: (context) => [
                            if (!loan.isPaidOff)
                              const PopupMenuItem(
                                value: 'payoff',
                                child: Text('Tandai Lunas Sekarang'),
                              ),
                            PopupMenuItem(
                              value: 'sync_toggle',
                              child: Text(
                                loan.syncToPayroll
                                    ? 'Nonaktifkan Sinkron Payroll'
                                    : 'Sinkronkan Potongan ke Payroll',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Hapus Data Bon',
                                style: TextStyle(color: AppColors.rose600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(),

          // Pagination Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Menampilkan ${loans.length} dari ${loans.length} karyawan',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Halaman 1 dari 1', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // G. Footnotes
  // ---------------------------------------------------------------------------
  Widget _buildFooter() {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(
          'ⓘ Semua nominal dalam Rupiah (IDR). Gaji bersih = gaji pokok + tunjangan − potongan.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          '© 2026 Payrole',
          style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void _handlePayrollAction(String action, PayrollLine line) {
    switch (action) {
      case 'slip':
        PayslipModal.show(context, widget.store, line);
        break;
      case 'edit':
        EditComponentsModal.show(context, widget.store, line.employee);
        break;
      case 'approve':
        widget.store.approveReview(line.employee.id);
        break;
      case 'flag':
        widget.store.flagForReview(line.employee.id);
        break;
    }
  }

  void _handleLoanAction(String action, Loan loan) {
    switch (action) {
      case 'payoff':
        widget.store.payOffLoan(loan.id, viaPayroll: false);
        break;
      case 'sync_toggle':
        widget.store.setLoanSync(loan.id, !loan.syncToPayroll);
        break;
      case 'delete':
        widget.store.deleteLoan(loan.id);
        break;
    }
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ekspor Laporan Payroll', style: AppText.sectionTitle),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(AppIcons.print, color: AppColors.primary),
                  title: const Text('Cetak / Unduh PDF Lengkap'),
                  subtitle: const Text('Format siap cetak dengan tabel rapi seluruh karyawan'),
                  onTap: () {
                    Navigator.of(context).pop();
                    PdfService.printOrShareReport(
                      lines: widget.store.payrollLines,
                      companyName: widget.store.settings.companyName,
                      periodLabel: widget.store.periodLabel,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.export, color: AppColors.primary),
                  title: const Text('Ekspor File CSV (Excel Compatible)'),
                  subtitle: const Text('Format CSV dengan UTF-8 BOM untuk olah data finansial'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final csv = await CsvService.generatePayrollCsv(
                      lines: widget.store.payrollLines,
                      periodLabel: widget.store.periodLabel,
                    );
                    await CsvService.shareCsv(
                      csv,
                      'Payroll_${widget.store.periodLabel.replaceAll(' ', '_')}.csv',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
