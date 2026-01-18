import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class DotIndicator extends StatelessWidget {
  final bool isActive;

  const DotIndicator({
    super.key,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: isActive ? 38 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primaryLight,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
