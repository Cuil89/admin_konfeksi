import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.dotColor,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color? dotColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class PayrollStatusBadge extends StatelessWidget {
  const PayrollStatusBadge({super.key, required this.status});
  final PayrollStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PayrollStatus.paid:
        return const StatusBadge(
          label: 'Sudah dibayar',
          backgroundColor: AppColors.emerald50,
          textColor: Color(0xFF047857), // text-emerald-700
          dotColor: AppColors.success,
        );
      case PayrollStatus.ready:
        return const StatusBadge(
          label: 'Siap dibayar',
          backgroundColor: AppColors.slate100,
          textColor: Color(0xFF334155), // text-slate-700
          dotColor: AppColors.textSubtle,
        );
      case PayrollStatus.review:
        return const StatusBadge(
          label: 'Perlu ditinjau',
          backgroundColor: AppColors.amber50,
          textColor: Color(0xFFB45309), // text-amber-700
          dotColor: Color(0xFFD97706),
        );
    }
  }
}

class LoanStatusBadge extends StatelessWidget {
  const LoanStatusBadge({super.key, required this.isPaidOff});
  final bool isPaidOff;

  @override
  Widget build(BuildContext context) {
    if (isPaidOff) {
      return const StatusBadge(
        label: 'Lunas',
        backgroundColor: AppColors.emerald50,
        textColor: Color(0xFF047857),
        dotColor: AppColors.success,
      );
    } else {
      return const StatusBadge(
        label: 'Belum lunas',
        backgroundColor: AppColors.amber50,
        textColor: Color(0xFFB45309),
        dotColor: Color(0xFFD97706),
      );
    }
  }
}

class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({super.key, required this.status});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AttendanceStatus.present:
        return const StatusBadge(
          label: 'Hadir',
          backgroundColor: AppColors.emerald50,
          textColor: Color(0xFF047857),
          dotColor: AppColors.success,
        );
      case AttendanceStatus.late:
        return const StatusBadge(
          label: 'Terlambat',
          backgroundColor: AppColors.amber50,
          textColor: Color(0xFFB45309),
          dotColor: Color(0xFFD97706),
        );
      case AttendanceStatus.leave:
        return const StatusBadge(
          label: 'Izin',
          backgroundColor: AppColors.sky50,
          textColor: AppColors.sky700,
        );
      case AttendanceStatus.sick:
        return const StatusBadge(
          label: 'Sakit',
          backgroundColor: AppColors.indigo50,
          textColor: AppColors.indigo700,
        );
      case AttendanceStatus.vacation:
        return const StatusBadge(
          label: 'Cuti',
          backgroundColor: AppColors.slate100,
          textColor: AppColors.text2,
        );
      case AttendanceStatus.absent:
        return const StatusBadge(
          label: 'Tanpa ket.',
          backgroundColor: AppColors.rose50,
          textColor: AppColors.rose700,
        );
    }
  }
}

class ReimbursementStatusBadge extends StatelessWidget {
  const ReimbursementStatusBadge({super.key, required this.status});
  final ReimbursementStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ReimbursementStatus.approved:
        return const StatusBadge(
          label: 'Disetujui',
          backgroundColor: AppColors.emerald50,
          textColor: Color(0xFF047857),
          dotColor: AppColors.success,
        );
      case ReimbursementStatus.pending:
        return const StatusBadge(
          label: 'Menunggu',
          backgroundColor: AppColors.amber50,
          textColor: Color(0xFFB45309),
          dotColor: Color(0xFFD97706),
        );
      case ReimbursementStatus.rejected:
        return const StatusBadge(
          label: 'Ditolak',
          backgroundColor: AppColors.rose50,
          textColor: AppColors.rose700,
        );
    }
  }
}
