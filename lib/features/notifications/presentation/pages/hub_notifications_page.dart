import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/notifications/data/notifications_repository.dart';
import 'package:finsquare_mobile_app/features/notifications/presentation/providers/notifications_provider.dart';

// Colors matching hub page
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _mainTextColor = Color(0xFF333333);
const Color _esusuBgColor = Color(0xFFEBDAFB);
const Color _esusuTextColor = Color(0xFF8B20E9);
const Color _duesBgColor = Color(0xFFD1FAFF);
const Color _duesTextColor = Color(0xFF21A8FB);
const Color _contributionsBgColor = Color(0xFFF9DEE9);
const Color _contributionsTextColor = Color(0xFFF83180);
const Color _groupBuyBgColor = Color(0xFFF8E4CE);
const Color _groupBuyTextColor = Color(0xFFFC9D37);

/// Hub notifications page - shows all activity notifications
class HubNotificationsPage extends ConsumerStatefulWidget {
  final String communityId;

  const HubNotificationsPage({super.key, required this.communityId});

  @override
  ConsumerState<HubNotificationsPage> createState() => _HubNotificationsPageState();
}

class _HubNotificationsPageState extends ConsumerState<HubNotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsPageProvider.notifier).fetchNotifications(widget.communityId);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsPageProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsPageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Activity',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _mainTextColor,
                      ),
                    ),
                  ),
                  // Mark all as read button
                  if (state.notifications.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        await ref.read(notificationsPageProvider.notifier).markAllAsRead();
                        // Also refresh hub activity
                        ref.read(hubActivityProvider.notifier).refresh();
                      },
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: state.isLoading
                  ? _buildShimmer()
                  : state.notifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => ref.read(notificationsPageProvider.notifier).refresh(),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == state.notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final notification = state.notifications[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildNotificationItem(notification),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see activity notifications here',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(InAppNotification notification) {
    // Get feature-specific colors
    Color bgColor;
    Color textColor;
    String iconPath;

    switch (notification.feature) {
      case NotificationFeature.esusu:
        bgColor = _esusuBgColor;
        textColor = _esusuTextColor;
        iconPath = 'assets/svgs/hub/esusu.svg';
        break;
      case NotificationFeature.dues:
        bgColor = _duesBgColor;
        textColor = _duesTextColor;
        iconPath = 'assets/svgs/hub/dues.svg';
        break;
      case NotificationFeature.contributions:
        bgColor = _contributionsBgColor;
        textColor = _contributionsTextColor;
        iconPath = 'assets/svgs/hub/contributions.svg';
        break;
      case NotificationFeature.groupBuying:
        bgColor = _groupBuyBgColor;
        textColor = _groupBuyTextColor;
        iconPath = 'assets/svgs/hub/group_buying.svg';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _greyBackground,
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                    color: _mainTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(notification.createdAt),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                // View button
                GestureDetector(
                  onTap: () => _handleNotificationTap(notification),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle notification tap - navigate based on notification type
  void _handleNotificationTap(InAppNotification notification) async {
    // Mark as read
    await ref.read(notificationsPageProvider.notifier).markAsRead(notification.id);
    // Also update hub activity
    ref.read(hubActivityProvider.notifier).refresh();

    if (!mounted) return;

    // Navigate based on feature and type
    if (notification.feature == NotificationFeature.esusu) {
      final esusuId = notification.esusuId;
      final esusuName = notification.esusuName ?? 'Esusu';

      if (esusuId == null) return;

      // Determine where to navigate based on notification type
      switch (notification.type) {
        case 'esusu_invite':
        case 'esusu_reminder':
          // Pending invitation - go to invitation page
          context.push(
            '${AppRoutes.esusuInvitation}/$esusuId?name=${Uri.encodeComponent(esusuName)}',
          );
          break;
        case 'esusu_joined':
        case 'esusu_ready':
        case 'esusu_invite_accepted':
        case 'esusu_invite_declined':
          // Accepted/Ready - go to waiting room
          context.push(
            '${AppRoutes.esusuWaitingRoom}/$esusuId?name=${Uri.encodeComponent(esusuName)}',
          );
          break;
        case 'esusu_created':
        case 'esusu_cancelled':
        case 'esusu_invitation_expired':
          // General - go to Esusu list
          context.push(AppRoutes.esusuList);
          break;
        default:
          // Default - go to Esusu detail or list
          context.push(
            '${AppRoutes.esusuDetail}/$esusuId?name=${Uri.encodeComponent(esusuName)}',
          );
      }
    }
    // TODO: Add navigation for other features (dues, contributions, group buying)
  }
}
