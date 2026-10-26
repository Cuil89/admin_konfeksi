import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../badges.dart';

class ProcessPayrollModal extends StatefulWidget {
  const ProcessPayrollModal({super.key, required this.store});

  final AppStore store;

  static Future<void> show(BuildContext context, AppStore store) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProcessPayrollModal(store: store),
    );
  }

  @override
  State<ProcessPayrollModal> createState() => _ProcessPayrollModalState();
}

class _ProcessPayrollModalState extends State<ProcessPayrollModal> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    final readyLines = widget.store.payrollLines
        .where((l) => l.status == PayrollStatus.ready)
        .toList();
    _selectedIds.addAll(readyLines.map((l) => l.employee.id));
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.store.payrollLines;
    final readyLines =
        lines.where((l) => l.status == PayrollStatus.ready).toList();
    final reviewLines =
        lines.where((l) => l.status == PayrollStatus.review).toList();

    var selectedTotal = 0;
    for (final id in _selectedIds) {
      final line = lines.firstWhere((l) => l.employee.id == id);
      selectedTotal += line.net;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      AppIcons.process,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Proses Payroll', style: AppText.sectionTitle),
                        SizedBox(height: 2),
                        Text(
                          'Pilih karyawan untuk memproses pembayaran gaji periode ini.',
                          style: AppText.small,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Review Warning Alert
              if (reviewLines.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(AppIcons.info, size: 18, color: AppColors.amber700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reviewLines.length} Karyawan Perlu Ditinjau',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              reviewLines
                                  .map((l) =>
                                      '${l.employee.name}: ${l.employee.reviewNote ?? "Periksa rincian potongan"}')
                                  .join('\n'),
                              style: AppText.tiny.copyWith(color: AppColors.amber700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Summary Stats Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Terpilih Diproses',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedIds.length} dari ${readyLines.length} siap dibayar',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Nominal Pencairan',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Fmt.rupiah(selectedTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Employee List Section
              Expanded(
                child: ListView(
                  children: [
                    if (readyLines.isEmpty) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Tidak ada karyawan yang berstatus Siap dibayar.',
                            style: AppText.small,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Select All Row
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedIds.length == readyLines.length,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.addAll(
                                      readyLines.map((l) => l.employee.id));
                                } else {
                                  _selectedIds.clear();
                                }
                              });
                            },
                          ),
                          const Text(
                            'Pilih Semua Karyawan Siap Dibayar',
                            style: AppText.bodyStrong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      ...readyLines.map((line) {
                        final isChecked = _selectedIds.contains(line.employee.id);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChecked
                                  ? AppColors.primary
                                  : AppColors.borderStrong,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedIds.add(line.employee.id);
                                    } else {
                                      _selectedIds.remove(line.employee.id);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.employee.name,
                                      style: AppText.bodyStrong,
                                    ),
                                    Text(
                                      '${line.employee.id} · ${line.employee.department}',
                                      style: AppText.tiny,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Fmt.rupiah(line.net),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  const PayrollStatusBadge(
                                      status: PayrollStatus.ready),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Show review items with quick approve button
                    if (reviewLines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Karyawan Dalam Peninjauan:',
                        style: AppText.bodyStrong,
                      ),
                      const SizedBox(height: 6),
                      ...reviewLines.map((line) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.employee.name,
                                      style: AppText.bodyStrong,
                                    ),
                                    Text(
                                      '${line.employee.id} · ${line.employee.department}',
                                      style: AppText.tiny,
                                    ),
                                    if (line.employee.reviewNote != null)
                                      Text(
                                        line.employee.reviewNote!,
                                        style: AppText.tiny.copyWith(
                                          color: AppColors.amber700,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  widget.store.approveReview(line.employee.id);
                                  setState(() {
                                    _selectedIds.add(line.employee.id);
                                  });
                                },
                                child: const Text(
                                  'Setujui & Siapkan',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(AppIcons.process, size: 16),
                    label: Text(
                      'Bayar Sekarang (${_selectedIds.length})',
                    ),
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            final count = widget.store
                                .processPayroll(_selectedIds);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$count karyawan berhasil dibayarkan!',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
