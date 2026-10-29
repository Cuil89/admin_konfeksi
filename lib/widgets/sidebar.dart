import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import 'app_card.dart';

enum AppTab {
  summary('Ringkasan', AppIcons.summary),
  employees('Karyawan', AppIcons.employees),
  attendance('Kehadiran', AppIcons.attendance),
  payroll('Penggajian', AppIcons.payroll),
  reimbursement('Reimbursement', AppIcons.reimbursement),
  reports('Laporan', AppIcons.reports),
  settings('Pengaturan', AppIcons.settings),
  help('Pusat bantuan', AppIcons.help);

  const AppTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.companyName,
    this.onLogout,
    this.onHelpClick,
    this.isDrawer = false,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelectTab;
  final String companyName;
  final VoidCallback? onLogout;
  final VoidCallback? onHelpClick;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      AppIcons.payroll,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'payrole',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text(
                    ' .',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Workspace Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'N',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textStrong,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Perusahaan',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      AppIcons.chevronsUpDown,
                      size: 16,
                      color: AppColors.textSubtle,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu Groups Scrollable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _groupTitle('RUANG KERJA'),
                  _navItem(AppTab.summary),
                  _navItem(AppTab.employees),
                  _navItem(AppTab.attendance),
                  _navItem(AppTab.payroll),
                  _navItem(AppTab.reimbursement),
                  _navItem(AppTab.reports),
                  const SizedBox(height: 16),
                  _groupTitle('PREFERENSI'),
                  _navItem(AppTab.settings),
                  _navItem(AppTab.help),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Footer Sidebar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Help Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // emerald-50/70
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.emerald100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                AppIcons.support,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Butuh bantuan payroll?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textStrong,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tim kami siap membantu penggajian Anda.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onHelpClick ?? () => onSelectTab(AppTab.help),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hubungi kami',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary700,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                AppIcons.externalLink,
                                size: 13,
                                color: AppColors.primary700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderStrong),
                  const SizedBox(height: 8),

                  // User Profile Bar
                  // User Profile Bar (Role: Pemilik)
                  Row(
                    children: [
                      const InitialsAvatar(
                        initials: 'PM',
                        size: 34,
                        backgroundColor: Color(0xFFFEF3C7),
                        textColor: Color(0xFF92400E),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'H. Suryanto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textStrong,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pemilik',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB45309),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.logout, size: 18),
                        color: AppColors.textSubtle,
                        tooltip: 'Kunci Sesi / Keluar',
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSubtle,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _navItem(AppTab tab) {
    final isSelected = currentTab == tab;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent, // emerald-50
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelectTab(tab),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
