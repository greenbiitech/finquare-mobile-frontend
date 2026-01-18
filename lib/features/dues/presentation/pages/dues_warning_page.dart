import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

class DuesWarningPage extends StatelessWidget {
  const DuesWarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Header with back button
              Align(
                alignment: Alignment.centerLeft,
                child: const AppBackButton(),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Warning Icon
                    Image.asset(
                      'assets/images/dues_warning.png',
                      width: 166,
                      height: 166,
                    ),
                    const SizedBox(height: 51),

                    // Alert Title
                    Text(
                      'Alert',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Alert Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'You are about to create dues, which will be mandatory for all community members.\nIf you prefer a more customized approach for specific members, consider using the contribution feature.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF606060),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              DefaultButton(
                isButtonEnabled: true,
                onPressed: () => context.push(AppRoutes.createNewDues),
                title: 'I understand',
                buttonColor: Color(0xFF21A8FB),
                height: 54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 12),
              DefaultButton(
                isButtonEnabled: true,
                onPressed: () => Navigator.pop(context),
                title: 'Cancel',
                buttonColor: Color(0xFFF5F5F5),
                titleColor: Color(0xFF1A1A1A),
                height: 54,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
