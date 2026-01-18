import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/community/presentation/widgets/community_selection_modal.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);

/// Options Page - Static UI matching old Greencard design (ProfileScreen) exactly
/// Logic to be added later
class OptionsPage extends ConsumerStatefulWidget {
  const OptionsPage({super.key});

  @override
  ConsumerState<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends ConsumerState<OptionsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch communities when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityProvider.notifier).fetchAllCommunityData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final communityName = communityState.activeCommunity?.name ?? 'FinSquare Community';

    // Check if user has created any communities (is admin of at least one)
    // This determines whether to show the Manage Community cards or the "Create Community" prompt
    final bool hasCreatedCommunity = communityState.userCommunitiesCreated.isNotEmpty;
    final int communitiesCreatedCount = communityState.userCommunitiesCreated.length;

    // Get member count from active community (minimum 1 since admin is always a member)
    final int memberCount = (communityState.activeCommunity?.members.length ?? 0) > 0
        ? communityState.activeCommunity!.members.length
        : 1;

    // Get user role in active community
    final String userRole = _getRoleDisplayText(communityState.userRoleInActiveCommunity);

    const double sectionGap = 20.0;
    const double itemGap = 30.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Configure',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              // Community Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            communityName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _mainTextColor,
                            ),
                          ),
                          Text(
                            userRole,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showCommunitySelectionModal(communityState),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Switch',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _mainTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Conditional: Show cards if user has created a community, else show prompt
              if (hasCreatedCommunity) ...[
                // Community Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildCommunityCard(
                        svgPath: 'assets/svgs/settingstwo.svg',
                        title: 'Manage Community',
                        subtitle: 'Settings & Configuration',
                        onTap: () {
                          final communityId = communityState.activeCommunity?.id;
                          if (communityId != null) {
                            context.push('${AppRoutes.manageCommunity}/$communityId');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCommunityCard(
                        svgPath: 'assets/svgs/communityicon.svg',
                        title: 'Members',
                        subtitle: '$memberCount member${memberCount != 1 ? 's' : ''}',
                        onTap: () {
                          final communityId = communityState.activeCommunity?.id;
                          if (communityId != null) {
                            context.push('${AppRoutes.communityMembersList}/$communityId');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are managing $communitiesCreatedCount ${communitiesCreatedCount > 1 ? 'Communities' : 'Community'}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.blue.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Show "Create Community" prompt SVG
                GestureDetector(
                  onTap: () {
                    // Navigate to create community flow
                    context.push(AppRoutes.onboardCommunity);
                  },
                  child: SvgPicture.asset('assets/svgs/community_card.svg'),
                ),
              ],
              const SizedBox(height: sectionGap),

              // Wallet Section
              Text(
                'Wallet',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildListTile(
                    svgPath: 'assets/svgs/account.svg',
                    title: 'Upgrade',
                    onTap: () {
                      // TODO: Navigate to upgrade
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/card.svg',
                    title: 'Cards',
                    onTap: () {
                      // TODO: Navigate to cards
                    },
                  ),
                ],
              ),
              const SizedBox(height: sectionGap),

              // Profile and Security Section
              Text(
                'Profile and Security',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: itemGap),
              Column(
                children: [
                  _buildListTile(
                    svgPath: 'assets/svgs/account.svg',
                    title: 'Account',
                    onTap: () {
                      // TODO: Navigate to account
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/changepassword.svg',
                    title: 'Change Password',
                    onTap: () {
                      // TODO: Navigate to change password
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/settings.svg',
                    title: 'App Settings',
                    onTap: () {
                      // TODO: Navigate to app settings
                    },
                  ),
                ],
              ),
              const SizedBox(height: sectionGap),

              // Orders Section
              Text(
                'Orders',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: itemGap),
              Column(
                children: [
                  _buildListTile(
                    svgPath: 'assets/svgs/account.svg',
                    title: 'My Orders',
                    onTap: () {
                      // TODO: Navigate to my orders
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/account.svg',
                    title: 'My Group Buys',
                    onTap: () {
                      // TODO: Navigate to my group buys
                    },
                  ),
                ],
              ),
              const SizedBox(height: sectionGap),

              // Others Section
              Text(
                'Others',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: itemGap),
              Column(
                children: [
                  _buildListTile(
                    svgPath: 'assets/svgs/faqs.svg',
                    title: 'Help/FAQ',
                    onTap: () {
                      // TODO: Navigate to help/FAQ
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/support.svg',
                    title: 'Contact Support',
                    onTap: () {
                      // TODO: Navigate to contact support
                    },
                  ),
                  const SizedBox(height: itemGap),
                  _buildListTile(
                    svgPath: 'assets/svgs/logout.svg',
                    title: 'Logout',
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Community card widget - matching old design with SVG icons
  Widget _buildCommunityCard({
    required String svgPath,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _greyBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(svgPath),
              const SizedBox(height: 15),
              FittedBox(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (subtitle != null) const SizedBox(height: 4),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// List tile widget - matching old design with SVG icons
  Widget _buildListTile({
    required String svgPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(svgPath),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Icon(
            Icons.play_arrow_rounded,
            color: AppColors.primary,
            size: 15,
          ),
        ],
      ),
    );
  }

  /// Helper method to get role display text
  String _getRoleDisplayText(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'CO_ADMIN':
        return 'Co-Admin';
      case 'MEMBER':
        return 'Member';
      default:
        return 'Member';
    }
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: _greyTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Logout and navigate to login
                ref.read(authProvider.notifier).logout();
                context.go(AppRoutes.login);
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show community selection modal
  void _showCommunitySelectionModal(CommunityState communityState) {
    // Filter communities for switching - exclude FinSquare Community if user has other communities
    final allCommunities = communityState.myCommunities;
    final filteredCommunities = _filterCommunitiesForSwitching(allCommunities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunitySelectionModal(
        userCommunities: filteredCommunities,
        currentCommunityId: communityState.activeCommunity?.id,
        onCommunitySelected: (selectedCommunity) async {
          // Close the modal
          Navigator.pop(context);

          // Don't switch if already on the selected community
          if (selectedCommunity.id == communityState.activeCommunity?.id) {
            return;
          }

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Switching to ${selectedCommunity.name}...',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          try {
            // Switch active community via API call
            final success = await ref
                .read(communityProvider.notifier)
                .switchActiveCommunity(selectedCommunity.id);

            // Close loading dialog
            if (mounted) Navigator.pop(context);

            if (success) {
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${selectedCommunity.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to switch community'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            // Close loading dialog
            if (mounted) Navigator.pop(context);

            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to switch community: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCreateNewCommunity: () {
          // Close the modal
          Navigator.pop(context);
          // Navigate to create community flow
          context.push(AppRoutes.onboardCommunity);
        },
      ),
    );
  }

  /// Filter communities for switching - exclude FinSquare Community if user has other communities
  List<UserCommunity> _filterCommunitiesForSwitching(
      List<UserCommunity> communities) {
    // Check if user has any non-FinSquare communities
    final hasOtherCommunities =
        communities.any((c) => !c.isDefault);

    if (hasOtherCommunities) {
      // Filter out FinSquare Community if user has other communities
      return communities.where((c) => !c.isDefault).toList();
    }

    // If user only has FinSquare Community, return all communities
    return communities;
  }
}
