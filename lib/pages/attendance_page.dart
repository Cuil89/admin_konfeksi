import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key, required this.store});

  final AppStore store;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final records = widget.store.attendanceFor(_selectedDate);
        final employees = widget.store.activeEmployees;

        final presentCount = records.where((r) => r.status.isPresent).length;
        final absentCount = records.where((r) => !r.status.isPresent).length;
        var totalDailyWageToday = 0;
        for (final emp in employees) {
          final rec = records.firstWhere(
            (r) => r.employeeId == emp.id,
            orElse: () => AttendanceRecord(
              employeeId: emp.id,
              day: Fmt.isoDay(_selectedDate),
              status: AttendanceStatus.present,
            ),
          );
          if (rec.status.isPresent) {
            totalDailyWageToday += emp.effectiveDailyRate;
          }
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kehadiran', style: AppText.pageTitle),
                              const SizedBox(height: 4),
                              Text(
                                'Kelola presensi harian karyawan dan izin kerja.',
                                style: AppText.small,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(AppIcons.calendar, size: 16),
                                label: Text(Fmt.dateWithDay(_selectedDate)),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                icon: const Icon(AppIcons.check, size: 16),
                                label: const Text('Tandai Semua Hadir'),
                                onPressed: () {
                                  widget.store.markAllPresent(_selectedDate);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Semua karyawan ditandai hadir.'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Attendance Quick Stats
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _statBox('Hadir Hari Ini', '$presentCount karyawan', AppColors.primary, AppColors.emerald50),
                          _statBox('Beban Upah Hari Ini', Fmt.rupiah(totalDailyWageToday), const Color(0xFF0F766E), const Color(0xFFCCFBF1)),
                          _statBox('Tidak Hadir / Izin', '$absentCount karyawan', AppColors.amber700, AppColors.amber50),
                          _statBox('Total Terdaftar', '${employees.length} karyawan', AppColors.textStrong, AppColors.slate100),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Attendance Table
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 960),
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                              headingTextStyle: AppText.tableHead,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 62,
                              horizontalMargin: 20,
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('KARYAWAN')),
                                DataColumn(label: Text('GAJI / HARI')),
                                DataColumn(label: Text('STATUS KEHADIRAN')),
                                DataColumn(label: Text('UPAH HARI INI')),
                                DataColumn(label: Text('JAM MASUK')),
                                DataColumn(label: Text('JAM KELUAR')),
                                DataColumn(label: Text('UBAH STATUS')),
                              ],
                              rows: employees.map((emp) {
                                final record = records.firstWhere(
                                  (r) => r.employeeId == emp.id,
                                  orElse: () => AttendanceRecord(
                                    employeeId: emp.id,
                                    day: Fmt.isoDay(_selectedDate),
                                    status: AttendanceStatus.present,
                                  ),
                                );
                                final isEarned = record.status.isPresent;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InitialsAvatar(initials: Fmt.initials(emp.name), size: 32),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(emp.name, style: AppText.bodyStrong),
                                              Text('${emp.id} · ${emp.department}', style: AppText.tiny),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        Fmt.rupiah(emp.effectiveDailyRate),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textStrong,
                                        ),
                                      ),
                                    ),
                                    DataCell(AttendanceStatusBadge(status: record.status)),
                                    DataCell(
                                      Text(
                                        isEarned ? Fmt.rupiah(emp.effectiveDailyRate) : 'Rp0',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isEarned ? AppColors.primary700 : AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(record.checkIn ?? '—', style: AppText.body)),
                                    DataCell(Text(record.checkOut ?? '—', style: AppText.body)),
                                    DataCell(
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<AttendanceStatus>(
                                          value: record.status,
                                          style: const TextStyle(fontSize: 12, color: AppColors.text2),
                                          items: AttendanceStatus.values.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s.label),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              widget.store.setAttendance(
                                                emp.id,
                                                _selectedDate,
                                                newStatus,
                                              );
                                            }
                                          },
                                        ),
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
}
