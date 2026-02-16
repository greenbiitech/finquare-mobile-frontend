import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/providers/contribution_creation_provider.dart';

// Contributions primary colors
const Color _contributionsPrimaryColor = Color(0xFFF83181);
const Color _contributionsAccentColor = Color(0xFFF9DEE9);
const Color _mainTextColor = Color(0xFF333333);

class ContributionsWelcomePage extends ConsumerStatefulWidget {
  const ContributionsWelcomePage({super.key});

  @override
  ConsumerState<ContributionsWelcomePage> createState() =>
      _ContributionsWelcomePageState();
}

class _ContributionsWelcomePageState
    extends ConsumerState<ContributionsWelcomePage> {
  bool _isCheckingEligibility = false;
  ContributionEligibilityResponse? _eligibility;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEligibility();
    });
  }

  Future<void> _checkEligibility() async {
    final communityState = ref.read(communityProvider);
    final activeCommunity = communityState.activeCommunity;

    if (activeCommunity == null) {
      setState(() {
        _errorMessage = 'No active community';
      });
      return;
    }

    setState(() {
      _isCheckingEligibility = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(contributionsRepositoryProvider);
      final response = await repository.checkEligibility(activeCommunity.id);

      setState(() {
        _isCheckingEligibility = false;
        _eligibility = response;
      });

      // Set community context in the creation provider
      if (response.canCreateContribution) {
        ref.read(contributionCreationProvider.notifier).setCommunityContext(
              communityId: activeCommunity.id,
              communityName: activeCommunity.name,
              memberCount: activeCommunity.memberCount,
            );
      }
    } catch (e) {
      setState(() {
        _isCheckingEligibility = false;
        _errorMessage = 'Failed to check eligibility';
      });
    }
  }

  void _handleCreateContribution() {
    if (_eligibility == null || !_eligibility!.canCreateContribution) {
      _showIneligibilityMessage();
      return;
    }

    // Reset the creation provider before starting
    ref.read(contributionCreationProvider.notifier).reset();

    // Re-set community context
    final communityState = ref.read(communityProvider);
    if (communityState.activeCommunity != null) {
      ref.read(contributionCreationProvider.notifier).setCommunityContext(
            communityId: communityState.activeCommunity!.id,
            communityName: communityState.activeCommunity!.name,
            memberCount: communityState.activeCommunity!.memberCount,
          );
    }

    context.push(AppRoutes.createContribution);
  }

  void _showIneligibilityMessage() {
    if (_eligibility == null && _errorMessage == null) return;

    String title;
    String message;
    String? ctaText;
    VoidCallback? ctaAction;

    if (_errorMessage != null) {
      title = 'Error';
      message = _errorMessage!;
    } else {
      switch (_eligibility!.reason) {
        case ContributionIneligibilityReason.notAdmin:
          title = 'Admin Required';
          message = 'Only community admins can create a Contribution. '
              'Contact your community admin to create one.';
          break;
        case ContributionIneligibilityReason.noCommunityWallet:
          title = 'Community Wallet Required';
          message = 'Please set up your community wallet first to create a Contribution.';
          ctaText = 'Setup Wallet';
          ctaAction = () {
            Navigator.pop(context);
            final communityId =
                ref.read(communityProvider).activeCommunity?.id ?? '';
            context.push('${AppRoutes.communityWalletSetup}/$communityId');
          };
          break;
        default:
          title = 'Cannot Create Contribution';
          message = _eligibility!.message ?? 'You are not eligible to create a Contribution.';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _contributionsAccentColor,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.info_outline,
                color: _contributionsPrimaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF606060),
              ),
            ),
            const SizedBox(height: 24),
            if (ctaText != null && ctaAction != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: ctaAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _contributionsPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(43),
                    ),
                  ),
                  child: Text(
                    ctaText,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (ctaText != null) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  ctaText != null ? 'Close' : 'Got it',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _contributionsPrimaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        _eligibility?.canCreateContribution == true && !_isCheckingEligibility;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 20),
                    Text(
                      'Contributions',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 50),
                SvgPicture.asset("assets/svgs/contributions_welcome_screen.svg"),
                // const SizedBox(height: 80),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contributions',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF020014),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _contributionHomeWidget(
                  icon: 'assets/svgs/contributions/Frame 2609038.svg',
                  title: 'Group Contributions',
                  description: "Track your group's contributions easily.",
                ),
                const SizedBox(height: 20),
                _contributionHomeWidget(
                  icon: 'assets/svgs/contributions/Frame 2609038 (1).svg',
                  title: 'Fast Contributions',
                  description: 'Contribute easily at the Group Fund.',
                ),
                const SizedBox(height: 20),
                _contributionHomeWidget(
                  icon: 'assets/svgs/contributions/Frame 2609038 (2).svg',
                  title: 'Simple and Secure',
                  description:
                      'Your contributions are safe and easy to manage.',
                ),
                const Spacer(),
                const SizedBox(height: 20),
                if (_isCheckingEligibility)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _contributionsPrimaryColor,
                      ),
                    ),
                  ),
                DefaultButton(
                  isButtonEnabled: !_isCheckingEligibility,
                  onPressed: _handleCreateContribution,
                  title: 'Get Started',
                  buttonColor:
                      canCreate ? _contributionsPrimaryColor : Colors.grey.shade400,
                  height: 54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contributionHomeWidget({
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        SvgPicture.asset(icon),
        const SizedBox(width: 10),
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
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF606060),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
