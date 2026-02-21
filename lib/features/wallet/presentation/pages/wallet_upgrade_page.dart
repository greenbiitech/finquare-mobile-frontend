import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors
const Color _mainTextColor = Color(0xFF333333);
const Color _subtitleColor = Color(0xFF606060);

/// Wallet Upgrade Page
///
/// Entry point for upgrading wallet from Tier 1 to Tier 2 or Tier 3.
/// Shows current tier status, upgrade benefits, and starts the upgrade flow.
class WalletUpgradePage extends ConsumerStatefulWidget {
  const WalletUpgradePage({super.key});

  @override
  ConsumerState<WalletUpgradePage> createState() => _WalletUpgradePageState();
}

class _WalletUpgradePageState extends ConsumerState<WalletUpgradePage> {
  bool _isLoading = true;
  UpgradeStatusResponse? _status;
  String? _selectedTier;
  bool _isStartingUpgrade = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final status = await walletRepo.getUpgradeStatus();

      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorSnackbar('Failed to load upgrade status');
      }
    }
  }

  Future<void> _startUpgrade() async {
    if (_selectedTier == null || _isStartingUpgrade) return;

    setState(() => _isStartingUpgrade = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.startUpgrade(_selectedTier!);

      if (!mounted) return;

      if (response.success) {
        // Navigate to the first step of upgrade
        final currentStep = response.data?['currentStep'] ?? 'MISSING_IDENTITY';
        _navigateToStep(currentStep);
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to start upgrade');
    } finally {
      if (mounted) {
        setState(() => _isStartingUpgrade = false);
      }
    }
  }

  void _continueUpgrade() {
    if (_status?.currentStep != null) {
      _navigateToStep(_status!.currentStep!);
    }
  }

  void _navigateToStep(String step) {
    switch (step) {
      case 'MISSING_IDENTITY':
        context.push(AppRoutes.upgradeIdentity);
        break;
      case 'PERSONAL_INFO':
        context.push(AppRoutes.upgradePersonalInfo);
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
      case 'UTILITY_BILL':
        context.push(AppRoutes.upgradeUtilityBill);
        break;
      case 'SIGNATURE':
        context.push(AppRoutes.upgradeSignature);
        break;
      case 'SUBMITTED':
        context.push(AppRoutes.upgradePending);
        break;
      default:
        context.push(AppRoutes.upgradePersonalInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == null) {
      return const Center(child: Text('Failed to load status'));
    }

    // If upgrade is pending approval
    if (_status!.isPendingApproval) {
      return _buildPendingApprovalView();
    }

    // If upgrade is in progress
    if (_status!.isUpgradeInProgress) {
      return _buildInProgressView();
    }

    // Show upgrade options
    return _buildUpgradeOptionsView();
  }

  Widget _buildPendingApprovalView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackButton(),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top,
                    size: 50,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Upgrade Pending',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your upgrade request is being reviewed. We\'ll notify you once it\'s approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInProgressView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackButton(),
          const SizedBox(height: 30),
          Text(
            'Continue Your Upgrade',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _mainTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have an upgrade in progress. Continue where you left off.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _subtitleColor,
            ),
          ),
          const SizedBox(height: 30),
          _buildProgressIndicator(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _continueUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              child: Text(
                'Continue Upgrade',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: () async {
                final walletRepo = ref.read(walletRepositoryProvider);
                await walletRepo.cancelUpgrade();
                _loadStatus();
              },
              child: Text(
                'Cancel Upgrade',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Identity', 'Personal Info', 'ID Document', 'Face', 'Address'];
    final currentStepIndex = _getStepIndex(_status?.currentStep);

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStepIndex;
        final isCurrent = index == currentStepIndex;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary
                    : (isCurrent ? AppColors.primary.withAlpha(50) : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? AppColors.primary : Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                steps[index],
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? _mainTextColor : _subtitleColor,
                ),
              ),
            ),
          ],
        );
      }).expand((widget) => [widget, const SizedBox(height: 16)]).toList()
        ..removeLast(),
    );
  }

  int _getStepIndex(String? step) {
    switch (step) {
      case 'MISSING_IDENTITY':
        return 0;
      case 'PERSONAL_INFO':
        return 1;
      case 'ID_DOCUMENT':
        return 2;
      case 'FACE_VERIFICATION':
        return 3;
      case 'ADDRESS':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildUpgradeOptionsView() {
    final canUpgradeToTier2 = _status?.canUpgradeToTier2 ?? false;
    final canUpgradeToTier3 = _status?.canUpgradeToTier3 ?? false;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackButton(),
          const SizedBox(height: 22),
          Text(
            'Upgrade Your Wallet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _mainTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get higher limits and more features',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _subtitleColor,
            ),
          ),
          const SizedBox(height: 24),

          // Current Tier
          _buildCurrentTierCard(),
          const SizedBox(height: 20),

          // Upgrade Options
          if (canUpgradeToTier2)
            _TierOptionCard(
              tier: 'TIER_2',
              title: 'Tier 2',
              balanceLimit: '500,000',
              dailyLimit: '200,000',
              requirements: 'BVN + NIN, ID Document, Face Verification',
              isSelected: _selectedTier == 'TIER_2',
              onTap: () => setState(() => _selectedTier = 'TIER_2'),
            ),

          if (canUpgradeToTier2) const SizedBox(height: 16),

          if (canUpgradeToTier3)
            _TierOptionCard(
              tier: 'TIER_3',
              title: 'Tier 3',
              balanceLimit: 'Unlimited',
              dailyLimit: '5,000,000',
              requirements: 'All Tier 2 requirements + Proof of Address',
              isSelected: _selectedTier == 'TIER_3',
              onTap: () => setState(() => _selectedTier = 'TIER_3'),
            ),

          if (!canUpgradeToTier2 && !canUpgradeToTier3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are already at the highest tier!',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          if (canUpgradeToTier2 || canUpgradeToTier3)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedTier != null && !_isStartingUpgrade
                    ? _startUpgrade
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTier != null
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(43),
                  ),
                ),
                child: _isStartingUpgrade
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Start Upgrade',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedTier != null
                              ? Colors.white
                              : AppColors.textDisabled,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCurrentTierCard() {
    final tier = _status?.currentTier ?? 'TIER_1';
    final tierNumber = tier.replaceAll('TIER_', '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                tierNumber,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: Tier $tierNumber',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
                Text(
                  tier == 'TIER_1'
                      ? 'Balance: ₦300k | Daily: ₦50k'
                      : tier == 'TIER_2'
                          ? 'Balance: ₦500k | Daily: ₦200k'
                          : 'Unlimited',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierOptionCard extends StatelessWidget {
  final String tier;
  final String title;
  final String balanceLimit;
  final String dailyLimit;
  final String requirements;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierOptionCard({
    required this.tier,
    required this.title,
    required this.balanceLimit,
    required this.dailyLimit,
    required this.requirements,
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
          color: isSelected ? Colors.white : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
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
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLimitChip('Balance', '₦$balanceLimit'),
                const SizedBox(width: 8),
                _buildLimitChip('Daily', '₦$dailyLimit'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requirements: $requirements',
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
    );
  }

  Widget _buildLimitChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _mainTextColor,
        ),
      ),
    );
  }
}
