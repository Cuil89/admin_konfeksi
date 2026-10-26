import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class ReimbursementPage extends StatefulWidget {
  const ReimbursementPage({super.key, required this.store});

  final AppStore store;

  @override
  State<ReimbursementPage> createState() => _ReimbursementPageState();
}

class _ReimbursementPageState extends State<ReimbursementPage> {
  String _categoryFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final claims = widget.store.reimbursements.where((r) {
          if (_categoryFilter == 'Semua') return true;
          return r.category == _categoryFilter;
        }).toList();

        final pendingTotal = claims
            .where((r) => r.status == ReimbursementStatus.pending)
            .fold(0, (s, r) => s + r.amount);

        final approvedTotal = claims
            .where((r) => r.status == ReimbursementStatus.approved)
            .fold(0, (s, r) => s + r.amount);

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
                              Text('Reimbursement', style: AppText.pageTitle),
                              SizedBox(height: 4),
                              Text(
                                'Klaim pengeluaran operasional dan medis karyawan.',
                                style: AppText.small,
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            ),
                            icon: const Icon(AppIcons.add, size: 16),
                            label: const Text('Ajukan Klaim Baru'),
                            onPressed: () => _showAddClaimDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Filter Bar
                      Row(
                        children: [
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
                                value: _categoryFilter,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                                items: ['Semua', ...kReimbursementCategories].map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(c == 'Semua' ? 'Semua Kategori' : c),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _categoryFilter = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Quick Stats
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _statBox('Menunggu Persetujuan', Fmt.rupiah(pendingTotal), AppColors.amber700, AppColors.amber50),
                          _statBox('Total Disetujui', Fmt.rupiah(approvedTotal), AppColors.primary700, AppColors.emerald50),
                          _statBox('Total Pengajuan', '${claims.length} klaim', AppColors.textStrong, AppColors.slate100),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Claims Table
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 850),
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                              headingTextStyle: AppText.tableHead,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 62,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('KARYAWAN')),
                                DataColumn(label: Text('KATEGORI')),
                                DataColumn(label: Text('KETERANGAN')),
                                DataColumn(label: Text('TANGGAL')),
                                DataColumn(label: Text('NOMINAL')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: SizedBox(width: 24)),
                              ],
                              rows: claims.map((claim) {
                                final emp = widget.store.employeeById(claim.employeeId);
                                final name = emp?.name ?? claim.employeeId;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InitialsAvatar(initials: Fmt.initials(name), size: 32),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(name, style: AppText.bodyStrong),
                                              Text(claim.employeeId, style: AppText.tiny),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(claim.category, style: AppText.body)),
                                    DataCell(Text(claim.description, style: AppText.body)),
                                    DataCell(Text(Fmt.date(claim.date), style: AppText.body)),
                                    DataCell(Text(Fmt.rupiah(claim.amount), style: AppText.money)),
                                    DataCell(ReimbursementStatusBadge(status: claim.status)),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(AppIcons.more, size: 18, color: AppColors.textMuted),
                                        onSelected: (action) {
                                          if (action == 'approve') {
                                            widget.store.setReimbursementStatus(claim.id, ReimbursementStatus.approved);
                                          } else if (action == 'reject') {
                                            widget.store.setReimbursementStatus(claim.id, ReimbursementStatus.rejected);
                                          } else if (action == 'delete') {
                                            widget.store.deleteReimbursement(claim.id);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (claim.status == ReimbursementStatus.pending) ...[
                                            const PopupMenuItem(
                                              value: 'approve',
                                              child: Text('Setujui Klaim'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'reject',
                                              child: Text('Tolak Klaim', style: TextStyle(color: AppColors.rose600)),
                                            ),
                                          ],
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus Data'),
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

  Widget _statBox(String title, String val, Color textC, Color bgC) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgC,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textC.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: textC, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textC)),
        ],
      ),
    );
  }

  void _showAddClaimDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final employees = widget.store.activeEmployees;
    var selectedEmp = employees.isNotEmpty ? employees.first.id : '';
    var selectedCat = kReimbursementCategories.first;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ajukan Reimbursement Baru', style: AppText.sectionTitle),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedEmp.isNotEmpty ? selectedEmp : null,
                    decoration: const InputDecoration(labelText: 'Karyawan'),
                    items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                    onChanged: (v) => selectedEmp = v ?? selectedEmp,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    decoration: const InputDecoration(labelText: 'Kategori Pengeluaran'),
                    items: kReimbursementCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => selectedCat = v ?? selectedCat,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Nominal Klaim', prefixText: 'Rp '),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nominal harus diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Keterangan Pengeluaran'),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Keterangan minimal 3 karakter' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final amt = int.tryParse(amountCtrl.text) ?? 0;
                          widget.store.addReimbursement(
                            employeeId: selectedEmp,
                            category: selectedCat,
                            description: descCtrl.text,
                            amount: amt,
                            date: DateTime.now(),
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Klaim reimbursement diajukan.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: const Text('Ajukan Klaim'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
