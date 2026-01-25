import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

class EsusuListPage extends ConsumerStatefulWidget {
  const EsusuListPage({super.key});

  @override
  ConsumerState<EsusuListPage> createState() => _EsusuListPageState();
}

class _EsusuListPageState extends ConsumerState<EsusuListPage> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Archived
  bool _isLoading = true;
  String? _error;
  List<EsusuListItem> _activeEsusus = [];
  List<EsusuListItem> _archivedEsusus = [];
  bool _isAdmin = false;
  int _lastRefreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastRefreshTrigger = ref.read(esusuListRefreshTriggerProvider);
      _fetchEsusus();
    });
  }

  Future<void> _fetchEsusus() async {
    final communityState = ref.read(communityProvider);
    final communityId = communityState.activeCommunity?.id;

    if (communityId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No active community';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);

      // Fetch both active and archived in parallel
      final results = await Future.wait([
        repository.getEsusuList(communityId, archived: false),
        repository.getEsusuList(communityId, archived: true),
      ]);

      if (mounted) {
        setState(() {
          _activeEsusus = results[0].esusus;
          _archivedEsusus = results[1].esusus;
          _isAdmin = results[0].isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load Esusus';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for refresh trigger changes (from other screens like Invitation, Slot Selection)
    ref.listen<int>(esusuListRefreshTriggerProvider, (previous, next) {
      if (next != _lastRefreshTrigger) {
        _lastRefreshTrigger = next;
        _fetchEsusus();
      }
    });

    final currentList = _selectedTabIndex == 0 ? _activeEsusus : _archivedEsusus;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    'Esusu',
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
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _error != null
                      ? _buildErrorState()
                      : currentList.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchEsusus,
                              color: _esusuPrimaryColor,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                itemCount: currentList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildEsusuCard(currentList[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 18,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Status and Amount row shimmer
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 22,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 22,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Participants and Frequency row shimmer
                Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 22,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 22,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(13),
                        ),
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
          color: isSelected ? const Color(0xFFEBDAFB) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected ? Border.all(color: const Color(0xFF8B20E9), width: 1) : null,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _fetchEsusus,
            child: const Text('Retry'),
          ),
        ],
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
            'No ${_selectedTabIndex == 0 ? 'active' : 'archived'} Esusu',
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

  Widget _buildEsusuCard(EsusuListItem item) {
    return GestureDetector(
      onTap: () => _handleCardTap(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            _buildEsusuImage(item.iconUrl),
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

                  // Status and Amount row
                  Row(
                    children: [
                      _buildStatusChip(item),
                      const SizedBox(width: 8),
                      _buildChip(
                        '\u20A6${_formatAmount(item.contributionAmount)}/cycle',
                        _esusuLightColor,
                        _esusuPrimaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Participants and Frequency row
                  Row(
                    children: [
                      _buildChip(
                        '${item.numberOfParticipants} Participants',
                        _esusuLightColor,
                        _esusuPrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        item.frequency.displayName,
                        _esusuLightColor,
                        _esusuPrimaryColor,
                      ),
                    ],
                  ),

                  // Progress bar (only for active status)
                  if (item.status == EsusuStatus.active && item.daysUntilPayout != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: const Color(0xFFFFFFFF),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_esusuPrimaryColor),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.daysUntilPayout} days till payout',
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

                  // View Invitation CTA for members with pending invites
                  if (!_isAdmin &&
                      item.inviteStatus == EsusuInviteStatus.invited) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _esusuPrimaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'View Invitation',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  void _handleCardTap(EsusuListItem item) {
    // If member has pending invitation, show invitation view
    if (!_isAdmin && item.inviteStatus == EsusuInviteStatus.invited) {
      context.push(
        '${AppRoutes.esusuInvitation}/${item.id}?name=${Uri.encodeComponent(item.name)}',
      ).then((_) => _fetchEsusus()); // Refresh list on return
      return;
    }

    // If member has accepted and Esusu is pending/ready, show waiting room
    if (!_isAdmin &&
        item.inviteStatus == EsusuInviteStatus.accepted &&
        (item.status == EsusuStatus.pendingMembers ||
            item.status == EsusuStatus.readyToStart)) {
      context.push(
        '${AppRoutes.esusuWaitingRoom}/${item.id}?name=${Uri.encodeComponent(item.name)}',
      ).then((_) => _fetchEsusus()); // Refresh list on return
      return;
    }

    // Admin view for pending/ready Esusus
    if (_isAdmin &&
        (item.status == EsusuStatus.pendingMembers ||
            item.status == EsusuStatus.readyToStart)) {
      // Check if Admin is a participant and needs to select a slot (FCFS)
      final needsSlotSelection = item.isParticipant &&
          item.payoutOrderType == PayoutOrderType.firstComeFirstServed &&
          item.slotNumber == null;

      // Debug logging
      debugPrint('=== Admin Card Tap Debug ===');
      debugPrint('Esusu: ${item.name}');
      debugPrint('isParticipant: ${item.isParticipant}');
      debugPrint('payoutOrderType: ${item.payoutOrderType}');
      debugPrint('slotNumber: ${item.slotNumber}');
      debugPrint('needsSlotSelection: $needsSlotSelection');
      debugPrint('============================');

      if (needsSlotSelection) {
        // Admin needs to pick a slot first, then go to Admin Waiting Room
        context.push(
          '${AppRoutes.esusuSlotSelection}/${item.id}?name=${Uri.encodeComponent(item.name)}&isAdmin=true',
        ).then((_) => _fetchEsusus());
      } else {
        // Admin goes directly to Admin Waiting Room (esusu_detail_page)
        context.push(
          '${AppRoutes.esusuDetail}/${item.id}?name=${Uri.encodeComponent(item.name)}',
        ).then((_) => _fetchEsusus());
      }
      return;
    }

    // Active esusu
    if (item.status == EsusuStatus.active) {
      // Navigate to active esusu detail page
      context.push(
        '${AppRoutes.activeEsusuDetail}/${item.id}?name=${Uri.encodeComponent(item.name)}',
      ).then((_) => _fetchEsusus()); // Refresh list on return
    }
  }

  Widget _buildEsusuImage(String? iconUrl) {
    final hasImage = iconUrl != null && iconUrl.isNotEmpty;

    if (!hasImage) {
      // Default icon when no image
      return Container(
        width: 98,
        height: 98,
        decoration: BoxDecoration(
          color: _esusuLightColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/svgs/hub/esusu.svg',
            width: 40,
            height: 40,
          ),
        ),
      );
    }

    // Cached network image with shimmer loading
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        width: 98,
        height: 98,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            color: _esusuLightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Shimmer.fromColors(
            baseColor: _esusuLightColor,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: _esusuLightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/hub/esusu.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    _esusuPrimaryColor.withValues(alpha: 0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 98,
          height: 98,
          decoration: BoxDecoration(
            color: _esusuLightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svgs/hub/esusu.svg',
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(EsusuListItem item) {
    Color bgColor;
    Color textColor;
    String text;

    // For members, show invite status if pending
    if (!_isAdmin && item.inviteStatus == EsusuInviteStatus.invited) {
      bgColor = const Color(0xFFFAEFBF);
      textColor = const Color(0xFF333333);
      text = 'Invited';
    } else {
      switch (item.status) {
        case EsusuStatus.active:
          bgColor = const Color(0xFFD0F5CE);
          textColor = const Color(0xFF333333);
          text = 'Active';
          break;
        case EsusuStatus.pendingMembers:
          bgColor = const Color(0xFFFAEFBF);
          textColor = const Color(0xFF333333);
          text = 'Pending Members';
          break;
        case EsusuStatus.readyToStart:
          bgColor = const Color(0xFFD1FAFF);
          textColor = const Color(0xFF333333);
          text = 'Ready to Start';
          break;
        case EsusuStatus.completed:
          bgColor = const Color(0xFFE0E0E0);
          textColor = const Color(0xFF606060);
          text = 'Completed';
          break;
        case EsusuStatus.cancelled:
          bgColor = const Color(0xFFFFE0E0);
          textColor = const Color(0xFF606060);
          text = 'Cancelled';
          break;
        case EsusuStatus.paused:
          bgColor = const Color(0xFFFAEFBF);
          textColor = const Color(0xFF606060);
          text = 'Paused';
          break;
      }
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
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bgColor, Color textColor) {
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

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)},000';
    }
    return amount.toStringAsFixed(0);
  }
}
