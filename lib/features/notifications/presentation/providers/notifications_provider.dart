import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/features/notifications/data/notifications_repository.dart';

/// State for hub activity notifications (limited to latest 3)
class HubActivityState {
  final List<InAppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  HubActivityState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  HubActivityState copyWith({
    List<InAppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return HubActivityState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier for hub activity
class HubActivityNotifier extends StateNotifier<HubActivityState> {
  final NotificationsRepository _repository;
  String? _communityId;

  HubActivityNotifier(this._repository) : super(HubActivityState());

  /// Fetch latest notifications for hub activity section
  Future<void> fetchNotifications(String communityId) async {
    print('[HubActivity] Fetching notifications for community: $communityId');
    _communityId = communityId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch latest 3 notifications for hub display
      final response = await _repository.getNotifications(
        communityId: communityId,
        page: 1,
        limit: 3,
      );

      print('[HubActivity] Got ${response.notifications.length} notifications');

      final unreadCount = await _repository.getUnreadCount(communityId: communityId);

      print('[HubActivity] Unread count: $unreadCount');

      state = state.copyWith(
        notifications: response.notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      print('[HubActivity] Error fetching notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    if (_communityId != null) {
      await fetchNotifications(_communityId!);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return InAppNotification(
            id: n.id,
            feature: n.feature,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      // Silently fail - notification will be marked as read on next fetch
    }
  }
}

/// Provider for hub activity state
final hubActivityProvider =
    StateNotifierProvider<HubActivityNotifier, HubActivityState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return HubActivityNotifier(repository);
});

/// State for full notifications page (with pagination)
class NotificationsPageState {
  final List<InAppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  NotificationsPageState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  NotificationsPageState copyWith({
    List<InAppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool clearError = false,
  }) {
    return NotificationsPageState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier for notifications page
class NotificationsPageNotifier extends StateNotifier<NotificationsPageState> {
  final NotificationsRepository _repository;
  String? _communityId;

  NotificationsPageNotifier(this._repository) : super(NotificationsPageState());

  /// Fetch initial notifications
  Future<void> fetchNotifications(String communityId) async {
    _communityId = communityId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _repository.getNotifications(
        communityId: communityId,
        page: 1,
        limit: 20,
      );

      state = state.copyWith(
        notifications: response.notifications,
        currentPage: 1,
        totalPages: response.pagination.totalPages,
        hasMore: response.pagination.page < response.pagination.totalPages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more notifications
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _communityId == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getNotifications(
        communityId: _communityId,
        page: nextPage,
        limit: 20,
      );

      state = state.copyWith(
        notifications: [...state.notifications, ...response.notifications],
        currentPage: nextPage,
        totalPages: response.pagination.totalPages,
        hasMore: nextPage < response.pagination.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    if (_communityId != null) {
      await fetchNotifications(_communityId!);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return InAppNotification(
            id: n.id,
            feature: n.feature,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    if (_communityId == null) return;

    try {
      await _repository.markAllAsRead(communityId: _communityId);
      // Update local state - mark all as read
      final updatedNotifications = state.notifications.map((n) {
        return InAppNotification(
          id: n.id,
          feature: n.feature,
          type: n.type,
          title: n.title,
          message: n.message,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      // Silently fail
    }
  }
}

/// Provider for notifications page state
final notificationsPageProvider =
    StateNotifierProvider<NotificationsPageNotifier, NotificationsPageState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return NotificationsPageNotifier(repository);
});
