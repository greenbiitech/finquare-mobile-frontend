import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
        ),
        child: Icon(
          Icons.arrow_back_outlined,
          size: 20,
        ),
      ),
    );
  }
}
