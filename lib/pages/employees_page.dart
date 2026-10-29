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
  String _statusFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final allEmployees = widget.store.employees;
        final activeEmployees = widget.store.activeEmployees;

        final employees = allEmployees.where((e) {
          final q = _search.trim().toLowerCase();
          final matchQ = q.isEmpty ||
              e.name.toLowerCase().contains(q) ||
              e.id.toLowerCase().contains(q) ||
              e.position.toLowerCase().contains(q);
          final matchD = _departmentFilter == 'Semua' || e.department == _departmentFilter;
          final matchS = _statusFilter == 'Semua' ||
              (_statusFilter == 'Aktif' ? e.active : !e.active);
          return matchQ && matchD && matchS;
        }).toList();

        final totalDailyRate = activeEmployees.fold<int>(
            0, (sum, e) => sum + e.effectiveDailyRate);

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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Manajemen Karyawan', style: AppText.pageTitle),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Text(
                                      'Akses Pemilik (CRUD)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${activeEmployees.length} karyawan aktif di ${kDepartments.length} divisi/departemen.',
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

                      // Quick Stat Cards
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _statBox('Total Karyawan', '${allEmployees.length} orang', AppColors.textStrong, AppColors.slate100),
                          _statBox('Karyawan Aktif', '${activeEmployees.length} orang', AppColors.primary, AppColors.emerald50),
                          _statBox('Total Beban Gaji Harian', Fmt.rupiah(totalDailyRate), const Color(0xFF0F766E), const Color(0xFFCCFBF1)),
                          _statBox('Divisi Terdaftar', '${kDepartments.length} divisi', const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
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
                                  hintText: 'Cari nama, ID, jabatan...',
                                ),
                                onChanged: (val) => setState(() => _search = val),
                              ),
                            ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
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
                                      value: _departmentFilter,
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                                      items: ['Semua', ...kDepartments].map((d) {
                                        return DropdownMenuItem(
                                          value: d,
                                          child: Text(d == 'Semua' ? 'Semua Divisi' : d),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _departmentFilter = val);
                                      },
                                    ),
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
                                      value: _statusFilter,
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                                      items: const ['Semua', 'Aktif', 'Non-aktif'].map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s == 'Semua' ? 'Semua Status' : s),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _statusFilter = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
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
                            constraints: const BoxConstraints(minWidth: 1050),
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                              headingTextStyle: AppText.tableHead,
                              dataRowMinHeight: 58,
                              dataRowMaxHeight: 68,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('KARYAWAN')),
                                DataColumn(label: Text('JABATAN')),
                                DataColumn(label: Text('GAJI / HARI')),
                                DataColumn(label: Text('GAJI POKOK')),
                                DataColumn(label: Text('METODE BAYAR')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('AKSI')),
                              ],
                              rows: employees.map((e) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      InkWell(
                                        onTap: () => _showEmployeeDetailDialog(context, e),
                                        child: Row(
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
                                    ),
                                    DataCell(Text(e.position, style: AppText.body)),
                                    DataCell(
                                      Text(
                                        Fmt.rupiah(e.effectiveDailyRate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.primary700,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(Fmt.rupiah(e.baseSalary), style: AppText.money)),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(e.paymentMethod, style: AppText.body),
                                          if (e.bankAccount != null && e.bankAccount!.isNotEmpty)
                                            Text(e.bankAccount!, style: AppText.tiny),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      StatusBadge(
                                        label: e.active ? 'Aktif' : 'Non-aktif',
                                        textColor: e.active ? AppColors.primary700 : AppColors.textMuted,
                                        backgroundColor: e.active ? AppColors.emerald50 : AppColors.slate100,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(AppIcons.info, size: 17, color: AppColors.primary),
                                            tooltip: 'Lihat Detail',
                                            onPressed: () => _showEmployeeDetailDialog(context, e),
                                          ),
                                          IconButton(
                                            icon: const Icon(AppIcons.edit, size: 17, color: AppColors.text2),
                                            tooltip: 'Edit Data Karyawan',
                                            onPressed: () => _showEditEmployeeDialog(context, e),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(AppIcons.more, size: 17, color: AppColors.textMuted),
                                            tooltip: 'Opsi Lainnya',
                                            onSelected: (action) {
                                              if (action == 'toggle_active') {
                                                widget.store.setEmployeeActive(e.id, !e.active);
                                              } else if (action == 'delete') {
                                                _showDeleteEmployeeDialog(context, e);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'toggle_active',
                                                child: Text(e.active ? 'Nonaktifkan' : 'Aktifkan Kembali'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Hapus Permanen', style: TextStyle(color: AppColors.rose600)),
                                              ),
                                            ],
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

  // ---------------------------------------------------------------------------
  // CREATE: Tambah Karyawan Baru
  // ---------------------------------------------------------------------------
  void _showAddEmployeeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final posCtrl = TextEditingController();
    final dailyRateCtrl = TextEditingController(text: '160000');
    final baseCtrl = TextEditingController(text: '4000000');
    final allowCtrl = TextEditingController(text: '500000');
    final bankCtrl = TextEditingController();
    var selectedDept = kDepartments.first;
    var selectedPayment = 'Transfer Bank';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(AppIcons.add, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Input Karyawan Baru', style: AppText.sectionTitle),
                            Text('Otoritas Pemilik Konveksi', style: AppText.tiny),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Contoh: Ahmad Fauzi',
                    ),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Minimal 3 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDept,
                          decoration: const InputDecoration(labelText: 'Divisi / Departemen'),
                          items: kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => selectedDept = v ?? selectedDept,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: posCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Jabatan / Keahlian',
                            hintText: 'Misal: Operator Jahit Kaos',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Jabatan wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dailyRateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Absensi / Hari',
                            prefixText: 'Rp ',
                            helperText: 'Upah kehadiran harian',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.isEmpty ? 'Gaji harian wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: baseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Pokok / Bulan',
                            prefixText: 'Rp ',
                            helperText: 'Gaji dasar acuan',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.isEmpty ? 'Gaji pokok wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: allowCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tunjangan / Uang Makan Bulanan',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email Karyawan',
                            hintText: 'nama@konveksi.id',
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Email valid dibutuhkan' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp / Telepon',
                            hintText: '081234567890',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.length < 8 ? 'Nomor telepon 8-15 digit' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPayment,
                          decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                          items: const [
                            DropdownMenuItem(value: 'Transfer Bank', child: Text('Transfer Bank')),
                            DropdownMenuItem(value: 'Tunai Amplop', child: Text('Tunai Amplop')),
                            DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
                          ],
                          onChanged: (v) => selectedPayment = v ?? selectedPayment,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: bankCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bank & No. Rekening',
                            hintText: 'BCA 1234567890',
                          ),
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
                              allowance: int.parse(allowCtrl.text.isEmpty ? '0' : allowCtrl.text),
                              dailyRate: int.tryParse(dailyRateCtrl.text),
                              paymentMethod: selectedPayment,
                              bankAccount: bankCtrl.text.isNotEmpty ? bankCtrl.text : null,
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Karyawan baru berhasil ditambahkan oleh Pemilik.'),
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

  // ---------------------------------------------------------------------------
  // READ: Detail Karyawan
  // ---------------------------------------------------------------------------
  void _showEmployeeDetailDialog(BuildContext context, Employee e) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InitialsAvatar(initials: Fmt.initials(e.name), size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: AppText.sectionTitle),
                          Text('${e.id} · ${e.department} · ${e.position}', style: AppText.small),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: e.active ? 'Aktif' : 'Non-aktif',
                      textColor: e.active ? AppColors.primary700 : AppColors.textMuted,
                      backgroundColor: e.active ? AppColors.emerald50 : AppColors.slate100,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text('SKEMA GAJI & UPAH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSubtle)),
                const SizedBox(height: 8),
                _detailRow('Gaji Absensi Per Hari', Fmt.rupiah(e.effectiveDailyRate), isBold: true, highlightColor: AppColors.primary700),
                _detailRow('Gaji Pokok Bulanan', Fmt.rupiah(e.baseSalary)),
                _detailRow('Tunjangan Bulanan', Fmt.rupiah(e.allowance)),
                _detailRow('Potongan Wajib (BPJS & PPh)', Fmt.rupiah(e.statutoryDeduction)),
                const SizedBox(height: 16),
                const Text('KONTAK & DATA PEMBAYARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSubtle)),
                const SizedBox(height: 8),
                _detailRow('Email', e.email),
                _detailRow('Nomor Telepon/WA', e.phone),
                _detailRow('Tanggal Bergabung', Fmt.date(e.joinDate)),
                _detailRow('Metode Pembayaran', e.paymentMethod),
                if (e.bankAccount != null && e.bankAccount!.isNotEmpty)
                  _detailRow('Rekening Bank', e.bankAccount!),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.edit, size: 16),
                      label: const Text('Edit Data'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditEmployeeDialog(context, e);
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
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

  Widget _detailRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.text2)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: highlightColor ?? AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE: Edit Data Karyawan
  // ---------------------------------------------------------------------------
  void _showEditEmployeeDialog(BuildContext context, Employee e) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: e.name);
    final emailCtrl = TextEditingController(text: e.email);
    final phoneCtrl = TextEditingController(text: e.phone);
    final posCtrl = TextEditingController(text: e.position);
    final dailyRateCtrl = TextEditingController(text: e.effectiveDailyRate.toString());
    final baseCtrl = TextEditingController(text: e.baseSalary.toString());
    final allowCtrl = TextEditingController(text: e.allowance.toString());
    final bankCtrl = TextEditingController(text: e.bankAccount ?? '');
    var selectedDept = kDepartments.contains(e.department) ? e.department : kDepartments.first;
    var selectedPayment = e.paymentMethod;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(AppIcons.edit, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Karyawan: ${e.name}', style: AppText.sectionTitle),
                            Text('ID: ${e.id} · Perubahan oleh Pemilik', style: AppText.tiny),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Minimal 3 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDept,
                          decoration: const InputDecoration(labelText: 'Divisi / Departemen'),
                          items: kDepartments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => selectedDept = v ?? selectedDept,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: posCtrl,
                          decoration: const InputDecoration(labelText: 'Jabatan / Posisi'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Jabatan wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dailyRateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Absensi / Hari',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.isEmpty ? 'Gaji harian wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: baseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Gaji Pokok / Bulan',
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v == null || v.isEmpty ? 'Gaji pokok wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: allowCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tunjangan Bulanan',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email Perusahaan'),
                          validator: (v) => v == null || !v.contains('@') ? 'Email valid dibutuhkan' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'WhatsApp / Telepon'),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v == null || v.length < 8 ? 'Nomor telepon 8-15 digit' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPayment,
                          decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                          items: const [
                            DropdownMenuItem(value: 'Transfer Bank', child: Text('Transfer Bank')),
                            DropdownMenuItem(value: 'Tunai Amplop', child: Text('Tunai Amplop')),
                            DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
                          ],
                          onChanged: (v) => selectedPayment = v ?? selectedPayment,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: bankCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bank & No. Rekening',
                            hintText: 'BCA 1234567890',
                          ),
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
                            widget.store.updateEmployee(
                              e.id,
                              name: nameCtrl.text,
                              department: selectedDept,
                              position: posCtrl.text,
                              email: emailCtrl.text,
                              phone: phoneCtrl.text,
                              joinDate: e.joinDate,
                              baseSalary: int.parse(baseCtrl.text),
                              allowance: int.parse(allowCtrl.text.isEmpty ? '0' : allowCtrl.text),
                              dailyRate: int.tryParse(dailyRateCtrl.text),
                              paymentMethod: selectedPayment,
                              bankAccount: bankCtrl.text.isNotEmpty ? bankCtrl.text : null,
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Data ${e.name} berhasil diperbarui.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err.toString()), backgroundColor: AppColors.rose600),
                            );
                          }
                        },
                        child: const Text('Simpan Perubahan'),
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

  // ---------------------------------------------------------------------------
  // DELETE: Hapus / Nonaktifkan Karyawan
  // ---------------------------------------------------------------------------
  void _showDeleteEmployeeDialog(BuildContext context, Employee e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(AppIcons.delete, color: AppColors.rose600, size: 22),
            const SizedBox(width: 8),
            Text('Hapus ${e.name}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus data karyawan ${e.name} (${e.id})?'),
            const SizedBox(height: 12),
            const Text(
              'Perhatian: Jika karyawan memiliki riwayat payroll atau kasbon aktif, sistem menyarankan untuk "Nonaktifkan" daripada menghapus data permanen.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () {
              widget.store.setEmployeeActive(e.id, false);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${e.name} telah dinonaktifkan.')),
              );
            },
            child: const Text('Nonaktifkan Saja'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              try {
                widget.store.deleteEmployee(e.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Karyawan ${e.name} berhasil dihapus permanen.'),
                    backgroundColor: AppColors.rose600,
                  ),
                );
              } catch (err) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err.toString()), backgroundColor: AppColors.rose600),
                );
              }
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }
}
