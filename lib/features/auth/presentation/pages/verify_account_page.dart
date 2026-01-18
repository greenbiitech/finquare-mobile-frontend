import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/widgets/code_resend_widget.dart';

class VerifyAccountPage extends ConsumerStatefulWidget {
  const VerifyAccountPage({super.key});

  @override
  ConsumerState<VerifyAccountPage> createState() => _VerifyAccountPageState();
}

class _VerifyAccountPageState extends ConsumerState<VerifyAccountPage> {
  String pin = '';
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (pin.length != 6) return;

    ref.showLoading('Verifying your account...');

    final success = await ref.read(authProvider.notifier).verifyOtp(pin);

    ref.hideLoading();

    if (success && mounted) {
      showSuccessSnackbar('Account verified successfully!');
      context.push(AppRoutes.createPasskey);
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Verification failed');
      _pinController.clear();
      setState(() {
        pin = '';
      });
    }
  }

  Future<void> _handleResend() async {
    ref.showLoading('Sending new code...');

    final success = await ref.read(authProvider.notifier).resendOtp();

    ref.hideLoading();

    if (success) {
      showSuccessSnackbar('A new code has been sent');
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Failed to resend code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final email = authState.tempEmail ?? 'your email';

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 54,
      textStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF020014),
      ),
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              AppBackButton(),
              SizedBox(height: 20),
              Text(
                'Verify your Account',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'We sent a code to $email',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF606060),
                ),
              ),
              SizedBox(height: 80),
              Center(
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme,
                  separatorBuilder: (index) => SizedBox(width: 8),
                  onChanged: (value) {
                    setState(() {
                      pin = value;
                    });
                  },
                  onCompleted: (value) {
                    _handleVerify();
                  },
                ),
              ),
              Spacer(),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    CodeResendWidget(
                      onResend: _handleResend,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25),
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
              backgroundColor: pin.length == 6 ? AppColors.primary : AppColors.buttonInactive,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: pin.length == 6 ? _handleVerify : null,
            child: Text(
              'Verify',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
