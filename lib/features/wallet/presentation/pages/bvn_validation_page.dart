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

/// BVN Validation Page
///
/// First step in wallet setup flow.
/// User enters their 11-digit Bank Verification Number (BVN).
/// After validation, proceeds to Select Verification Method.
class BvnValidationPage extends ConsumerStatefulWidget {
  const BvnValidationPage({super.key});

  @override
  ConsumerState<BvnValidationPage> createState() => _BvnValidationPageState();
}

class _BvnValidationPageState extends ConsumerState<BvnValidationPage> {
  final TextEditingController _bvnController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bvnController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bvnController.dispose();
    super.dispose();
  }

  // BVN regex validation (exactly 11 digits)
  bool get _isValidBvn {
    final bvn = _bvnController.text.trim();
    return RegExp(r'^\d{11}$').hasMatch(bvn);
  }

  void _showError(String message) {
    showErrorSnackbar(message);
  }

  Future<void> _onContinue() async {
    if (!_isValidBvn) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.initiateBvn(_bvnController.text.trim());

      if (!mounted) return;

      if (response.success) {
        // Navigate to Select Verification Method with session data
        context.push(
          AppRoutes.selectVerificationMethod,
          extra: {
            'sessionId': response.sessionId,
            'methods': response.methods,
          },
        );
      } else {
        _showError(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to validate BVN. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _isValidBvn && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  'BVN Validation',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'We need to validate your BVN or NIN to generate your wallet',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF606060),
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _bvnController,
                  hintText: '11 digits',
                  labelText: 'Bank Verification Number (BVN)',
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    return RegExp(r'^\d{11}$').hasMatch(value)
                        ? null
                        : 'Please enter a valid BVN with exactly 11 digits';
                  },
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'You can dial *565*0# to Retrieve your BVN',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: const Color(0xFF606060),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canContinue
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
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
                      color: canContinue
                          ? AppColors.textOnPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
