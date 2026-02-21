import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Verify BVN Credentials Page
///
/// Third step in wallet setup flow (or upgrade flow).
/// User enters their full email or phone number to verify ownership.
/// When they click Continue, API is called to send OTP to that method.
class VerifyBvnCredentialsPage extends ConsumerStatefulWidget {
  const VerifyBvnCredentialsPage({
    super.key,
    required this.sessionId,
    required this.method,
    this.isUpgrade = false,
  });

  final String sessionId;
  final String method; // 'phone', 'email', or 'alternate_phone'
  final bool isUpgrade; // True for Tier 2 upgrade flow

  @override
  ConsumerState<VerifyBvnCredentialsPage> createState() =>
      _VerifyBvnCredentialsPageState();
}

class _VerifyBvnCredentialsPageState
    extends ConsumerState<VerifyBvnCredentialsPage> {
  final TextEditingController _credentialController = TextEditingController();
  bool _isLoading = false;

  bool get _isEmail => widget.method.toLowerCase() == 'email';
  bool get _isAlternatePhone => widget.method.toLowerCase() == 'alternate_phone';
  bool get _isPhone => widget.method.toLowerCase() == 'phone' || _isAlternatePhone;

  @override
  void initState() {
    super.initState();
    _credentialController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final value = _credentialController.text.trim();
    if (_isEmail) {
      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    } else {
      // Phone number validation for both 'phone' and 'alternate_phone'
      // Accepts: 0XXXXXXXXXX (11 digits) or 234XXXXXXXXXX (13 digits)
      return RegExp(r'^(0[789]\d{9}|234[789]\d{9})$').hasMatch(value);
    }
  }

  void _showError(String message) {
    showErrorSnackbar(message);
  }

  Future<void> _onContinue() async {
    if (!_isValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Use upgrade-specific endpoint if in upgrade mode
      if (widget.isUpgrade) {
        final response = await walletRepo.verifyUpgradeBvnMethod(
          sessionId: widget.sessionId,
          method: widget.method,
          phoneNumber: _isAlternatePhone ? _credentialController.text.trim() : null,
        );

        if (!mounted) return;

        if (response.success) {
          context.push(
            AppRoutes.verifyOtp,
            extra: {
              'sessionId': widget.sessionId,
              'method': widget.method,
              'isUpgrade': true,
            },
          );
        } else {
          _showError(response.message);
        }
      } else {
        final response = await walletRepo.verifyBvnMethod(
          sessionId: widget.sessionId,
          method: widget.method,
          phoneNumber: _isAlternatePhone ? _credentialController.text.trim() : null,
        );

        if (!mounted) return;

        if (response.success) {
          context.push(
            AppRoutes.verifyOtp,
            extra: {
              'sessionId': widget.sessionId,
              'method': widget.method,
              'isUpgrade': false,
            },
          );
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send verification code. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _pageTitle {
    if (_isEmail) {
      return 'Verify your Email';
    } else if (_isAlternatePhone) {
      return 'Enter Alternate Phone Number';
    } else {
      return 'Verify your Phone Number';
    }
  }

  String get _pageDescription {
    if (_isEmail) {
      return 'Please enter your complete email address linked to your BVN to receive a verification code.';
    } else if (_isAlternatePhone) {
      return 'Please enter your alternate phone number to receive a verification code.';
    } else {
      return 'Please enter your complete phone number linked to your BVN to receive a verification code.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _isValid && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const AppBackButton(),
                const SizedBox(height: 22),
                SvgPicture.asset('assets/svgs/pagination_dots.svg'),
                const SizedBox(height: 15),
                Text(
                  _pageTitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _pageDescription,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF606060),
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _credentialController,
                  hintText: _isEmail ? 'Enter Email' : 'Enter Phone Number',
                  labelText: _isEmail ? 'Email' : 'Phone Number',
                  keyboardType: _isEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    if (_isEmail) {
                      return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)
                          ? null
                          : 'Please enter a valid email address';
                    } else {
                      return RegExp(r'^(0[789]\d{9}|234[789]\d{9})$').hasMatch(value)
                          ? null
                          : 'Please enter a valid phone number (e.g., 08012345678 or 2348012345678)';
                    }
                  },
                ),
              ],
            ),
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
              backgroundColor:
                  canContinue ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: canContinue ? _onContinue : null,
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
                    'Continue',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canContinue ? Colors.white : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
