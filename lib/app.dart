import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/constants/app_constants.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/deep_link_service.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class FinSquareApp extends ConsumerStatefulWidget {
  const FinSquareApp({super.key});

  @override
  ConsumerState<FinSquareApp> createState() => _FinSquareAppState();
}

class _FinSquareAppState extends ConsumerState<FinSquareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Initialize OverlayLoader with ref for non-widget contexts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OverlayLoader.init(ref);
      _setupDeepLinkListener();
      _setupWalletRefreshTriggers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh wallet balance when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _refreshWalletOnResume();
    }
  }

  /// Refresh wallet balance silently when app resumes
  void _refreshWalletOnResume() {
    final authState = ref.read(authProvider);
    final hasWallet = authState.user?.hasWallet ?? false;

    if (hasWallet) {
      // Silent refresh - no loading indicator
      ref.read(walletProvider.notifier).refreshBalanceSilently();
    }
  }

  /// Set up FCM listeners to refresh wallet on wallet credit notifications
  void _setupWalletRefreshTriggers() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleWalletNotification);
    // Listen for background message tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleWalletNotification);
  }

  /// Handle wallet-related notifications
  void _handleWalletNotification(RemoteMessage message) {
    final data = message.data;
    final notificationType = data['type'] ?? data['notificationType'];

    // Check if this is a wallet credit notification
    if (notificationType == 'WALLET_CREDIT' ||
        notificationType == 'wallet_credit' ||
        notificationType == 'INFLOW' ||
        notificationType == 'inflow') {
      // Refresh wallet balance
      final authState = ref.read(authProvider);
      final hasWallet = authState.user?.hasWallet ?? false;

      if (hasWallet) {
        ref.read(walletProvider.notifier).refreshBalance();
      }
    }
  }

  void _setupDeepLinkListener() {
    final deepLinkService = ref.read(deepLinkServiceProvider);

    // Listen for invite links
    deepLinkService.inviteLinkStream.listen((inviteLink) {
      if (inviteLink != null && mounted) {
        final router = ref.read(appRouterProvider);
        router.push('${AppRoutes.joinCommunity}/${inviteLink.token}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return OverlaySupport.global(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
        builder: (context, child) {
          return OverlayLoaderWrapper(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
