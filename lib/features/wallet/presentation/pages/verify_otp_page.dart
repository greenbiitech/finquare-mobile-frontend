import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Verify OTP Page (Verify Credentials Screen)
///
/// Fourth step in wallet setup flow (or upgrade flow).
/// User enters the 6-digit OTP sent to their email/phone.
/// On verification, BVN details are retrieved and passed to next screen.
///
/// For Tier 1: Navigates to PIN creation
/// For Tier 2 Upgrade: Navigates to next upgrade step (PERSONAL_INFO)
class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.sessionId,
    required this.method,
    this.isUpgrade = false,
  });

  final String sessionId;
  final String method; // 'phone' or 'email'
  final bool isUpgrade; // True for Tier 2 upgrade flow

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isResending = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool get _isEmail => widget.method.toLowerCase() == 'email';

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (_hasError) {
        setState(() => _hasError = false);
      } else {
        setState(() {});
      }
    });
    _startResendTimer();

    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinFocusNode.dispose();
    _shakeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  bool get _isValidOtp => _otpController.text.trim().length == 6;

  void _showError(String message) {
    showErrorSnackbar(message);
  }

  void _showSuccess(String message) {
    showSuccessSnackbar(message);
  }

  Future<void> _handleOtpError(String message) async {
    // Set error state
    setState(() => _hasError = true);

    // Vibrate
    HapticFeedback.heavyImpact();

    // Shake animation
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });

    // Show error message
    _showError(message);

    // Wait a moment then clear the input
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _otpController.clear();
      _pinFocusNode.requestFocus();
    }
  }

  Future<void> _onVerify() async {
    if (!_isValidOtp || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      if (widget.isUpgrade) {
        // Tier 2 Upgrade flow: Use upgrade-specific endpoint
        final response = await walletRepo.verifyUpgradeBvnOtp(
          sessionId: widget.sessionId,
          otp: _otpController.text.trim(),
        );

        if (!mounted) return;

        if (response.success) {
          // Navigate to next upgrade step (PERSONAL_INFO) with BVN data
          final nextStep = response.nextStep ?? 'PERSONAL_INFO';
          _navigateToUpgradeStep(nextStep, bvnData: {
            'firstName': response.bvnData.firstName,
            'lastName': response.bvnData.lastName,
            'middleName': response.bvnData.middleName,
            'phoneNumber': response.bvnData.phoneNumber,
            'dateOfBirth': response.bvnData.dateOfBirth,
            'gender': response.bvnData.gender,
          });
        } else {
          setState(() => _isLoading = false);
          await _handleOtpError(response.message);
          return;
        }
      } else {
        // Tier 1 flow: Use standard endpoint
        final response = await walletRepo.verifyBvnOtp(
          sessionId: widget.sessionId,
          otp: _otpController.text.trim(),
        );

        if (!mounted) return;

        if (response.success) {
          // Tier 1 flow: BVN verified - go directly to PIN creation
          context.push(
            AppRoutes.createTransactionPin,
            extra: {
              'verificationType': 'BVN',
              'verificationData': {
                'firstName': response.bvnData.firstName,
                'lastName': response.bvnData.lastName,
                'middleName': response.bvnData.middleName,
                'phoneNumber': response.bvnData.phoneNumber,
                'dateOfBirth': response.bvnData.dateOfBirth,
                'gender': response.bvnData.gender,
              },
            },
          );
        } else {
          setState(() => _isLoading = false);
          await _handleOtpError(response.message);
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _handleOtpError('Invalid OTP. Please try again.');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigate to the appropriate upgrade step
  void _navigateToUpgradeStep(String step, {Map<String, dynamic>? bvnData}) {
    switch (step) {
      case 'PERSONAL_INFO':
        context.push(
          AppRoutes.upgradePersonalInfo,
          extra: {'bvnData': bvnData},
        );
        break;
      case 'ID_DOCUMENT':
        context.push(AppRoutes.upgradeIdDocument);
        break;
      case 'FACE_VERIFICATION':
        context.push(AppRoutes.upgradeFace);
        break;
      case 'ADDRESS':
        context.push(AppRoutes.upgradeAddress);
        break;
      case 'SUBMITTED':
        context.go(AppRoutes.upgradePending);
        break;
      default:
        context.push(
          AppRoutes.upgradePersonalInfo,
          extra: {'bvnData': bvnData},
        );
    }
  }

  Future<void> _onResend() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Use upgrade-specific endpoint if in upgrade mode
      if (widget.isUpgrade) {
        final response = await walletRepo.verifyUpgradeBvnMethod(
          sessionId: widget.sessionId,
          method: widget.method,
        );

        if (!mounted) return;

        if (response.success) {
          _showSuccess('Verification code resent successfully');
          _startResendTimer();
        } else {
          _showError(response.message);
        }
      } else {
        final response = await walletRepo.verifyBvnMethod(
          sessionId: widget.sessionId,
          method: widget.method,
        );

        if (!mounted) return;

        if (response.success) {
          _showSuccess('Verification code resent successfully');
          _startResendTimer();
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to resend code. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 54,
      textStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _mainTextColor,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1.5),
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
              const SizedBox(height: 60),
              const AppBackButton(),
              const SizedBox(height: 20),
              SvgPicture.asset('assets/svgs/pagination_dots.svg'),
              const SizedBox(height: 15),
              Text(
                'Verify your Credentials',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Enter the verification code sent to your ${_isEmail ? 'email address' : 'phone number'}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF606060),
                ),
              ),
              const SizedBox(height: 30),
              // PIN input using Pinput - centered with shake animation
              Center(
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    focusNode: _pinFocusNode,
                    defaultPinTheme: _hasError ? errorPinTheme : defaultPinTheme,
                    focusedPinTheme: _hasError ? errorPinTheme : defaultPinTheme,
                    submittedPinTheme: _hasError ? errorPinTheme : defaultPinTheme,
                    errorPinTheme: errorPinTheme,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    onCompleted: (pin) {
                      if (!_isLoading) {
                        _onVerify();
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
              // Resend code section
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    if (_isResending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_canResend)
                      TextButton(
                        onPressed: _onResend,
                        child: Text(
                          'Resend Code',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Resend code in $_resendSeconds seconds',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF606060),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isValidOtp && !_isLoading)
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: (_isValidOtp && !_isLoading) ? _onVerify : null,
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Verify',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isValidOtp ? Colors.white : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
