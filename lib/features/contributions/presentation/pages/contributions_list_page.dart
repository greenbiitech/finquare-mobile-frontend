import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);

/// Provider for fetching contribution list
final contributionListProvider = FutureProvider.autoDispose
    .family<ContributionListResponse, ({String communityId, bool archived})>(
        (ref, params) async {
  // Watch the refresh trigger to refetch when it changes
  ref.watch(contributionListRefreshTriggerProvider);

  final repository = ref.watch(contributionsRepositoryProvider);
  return repository.getContributionList(params.communityId,
      archived: params.archived);
});

class ContributionsListPage extends ConsumerStatefulWidget {
  const ContributionsListPage({super.key});

  @override
  ConsumerState<ContributionsListPage> createState() =>
      _ContributionsListPageState();
}

class _ContributionsListPageState extends ConsumerState<ContributionsListPage> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Archived

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final communityId = communityState.activeCommunity?.id ?? '';

    final isArchived = _selectedTabIndex == 1;
    final listAsync = ref.watch(
      contributionListProvider((communityId: communityId, archived: isArchived)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.contributionsWelcome);
        },
        backgroundColor: _contributionPrimary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
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
            ),
            const SizedBox(height: 20),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTab('Active', 0),
                  const SizedBox(width: 12),
                  _buildTab('Archived', 1),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: listAsync.when(
                loading: () => _buildShimmerLoader(),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load contributions',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          color: const Color(0xFF606060),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(contributionListProvider(
                            (communityId: communityId, archived: isArchived),
                          ));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (response) {
                  final contributions = response.contributions;

                  if (contributions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(contributionListProvider(
                        (communityId: communityId, archived: isArchived),
                      ));
                    },
                    color: _contributionPrimary,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: contributions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildContributionCard(contributions[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _contributionLight : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _contributionPrimary, width: 1)
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(isSelected ? 0xFF333333 : 0xFF8E8E8E),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedTabIndex == 0 ? 'active' : 'archived'} contributions',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF606060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(ContributionListItem item) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.contributionDetail}/${item.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            _buildContributionImage(item.imageUrl),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Creator row
                  Row(
                    children: [
                      _buildCreatorAvatar(item.creatorName),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            Text(
                              item.isCreator ? 'You' : item.creatorName,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status and Type tag row
                  Row(
                    children: [
                      _buildStatusChip(item.status),
                      const SizedBox(width: 8),
                      _buildTypeChip(item),
                    ],
                  ),

                  // Progress bar (only for active)
                  if (item.status == ContributionStatus.active) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress / 100,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  _contributionPrimary),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.daysRemaining != null && item.daysRemaining! > 0
                              ? '${item.daysRemaining} days till Deadline'
                              : 'No deadline',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF606060),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionImage(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (!hasImage) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _contributionLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/svgs/hub/contributions.svg',
            width: 48,
            height: 48,
            colorFilter: const ColorFilter.mode(
              _contributionPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _contributionLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svgs/hub/contributions.svg',
              width: 48,
              height: 48,
              colorFilter: const ColorFilter.mode(
                _contributionPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorAvatar(String name) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ContributionStatus status) {
    Color bgColor;
    String text;

    switch (status) {
      case ContributionStatus.active:
        bgColor = const Color(0xFFD0F5CE);
        text = 'Active';
        break;
      case ContributionStatus.completed:
        bgColor = const Color(0xFFE0E0E0);
        text = 'Completed';
        break;
      case ContributionStatus.cancelled:
        bgColor = const Color(0xFFFFE0E0);
        text = 'Cancelled';
        break;
      case ContributionStatus.pendingInvites:
        bgColor = const Color(0xFFFAEFBF);
        text = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ContributionListItem item) {
    String text;
    switch (item.type) {
      case ContributionType.fixed:
        text = item.amount != null
            ? '₦${_formatAmount(item.amount!)} person'
            : 'Fixed amount';
        break;
      case ContributionType.target:
        text = item.amount != null
            ? '₦${_formatAmount(item.amount!)} target'
            : 'Target amount';
        break;
      case ContributionType.flexible:
        text = 'Flexible payments';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _contributionLight,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  width: 150,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Creator row
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status chips
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
