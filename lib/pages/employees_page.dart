import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key, required this.store});

  final AppStore store;

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  String _search = '';
  String _departmentFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final employees = widget.store.employees.where((e) {
          final q = _search.trim().toLowerCase();
          final matchQ = q.isEmpty ||
              e.name.toLowerCase().contains(q) ||
              e.id.toLowerCase().contains(q);
          final matchD = _departmentFilter == 'Semua' || e.department == _departmentFilter;
          return matchQ && matchD;
        }).toList();

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Karyawan', style: AppText.pageTitle),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.store.activeEmployees.length} karyawan aktif di ${kDepartments.length} departemen.',
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
                            label: const Text('Tambah Karyawan'),
                            onPressed: () => _showAddEmployeeDialog(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Filter Bar
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: isMobile ? double.infinity : 280,
                              height: 38,
                              child: TextField(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(AppIcons.search, size: 16),
                                  hintText: 'Cari nama atau ID...',
                                ),
                                onChanged: (val) => setState(() => _search = val),
                              ),
                            ),
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
                                      child: Text(d == 'Semua' ? 'Semua Departemen' : d),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _departmentFilter = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Employees Table
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 900),
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                              headingTextStyle: AppText.tableHead,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('KARYAWAN')),
                                DataColumn(label: Text('JABATAN')),
                                DataColumn(label: Text('KONTAK')),
                                DataColumn(label: Text('TANGGAL GABUNG')),
                                DataColumn(label: Text('GAJI POKOK')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: SizedBox(width: 24)),
                              ],
                              rows: employees.map((e) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InitialsAvatar(initials: Fmt.initials(e.name), size: 34),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(e.name, style: AppText.bodyStrong),
                                              Text('${e.id} · ${e.department}', style: AppText.tiny),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(e.position, style: AppText.body)),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(e.email, style: AppText.tiny),
                                          Text(Fmt.maskPhone(e.phone), style: AppText.tiny),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(Fmt.date(e.joinDate), style: AppText.body)),
                                    DataCell(Text(Fmt.rupiah(e.baseSalary), style: AppText.money)),
                                    DataCell(
                                      StatusBadge(
                                        label: e.active ? 'Aktif' : 'Non-aktif',
                                        textColor: e.active ? AppColors.primary700 : AppColors.textMuted,
                                        backgroundColor: e.active ? AppColors.emerald50 : AppColors.slate100,
                                      ),
                                    ),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(AppIcons.more, size: 18, color: AppColors.textMuted),
                                        onSelected: (action) {
                                          if (action == 'toggle_active') {
                                            widget.store.setEmployeeActive(e.id, !e.active);
                                          } else if (action == 'delete') {
                                            widget.store.deleteEmployee(e.id);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'toggle_active',
                                            child: Text(e.active ? 'Nonaktifkan' : 'Aktifkan Kembali'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus', style: TextStyle(color: AppColors.rose600)),
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

  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final baseCtrl = TextEditingController(text: '8000000');
    final allowCtrl = TextEditingController(text: '1000000');
    var selectedDept = kDepartments.first;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tambah Karyawan Baru', style: AppText.sectionTitle),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Minimal 3 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDept,
                    decoration: const InputDecoration(labelText: 'Departemen'),
                    items: kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => selectedDept = v ?? selectedDept,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: posCtrl,
                    decoration: const InputDecoration(labelText: 'Jabatan / Posisi'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Jabatan wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Perusahaan'),
                    validator: (v) => v == null || !v.contains('@') ? 'Email valid dibutuhkan' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Nomor WhatsApp / Telepon'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.length < 8 ? 'Nomor telepon 8-15 digit' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: baseCtrl,
                          decoration: const InputDecoration(labelText: 'Gaji Pokok', prefixText: 'Rp '),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: allowCtrl,
                          decoration: const InputDecoration(labelText: 'Tunjangan', prefixText: 'Rp '),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
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
                          try {
                            widget.store.addEmployee(
                              name: nameCtrl.text,
                              department: selectedDept,
                              position: posCtrl.text,
                              email: emailCtrl.text,
                              phone: phoneCtrl.text,
                              joinDate: DateTime.now(),
                              baseSalary: int.parse(baseCtrl.text),
                              allowance: int.parse(allowCtrl.text),
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Karyawan berhasil ditambahkan.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.rose600),
                            );
                          }
                        },
                        child: const Text('Simpan Karyawan'),
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
