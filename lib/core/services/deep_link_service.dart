import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_service.g.dart';

/// Deep link data representing a parsed invite link
class InviteDeepLink {
  final String token;

  const InviteDeepLink({required this.token});

  @override
  String toString() => 'InviteDeepLink(token: $token)';
}

/// Deep Link Service for handling app links
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final StreamController<InviteDeepLink?> _inviteLinkController =
      StreamController<InviteDeepLink?>.broadcast();

  /// Stream of invite deep links
  Stream<InviteDeepLink?> get inviteLinkStream => _inviteLinkController.stream;

  /// Initialize and start listening for deep links
  Future<void> initialize() async {
    // Handle link when app is started from a link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }

    // Handle links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  /// Parse and handle incoming URI
  void _handleUri(Uri uri) {
    final inviteLink = _parseInviteLink(uri);
    if (inviteLink != null) {
      _inviteLinkController.add(inviteLink);
    }
  }

  /// Parse invite link from URI
  /// Supports:
  /// - finsquare://invite/{token}
  /// - https://finsquare-invite.netlify.app/invite/{token}
  InviteDeepLink? _parseInviteLink(Uri uri) {
    // Check for custom scheme: finsquare://invite/{token}
    if (uri.scheme == 'finsquare') {
      if (uri.host == 'invite' && uri.pathSegments.isNotEmpty) {
        return InviteDeepLink(token: uri.pathSegments.first);
      }
      // Also handle: finsquare://invite?token={token}
      if (uri.host == 'invite' && uri.queryParameters.containsKey('token')) {
        return InviteDeepLink(token: uri.queryParameters['token']!);
      }
    }

    // Check for HTTPS: https://finsquare-invite.netlify.app/invite/{token}
    if (uri.scheme == 'https' && uri.host == 'finsquare-invite.netlify.app') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'invite') {
        return InviteDeepLink(token: uri.pathSegments[1]);
      }
      // Also handle query param: https://finsquare-invite.netlify.app/invite?token={token}
      if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first == 'invite' &&
          uri.queryParameters.containsKey('token')) {
        return InviteDeepLink(token: uri.queryParameters['token']!);
      }
    }

    return null;
  }

  /// Generate a shareable invite link
  static String generateInviteLink(String token) {
    // Using the Netlify hosted invite page
    return 'https://finsquare-invite.netlify.app/invite/$token';
  }

  /// Generate a custom scheme invite link (for direct app opening)
  static String generateAppInviteLink(String token) {
    return 'finsquare://invite/$token';
  }

  /// Clear the current invite link (after handling)
  void clearCurrentInvite() {
    _inviteLinkController.add(null);
  }

  /// Dispose of resources
  void dispose() {
    _inviteLinkController.close();
  }
}

/// Provider for DeepLinkService
@Riverpod(keepAlive: true)
DeepLinkService deepLinkService(Ref ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider for the current pending invite link
@riverpod
class PendingInviteLink extends _$PendingInviteLink {
  StreamSubscription<InviteDeepLink?>? _subscription;

  @override
  InviteDeepLink? build() {
    final service = ref.watch(deepLinkServiceProvider);

    _subscription = service.inviteLinkStream.listen((inviteLink) {
      state = inviteLink;
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return null;
  }

  /// Clear the pending invite
  void clear() {
    state = null;
  }
}
