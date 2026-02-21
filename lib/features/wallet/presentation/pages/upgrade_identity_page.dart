import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/custom_text_field.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Upgrade Identity Page
///
/// First step in wallet upgrade flow.
/// User provides the missing identity (BVN if they registered with NIN, or NIN if they registered with BVN).
///
/// For BVN: Full OTP verification flow (initiate -> select method -> verify OTP)
/// For NIN: Direct verification via Mono lookup (no OTP required)
class UpgradeIdentityPage extends ConsumerStatefulWidget {
  const UpgradeIdentityPage({super.key});

  @override
  ConsumerState<UpgradeIdentityPage> createState() => _UpgradeIdentityPageState();
}

class _UpgradeIdentityPageState extends ConsumerState<UpgradeIdentityPage> {
  final TextEditingController _identityController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _missingIdentityType; // 'BVN' or 'NIN'
  String? _existingIdentity; // What they already have

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _identityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final status = await walletRepo.getUpgradeStatus();

      if (mounted) {
        setState(() {
          // Determine what's missing based on upgrade status
          // If user has BVN, they need NIN. If user has NIN, they need BVN.
          _missingIdentityType = status.missingIdentity ?? 'NIN';
          _existingIdentity = _missingIdentityType == 'BVN' ? 'NIN' : 'BVN';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorSnackbar('Failed to load status');
      }
    }
  }

  bool get _isValidIdentity {
    final value = _identityController.text.trim();
    // Both BVN and NIN are 11 digits
    return RegExp(r'^\d{11}$').hasMatch(value);
  }

  Future<void> _onSubmit() async {
    if (!_isValidIdentity || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      if (_missingIdentityType == 'BVN') {
        // BVN requires full OTP verification flow
        await _handleBvnVerification(walletRepo);
      } else {
        // NIN can be verified directly (no OTP required)
        await _handleNinVerification(walletRepo);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to submit identity. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Handle BVN verification - starts OTP flow
  Future<void> _handleBvnVerification(WalletRepository walletRepo) async {
    showInfoSnackbar('Initiating BVN verification...');

    final response = await walletRepo.initiateUpgradeBvn(_identityController.text.trim());

    if (!mounted) return;

    if (response.success) {
      // Navigate to Select Verification Method with upgrade mode
      context.push(
        AppRoutes.selectVerificationMethod,
        extra: {
          'sessionId': response.sessionId,
          'methods': response.methods,
          'isUpgrade': true, // Flag for upgrade mode
        },
      );
    } else {
      showErrorSnackbar(response.message);
    }
  }

  /// Handle NIN verification - direct lookup (no OTP)
  Future<void> _handleNinVerification(WalletRepository walletRepo) async {
    final response = await walletRepo.submitUpgradeIdentity(
      nin: _identityController.text.trim(),
    );

    if (!mounted) return;

    if (response.success) {
      // Navigate to next step
      final nextStep = response.data?['nextStep'] ?? 'PERSONAL_INFO';
      _navigateToStep(nextStep);
    } else {
      showErrorSnackbar(response.message);
    }
  }

  void _navigateToStep(String step) {
    switch (step) {
      case 'PERSONAL_INFO':
        context.push(AppRoutes.upgradePersonalInfo);
        break;
      case 'ID_DOCUMENT':
        context.push(AppRoutes.upgradeIdDocument);
        break;
      default:
        context.push(AppRoutes.upgradePersonalInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canSubmit = _isValidIdentity && !_isSubmitting;
    final identityLabel = _missingIdentityType == 'BVN'
        ? 'Bank Verification Number (BVN)'
        : 'National Identification Number (NIN)';
    final identityHint = '11 digits';
    final helpText = _missingIdentityType == 'BVN'
        ? 'Dial *565*0# to retrieve your BVN'
        : 'Check your NIMC slip or dial *346# to retrieve your NIN';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                const AppBackButton(),
                const SizedBox(height: 22),
                // Progress indicator
                _buildProgressIndicator(1, 5),
                const SizedBox(height: 20),
                Text(
                  'Provide Your $_missingIdentityType',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You registered with your $_existingIdentity. To upgrade your wallet, we need your $_missingIdentityType.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _identityController,
                  hintText: identityHint,
                  labelText: identityLabel,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    return RegExp(r'^\d{11}$').hasMatch(value)
                        ? null
                        : 'Please enter exactly 11 digits';
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: _subtitleColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        helpText,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: _subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_missingIdentityType == 'BVN') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'BVN verification requires OTP confirmation for your security.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              backgroundColor: canSubmit ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: canSubmit ? _onSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canSubmit ? Colors.white : AppColors.textDisabled,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isCompleted = index < current - 1;
        final isCurrent = index == current - 1;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
