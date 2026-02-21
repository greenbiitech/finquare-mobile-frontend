import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);
const Color _cardBgColor = Color(0xFFF5F6F8);
const Color _selectedBorderColor = Color(0xFF2C2C2C);

/// Select Verification Type Page
///
/// Entry point for Tier 1 wallet activation.
/// User chooses between BVN or NIN for identity verification.
class SelectVerificationTypePage extends ConsumerStatefulWidget {
  const SelectVerificationTypePage({super.key});

  @override
  ConsumerState<SelectVerificationTypePage> createState() =>
      _SelectVerificationTypePageState();
}

class _SelectVerificationTypePageState
    extends ConsumerState<SelectVerificationTypePage> {
  String? _selectedType; // 'BVN' or 'NIN'

  void _onContinue() {
    if (_selectedType == 'BVN') {
      context.push(AppRoutes.bvnValidation);
    } else if (_selectedType == 'NIN') {
      context.push(AppRoutes.ninValidation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedType != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const AppBackButton(),
              const SizedBox(height: 22),
              SvgPicture.asset('assets/svgs/pagination_dots.svg'),
              const SizedBox(height: 15),
              Text(
                'Verify Your Identity',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Choose how you want to verify your identity to create your wallet',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _subtitleColor,
                ),
              ),
              const SizedBox(height: 30),

              // BVN Option
              _VerificationOptionCard(
                title: 'Bank Verification Number (BVN)',
                description:
                    'Verify using your BVN. You\'ll receive an OTP to confirm.',
                icon: Icons.account_balance_outlined,
                isSelected: _selectedType == 'BVN',
                onTap: () => setState(() => _selectedType = 'BVN'),
              ),

              const SizedBox(height: 16),

              // NIN Option
              _VerificationOptionCard(
                title: 'National Identification Number (NIN)',
                description:
                    'Verify using your NIN. Quick verification - no OTP needed.',
                icon: Icons.badge_outlined,
                isSelected: _selectedType == 'NIN',
                onTap: () => setState(() => _selectedType = 'NIN'),
              ),

              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This creates a Tier 1 wallet with a ₦300,000 balance limit. You can upgrade later for higher limits.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
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
              backgroundColor:
                  canContinue ? AppColors.primary : AppColors.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: canContinue ? _onContinue : null,
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    canContinue ? AppColors.textOnPrimary : AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card widget for verification type selection
class _VerificationOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VerificationOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : _cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _selectedBorderColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : _subtitleColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected ? true : null,
              onChanged: (_) => onTap(),
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return const Color(0xFF49454F);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
