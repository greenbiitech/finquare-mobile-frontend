import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8F5E9);
const Color _communityBorderColor = Color(0xFFC54600);

// Finance item colors
const Color _esusuBgColor = Color(0xFFEBDAFB);
const Color _esusuTextColor = Color(0xFF8B20E9);
const Color _duesBgColor = Color(0xFFD1FAFF);
const Color _duesTextColor = Color(0xFF21A8FB);
const Color _contributionsBgColor = Color(0xFFF9DEE9);
const Color _contributionsTextColor = Color(0xFFF83180);
const Color _groupBuyBgColor = Color(0xFFF8E4CE);
const Color _groupBuyTextColor = Color(0xFFFC9D37);

/// Hub Page - Static UI matching old Greencard design
/// Logic to be added later
class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final communityName = communityState.activeCommunity?.name ?? 'FinSquare Community';
    // Member count - static for now, will be fetched from API later
    const int memberCount = 1;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'hub_fab',
        backgroundColor: AppColors.primary,
        onPressed: () {
          context.push(AppRoutes.createHub);
        },
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerEffect()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Community header with shadow underneath
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Shadow element positioned behind
                        Positioned(
                          top: 55,
                          left: 10,
                          right: 10,
                          child: Container(
                            width: 340,
                            height: 35,
                            decoration: BoxDecoration(
                              color: _communityBorderColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Community header on top
                        _buildCommunityHeader(communityName, memberCount),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCommunityFinanceSection(),
                    const SizedBox(height: 24),
                    _buildPersonalSavingsSection(),
                    const SizedBox(height: 24),
                    _buildActivitySection(),
                    const SizedBox(height: 100), // Space for FAB and bottom nav
                  ],
                ),
              ),
      ),
    );
  }

  /// Shimmer loading effect
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildShimmerCommunityHeader(),
            const SizedBox(height: 24),
            _buildShimmerSection(),
            const SizedBox(height: 24),
            _buildShimmerSection(),
            const SizedBox(height: 24),
            _buildShimmerActivitySection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCommunityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 18, color: Colors.white),
                const SizedBox(height: 8),
                Container(width: 80, height: 12, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 120, height: 12, color: Colors.white),
        const SizedBox(height: 16),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(4, (index) => Container(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildShimmerActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 60, height: 16, color: Colors.white),
        const SizedBox(height: 16),
        Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Community header widget - matching old design
  Widget _buildCommunityHeader(String communityName, int memberCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10).copyWith(left: 8, right: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _communityBorderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: _greyBackground,
      ),
      child: Row(
        children: [
          // Logo with colored stripes (gradient circle)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade400,
                  Colors.blue.shade400,
                  Colors.yellow.shade400,
                  Colors.brown.shade400,
                  Colors.lightBlue.shade400,
                  Colors.blue.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                communityName.isNotEmpty ? communityName.substring(0, 1).toUpperCase() : 'F',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                  communityName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Member avatars - Overlapping circles
                    SizedBox(
                      width: memberCount >= 3 ? 44 : (memberCount == 2 ? 32 : 20),
                      height: 21,
                      child: Stack(
                        children: List.generate(
                          memberCount >= 3 ? 3 : (memberCount > 0 ? memberCount : 1),
                          (index) => Positioned(
                            left: index * 12.0,
                            top: 0.5,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$memberCount member${memberCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: _mainTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, size: 30),
        ],
      ),
    );
  }

  /// Community finance section - matching old design
  Widget _buildCommunityFinanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Finance',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _mainTextColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to view all community finance
              },
              child: Text(
                'View All',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildFinanceItem('Esusu', 'assets/svgs/hub/esusu.svg', 0, _esusuBgColor, _esusuTextColor, onTap: () => context.push(AppRoutes.esusuList)),
            _buildFinanceItem('Dues', 'assets/svgs/hub/dues.svg', 0, _duesBgColor, _duesTextColor),
            _buildFinanceItem('Contributions', 'assets/svgs/hub/contributions.svg', 0, _contributionsBgColor, _contributionsTextColor),
            _buildFinanceItem('Group Buying', 'assets/svgs/hub/group_buying.svg', 0, _groupBuyBgColor, _groupBuyTextColor),
          ],
        ),
      ],
    );
  }

  /// Finance item widget - matching old design with SVG icons
  Widget _buildFinanceItem(
    String title,
    String svgPath,
    int count,
    Color bgColor,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _greyBackground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SvgPicture.asset(svgPath),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mainTextColor,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Personal savings section - matching old design
  Widget _buildPersonalSavingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Savings',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _mainTextColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to view all personal savings
              },
              child: Text(
                'View All',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSavingsItem('Target Savings', 'assets/svgs/hub/target_savings.svg', 0)),
            const SizedBox(width: 12),
            Expanded(child: _buildSavingsItem('Safelock', 'assets/svgs/hub/safelock.svg', 0)),
          ],
        ),
      ],
    );
  }

  /// Savings item widget - matching old design with SVG icons
  Widget _buildSavingsItem(String title, String svgPath, int count) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _greyBackground,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(svgPath),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _mainTextColor,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _veryLightPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Activity section - matching old design
  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: _mainTextColor,
          ),
        ),
        const SizedBox(height: 16),
        // Empty state
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _greyBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No activities yet',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activities will appear here when available',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
