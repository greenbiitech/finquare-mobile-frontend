import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

class ResetPasswordSuccessPage extends StatelessWidget {
  const ResetPasswordSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(height: 150),
              SvgPicture.asset('assets/svgs/sucessful.svg'),
              SizedBox(height: 20),
              Text(
                'Success',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You have successfully reset your password, great to have you back',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: () {
              context.go(AppRoutes.login);
            },
            child: Text(
              'Login',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
