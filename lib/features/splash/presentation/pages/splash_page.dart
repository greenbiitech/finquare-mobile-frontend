import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/app_startup_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/join_community_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  /// Check for pending invite token and clear it
  Future<String?> _checkPendingInvite() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: kPendingInviteTokenKey);
    if (token != null) {
      // Clear the pending token so it's not used again
      await storage.delete(key: kPendingInviteTokenKey);
    }
    return token;
  }

  Future<void> _navigateToNextScreen() async {
    // Small delay to show splash
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final startupService = ref.read(appStartupServiceProvider);
    final startupData = await startupService.determineInitialState();

    if (!mounted) return;

    switch (startupData.state) {
      case AppStartupState.showOnboarding:
        context.go(AppRoutes.onboarding);
        break;
      case AppStartupState.showLogin:
        context.go(AppRoutes.login);
        break;
      case AppStartupState.showPasskeyLogin:
        context.go(AppRoutes.passkeyLogin);
        break;
      case AppStartupState.showCreatePasskey:
        context.go(AppRoutes.createPasskey);
        break;
      case AppStartupState.showPickMembership:
        context.go(AppRoutes.pickMembership);
        break;
      case AppStartupState.showHome:
        // Check for pending invite token
        final pendingToken = await _checkPendingInvite();
        if (pendingToken != null && mounted) {
          context.go('${AppRoutes.joinCommunity}/$pendingToken');
        } else if (mounted) {
          context.go(AppRoutes.home);
        }
        break;
      case AppStartupState.loading:
        // Should not happen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or name
            Text(
              'FinSquare',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
