import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final IconData? icon;
  final Color? iconColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double titleFontSize;
  final double? minHeight;

  const MenuCard({
    super.key,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.backgroundColor = const Color(0xFF142234),
    this.borderColor = const Color(0xFF1F3A56),
    this.titleColor = const Color(0xFF4FC3F7),
    this.subtitleColor = const Color(0xFF9FB3C8),
    this.icon,
    this.iconColor,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    this.titleFontSize = 18,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? titleColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          constraints: minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveIconColor, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
