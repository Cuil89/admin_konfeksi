import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderRadius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final card = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius as BorderRadius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.backgroundColor = AppColors.slate100,
    this.textColor = AppColors.text2,
  });

  final String initials;
  final double size;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
