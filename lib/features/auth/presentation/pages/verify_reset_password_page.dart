import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';

class VerifyResetPasswordPage extends StatefulWidget {
  const VerifyResetPasswordPage({super.key});

  @override
  State<VerifyResetPasswordPage> createState() => _VerifyResetPasswordPageState();
}

class _VerifyResetPasswordPageState extends State<VerifyResetPasswordPage> {
  final TextEditingController _pinController = TextEditingController();
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _pinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleResendCode() {
    if (_canResend) {
      // TODO: Call resend OTP API
      _startResendTimer();
    }
  }

  bool get _canVerify => _pinController.text.length == 6;

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 22,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

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
                'Verify your Account 🔐',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please enter the verification code sent to your email address',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: Pinput(
                  controller: _pinController,
                  length: 6,
                  obscureText: true,
                  obscuringCharacter: '•',
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: defaultPinTheme,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  onCompleted: (pin) {
                    // Auto verify on complete if desired
                  },
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: Text(
                  "Can't access your email?\nVerify phone number",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 150),
              Center(
                child: Text(
                  "Didn't get a code?",
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _handleResendCode,
                  child: Text(
                    _canResend
                        ? 'Resend Code'
                        : 'Resend Code ${_resendCountdown.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _canResend ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _canVerify ? AppColors.primary : AppColors.surfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(43),
                    ),
                  ),
                  onPressed: _canVerify
                      ? () {
                          context.push(AppRoutes.enterNewPassword);
                        }
                      : null,
                  child: Text(
                    'Verify',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canVerify
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
