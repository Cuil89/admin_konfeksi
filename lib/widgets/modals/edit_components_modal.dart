import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

class EditComponentsModal extends StatefulWidget {
  const EditComponentsModal({
    super.key,
    required this.store,
    required this.employee,
  });

  final AppStore store;
  final Employee employee;

  static Future<void> show(
    BuildContext context,
    AppStore store,
    Employee employee,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditComponentsModal(
        store: store,
        employee: employee,
      ),
    );
  }

  @override
  State<EditComponentsModal> createState() => _EditComponentsModalState();
}

class _EditComponentsModalState extends State<EditComponentsModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _baseController;
  late TextEditingController _allowanceController;
  late TextEditingController _bpjsKesController;
  late TextEditingController _bpjsKetController;
  late TextEditingController _pph21Controller;
  late TextEditingController _otherController;

  bool _markReady = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _baseController = TextEditingController(text: e.baseSalary.toString());
    _allowanceController = TextEditingController(text: e.allowance.toString());
    _bpjsKesController = TextEditingController(text: e.bpjsKesehatan.toString());
    _bpjsKetController = TextEditingController(text: e.bpjsKetenagakerjaan.toString());
    _pph21Controller = TextEditingController(text: e.pph21.toString());
    _otherController = TextEditingController(text: e.otherDeduction.toString());
  }

  @override
  void dispose() {
    _baseController.dispose();
    _allowanceController.dispose();
    _bpjsKesController.dispose();
    _bpjsKetController.dispose();
    _pph21Controller.dispose();
    _otherController.dispose();
    super.dispose();
  }

  int _parse(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  void _recalcBpjs() {
    final base = _parse(_baseController.text);
    _bpjsKesController.text = AppStore.estimateBpjsKesehatan(base).toString();
    _bpjsKetController.text = AppStore.estimateBpjsKetenagakerjaan(base).toString();
    setState(() {});
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      widget.store.updateComponents(
        widget.employee.id,
        baseSalary: _parse(_baseController.text),
        allowance: _parse(_allowanceController.text),
        bpjsKesehatan: _parse(_bpjsKesController.text),
        bpjsKetenagakerjaan: _parse(_bpjsKetController.text),
        pph21: _parse(_pph21Controller.text),
        otherDeduction: _parse(_otherController.text),
        markReady: _markReady,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komponen gaji berhasil diperbarui.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _parse(_baseController.text);
    final allowance = _parse(_allowanceController.text);
    final bpjsKes = _parse(_bpjsKesController.text);
    final bpjsKet = _parse(_bpjsKetController.text);
    final pph21 = _parse(_pph21Controller.text);
    final other = _parse(_otherController.text);
    final loanDeduction = widget.store.loanDeductionFor(widget.employee.id);

    final gross = base + allowance;
    final totalDeduction = bpjsKes + bpjsKet + pph21 + other + loanDeduction;
    final net = gross - totalDeduction;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Komponen Gaji', style: AppText.sectionTitle),
                        Text(
                          '${widget.employee.name} (${widget.employee.id} · ${widget.employee.department})',
                          style: AppText.small,
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
                const SizedBox(height: 12),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.rose50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.rose600.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppText.small.copyWith(color: AppColors.rose700),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gaji Pokok & Tunjangan
                        const Text('Penghasilan Bruto', style: AppText.bodyStrong),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: 'Gaji Pokok',
                                controller: _baseController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                label: 'Tunjangan',
                                controller: _allowanceController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // BPJS & Taxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Potongan Statuter & Pajak', style: AppText.bodyStrong),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: AppColors.primary,
                              ),
                              icon: const Icon(AppIcons.adjust, size: 14),
                              label: const Text('Hitung Otomatis BPJS', style: TextStyle(fontSize: 12)),
                              onPressed: _recalcBpjs,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: 'BPJS Kes (1%)',
                                controller: _bpjsKesController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                label: 'BPJS TK (3%)',
                                controller: _bpjsKetController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _numberField(
                                label: 'PPh 21',
                                controller: _pph21Controller,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _numberField(
                                label: 'Potongan Lain',
                                controller: _otherController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        if (loanDeduction > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.amber50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(AppIcons.info, size: 16, color: AppColors.amber700),
                                const SizedBox(width: 8),
                                Text(
                                  'Karyawan memiliki cicilan bon aktif: ${Fmt.rupiah(loanDeduction)}',
                                  style: AppText.tiny.copyWith(color: AppColors.amber700),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Live Calculation Preview Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderStrong),
                          ),
                          child: Column(
                            children: [
                              _calcRow('Total Penghasilan Bruto', Fmt.rupiah(gross)),
                              _calcRow('Total Potongan', '−${Fmt.rupiah(totalDeduction)}', color: AppColors.rose600),
                              const Divider(height: 14),
                              _calcRow(
                                'Estimasi Gaji Bersih',
                                Fmt.rupiah(net),
                                isBold: true,
                                color: net >= 0 ? AppColors.primary : AppColors.rose600,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Checkbox mark ready
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Tandai sebagai "Siap dibayar"',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Menghilangkan status "Perlu ditinjau" jika sebelumnya ada catatan peninjauan.',
                            style: AppText.tiny,
                          ),
                          value: _markReady,
                          onChanged: (val) => setState(() => _markReady = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _submit,
                      child: const Text('Simpan Perubahan'),
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

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.small.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            isDense: true,
          ),
          onChanged: onChanged,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Harus diisi';
            return null;
          },
        ),
      ],
    );
  }

  Widget _calcRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.text2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
