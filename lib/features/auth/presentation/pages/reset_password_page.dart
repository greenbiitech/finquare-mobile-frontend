import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showPhone = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_showPhone) {
      return _phoneController.text.trim().isNotEmpty;
    } else {
      return _emailController.text.trim().isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              AppBackButton(),
              SizedBox(height: 20),
              Text(
                'Reset your Password 😊',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _showPhone
                    ? 'Enter the phone number you registered with'
                    : 'Enter the email you registered with',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 40),
              if (_showPhone)
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'e.g 0812345689',
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                )
              else
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPhone = !_showPhone;
                  });
                },
                child: Text(
                  _showPhone ? 'Use Email' : 'Use Phone Number',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 250),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canContinue ? AppColors.primary : AppColors.surfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(43),
                    ),
                  ),
                  onPressed: _canContinue
                      ? () {
                          context.push(AppRoutes.verifyResetPassword);
                        }
                      : null,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canContinue
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
