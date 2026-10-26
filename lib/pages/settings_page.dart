import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../security/auth_state.dart';
import '../widgets/app_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.store,
    required this.authState,
  });

  final AppStore store;
  final AuthState authState;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _companyController;
  late int _payday;

  @override
  void initState() {
    super.initState();
    _companyController =
        TextEditingController(text: widget.store.settings.companyName);
    _payday = widget.store.settings.payday;
  }

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.store, widget.authState]),
      builder: (context, _) {
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
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text('Pengaturan', style: AppText.pageTitle),
                      const SizedBox(height: 4),
                      const Text(
                        'Konfigurasi data perusahaan, tanggal pembayaran gaji, dan keamanan cyber.',
                        style: AppText.small,
                      ),

                      const SizedBox(height: 24),

                      // Company Information
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Informasi Perusahaan & Siklus Payroll', style: AppText.sectionTitle),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _companyController,
                              decoration: const InputDecoration(labelText: 'Nama Perusahaan'),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              initialValue: _payday,
                              decoration: const InputDecoration(labelText: 'Tanggal Penggajian Bulanan'),
                              items: List.generate(28, (i) => i + 1).map((day) {
                                return DropdownMenuItem(
                                  value: day,
                                  child: Text('Tanggal $day setiap bulan'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _payday = val);
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                widget.store.updateSettings(
                                  widget.store.settings.copyWith(
                                    companyName: _companyController.text,
                                    payday: _payday,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengaturan perusahaan berhasil disimpan.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: const Text('Simpan Perubahan'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Cybersecurity & PIN Protection
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Keamanan Cyber & Kunci PIN', style: AppText.sectionTitle),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PBKDF2 Enkripsi',
                                    style: TextStyle(fontSize: 11, color: AppColors.primary700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Data gaji dan identitas karyawan dilindungi oleh enkripsi Secure Storage. '
                              'Anda dapat mengaktifkan proteksi PIN 6 digit untuk mengunci akses.',
                              style: AppText.small,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Proteksi PIN Sesi', style: AppText.bodyStrong),
                              subtitle: Text(
                                widget.authState.isPinSet
                                    ? 'PIN aktif. Sistem akan meminta PIN saat sesi dibuka.'
                                    : 'Atur PIN terlebih dahulu untuk mengaktifkan.',
                                style: AppText.tiny,
                              ),
                              value: widget.authState.isPinRequired,
                              onChanged: (val) async {
                                if (!widget.authState.isPinSet && val) {
                                  _showSetPinDialog(context);
                                } else {
                                  await widget.authState.setPinEnabled(val);
                                }
                              },
                            ),
                            const Divider(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(AppIcons.lock, size: 16),
                                  label: Text(widget.authState.isPinSet ? 'Ubah PIN' : 'Buat PIN Baru'),
                                  onPressed: () => _showSetPinDialog(context),
                                ),
                                if (widget.authState.isPinRequired)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.textStrong,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(AppIcons.lock, size: 16),
                                    label: const Text('Kunci Sesi Sekarang'),
                                    onPressed: () => widget.authState.lockSession(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reset Demo Data
                      AppCard(
                        borderColor: AppColors.rose600.withValues(alpha: 0.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pulihkan Data Demo Awal',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.rose700),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mengembalikan data 8 karyawan dan 4 bon ke kondisi awal sesuai spesifikasi Nusa Digital.',
                              style: AppText.small,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.rose700,
                                side: const BorderSide(color: AppColors.rose600),
                              ),
                              icon: const Icon(AppIcons.delete, size: 16),
                              label: const Text('Reset ke Data Awal'),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Reset Data Demo?'),
                                    content: const Text('Data yang sudah diubah akan kembali ke nilai awal.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose600),
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await widget.store.resetDemo();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Data demo berhasil dipulihkan.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                }
                              },
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

  void _showSetPinDialog(BuildContext context) {
    final pinCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Atur 6 Digit PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gunakan 6 digit angka yang aman untuk mengunci sesi payroll.',
                  style: AppText.small,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  try {
                    await widget.authState.setPin(pinCtrl.text.trim());
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN keamanan berhasil disimpan!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    setModalState(() => error = e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: const Text('Simpan PIN'),
              ),
            ],
          );
        },
      ),
    );
  }
}
