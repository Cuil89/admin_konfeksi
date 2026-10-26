import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';

class AddLoanModal extends StatefulWidget {
  const AddLoanModal({
    super.key,
    required this.store,
    this.initialEmployeeId,
  });

  final AppStore store;
  final String? initialEmployeeId;

  static Future<void> show(BuildContext context, AppStore store, {String? initialEmployeeId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddLoanModal(
        store: store,
        initialEmployeeId: initialEmployeeId,
      ),
    );
  }

  @override
  State<AddLoanModal> createState() => _AddLoanModalState();
}

class _AddLoanModalState extends State<AddLoanModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmployeeId;
  final _amountController = TextEditingController();
  final _deductionController = TextEditingController();
  final _noteController = TextEditingController();
  bool _syncToPayroll = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final active = widget.store.activeEmployees;
    if (widget.initialEmployeeId != null &&
        active.any((e) => e.id == widget.initialEmployeeId)) {
      _selectedEmployeeId = widget.initialEmployeeId!;
    } else {
      _selectedEmployeeId = active.isNotEmpty ? active.first.id : '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _deductionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _parseMoney(String s) {
    final clean = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseMoney(_amountController.text);
    final deduction = _parseMoney(_deductionController.text);

    try {
      widget.store.addLoan(
        employeeId: _selectedEmployeeId,
        amount: amount,
        deduction: deduction,
        syncToPayroll: _syncToPayroll,
        note: _noteController.text,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bon karyawan berhasil dicatat.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = widget.store.activeEmployees;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        AppIcons.payroll,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catat Bon Baru',
                            style: AppText.sectionTitle,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Catat pinjaman atau kasbon baru untuk karyawan.',
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

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rose50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rose600.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.info, size: 16, color: AppColors.rose700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppText.small.copyWith(color: AppColors.rose700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Employee Selection
                const Text('Karyawan', style: AppText.bodyStrong),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedEmployeeId.isNotEmpty ? _selectedEmployeeId : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(AppIcons.employees, size: 18),
                  ),
                  items: employees.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} (${e.id} · ${e.department})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedEmployeeId = val);
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Pilih karyawan' : null,
                ),

                const SizedBox(height: 16),

                // Amount
                const Text('Jumlah Bon (Total Pinjaman)', style: AppText.bodyStrong),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Contoh: 1.500.000',
                  ),
                  onChanged: (val) {
                    // Update deduction preview if empty
                    if (_deductionController.text.isEmpty) {
                      _deductionController.text = val;
                    }
                  },
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Masukkan jumlah bon';
                    final numVal = _parseMoney(val);
                    if (numVal <= 0) return 'Jumlah bon harus lebih dari 0';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Deduction
                const Text('Potongan Per Bulan (Cicilan)', style: AppText.bodyStrong),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _deductionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Contoh: 250.000',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Masukkan nominal potongan';
                    }
                    final numVal = _parseMoney(val);
                    final amtVal = _parseMoney(_amountController.text);
                    if (numVal <= 0) return 'Potongan harus lebih dari 0';
                    if (numVal > amtVal) {
                      return 'Potongan tidak boleh melebihi jumlah bon';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Sync with Payroll Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sinkronkan ke Payroll Periode Ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textStrong,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Potongan akan langsung mengurangi Gaji Bersih karyawan di tabel payroll.',
                              style: AppText.tiny.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _syncToPayroll,
                        onChanged: (val) => setState(() => _syncToPayroll = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Note
                const Text('Keterangan / Keperluan (Opsional)', style: AppText.bodyStrong),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Biaya berobat keluarga, servis kendaraan...',
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(AppIcons.add, size: 16),
                      label: const Text('Simpan Bon'),
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
