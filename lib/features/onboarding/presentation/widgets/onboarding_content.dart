import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class OnboardingContent extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingContent({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Spacer(flex: 1),
          SizedBox(
            width: 300,
            child: Image.asset(
              image,
              fit: BoxFit.fitWidth,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
