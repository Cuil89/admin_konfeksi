import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import 'sidebar.dart';

class Topbar extends StatelessWidget {
  const Topbar({
    super.key,
    required this.currentTab,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.isMobile = false,
  });

  final AppTab currentTab;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Mobile Menu Button
          if (isMobile) ...[
            IconButton(
              icon: const Icon(AppIcons.menu, size: 20),
              color: AppColors.text2,
              onPressed: onMenuPressed,
              tooltip: 'Buka menu',
            ),
            const SizedBox(width: 4),
          ],

          // Breadcrumb
          Expanded(
            child: Row(
              children: [
                if (!isMobile) ...[
                  const Text(
                    'Ruang kerja',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '>',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    currentTab.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Security Shield Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald200, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppIcons.shield,
                  size: 14,
                  color: AppColors.primary700,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'Data Terlindungi',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Role Badge: Pemilik
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // amber-100
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppIcons.shield,
                  size: 14,
                  color: Color(0xFF92400E), // amber-800
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 5),
                  const Text(
                    'Role: Pemilik',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Notification Bell
          IconButton(
            icon: const Icon(AppIcons.bell, size: 19),
            color: AppColors.text2,
            tooltip: 'Notifikasi',
            onPressed: onNotificationPressed,
          ),
        ],
      ),
    );
  }
}
