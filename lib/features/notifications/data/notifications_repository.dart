import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';

/// Notification feature enum matching backend
enum NotificationFeature {
  esusu,
  dues,
  contributions,
  groupBuying;

  static NotificationFeature fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ESUSU':
        return NotificationFeature.esusu;
      case 'DUES':
        return NotificationFeature.dues;
      case 'CONTRIBUTIONS':
        return NotificationFeature.contributions;
      case 'GROUP_BUYING':
        return NotificationFeature.groupBuying;
      default:
        return NotificationFeature.esusu;
    }
  }
}

/// In-app notification model
class InAppNotification {
  final String id;
  final NotificationFeature feature;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  InAppNotification({
    required this.id,
    required this.feature,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      feature: NotificationFeature.fromString(json['feature'] as String),
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Get esusuId from data if available
  String? get esusuId => data?['esusuId'] as String?;

  /// Get esusuName from data if available
  String? get esusuName => data?['esusuName'] as String?;

  /// Get contributionId from data if available
  String? get contributionId => data?['contributionId'] as String?;

  /// Get contributionName from data if available
  String? get contributionName => data?['contributionName'] as String?;
}

/// Pagination info
class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Notifications list response
class NotificationsResponse {
  final List<InAppNotification> notifications;
  final NotificationPagination pagination;

  NotificationsResponse({
    required this.notifications,
    required this.pagination,
  });
}

/// Notifications repository
class NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepository(this._apiClient);

  /// Get in-app notifications with optional community filter
  Future<NotificationsResponse> getNotifications({
    String? communityId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (communityId != null) {
      queryParams['communityId'] = communityId;
    }

    print('[NotificationsRepo] Fetching notifications with params: $queryParams');

    final response = await _apiClient.get(
      '/notifications/in-app',
      queryParameters: queryParams,
    );

    print('[NotificationsRepo] Response received');

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final notificationsList = (data['notifications'] as List)
        .map((n) => InAppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
    final pagination = NotificationPagination.fromJson(
        data['pagination'] as Map<String, dynamic>);

    print('[NotificationsRepo] Parsed ${notificationsList.length} notifications');

    return NotificationsResponse(
      notifications: notificationsList,
      pagination: pagination,
    );
  }

  /// Get unread notification count
  Future<int> getUnreadCount({String? communityId}) async {
    final queryParams = <String, String>{};
    if (communityId != null) {
      queryParams['communityId'] = communityId;
    }

    final response = await _apiClient.get(
      '/notifications/in-app/unread-count',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final responseData = response.data as Map<String, dynamic>;
    return responseData['data']['unreadCount'] as int;
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.patch('/notifications/in-app/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? communityId}) async {
    final queryParams = <String, String>{};
    if (communityId != null) {
      queryParams['communityId'] = communityId;
    }

    await _apiClient.patch(
      '/notifications/in-app/read-all',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }
}

/// Provider for notifications repository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRepository(apiClient);
});
