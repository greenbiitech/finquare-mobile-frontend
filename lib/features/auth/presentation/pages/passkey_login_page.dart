import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/app_startup_service.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/join_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class PasskeyLoginPage extends ConsumerStatefulWidget {
  const PasskeyLoginPage({super.key});

  @override
  ConsumerState<PasskeyLoginPage> createState() => _PasskeyLoginPageState();
}

class _PasskeyLoginPageState extends ConsumerState<PasskeyLoginPage> {
  String _pin = '';

  String? get _userName {
    final startupService = ref.read(appStartupServiceProvider);
    return startupService.savedUserName;
  }

  String? get _userEmail {
    final startupService = ref.read(appStartupServiceProvider);
    return startupService.savedUserEmail;
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 5) {
      setState(() {
        _pin += number;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _onSubmitPressed() async {
    if (_pin.length < 5) {
      showWarningSnackbar('Please enter your 5-digit passkey');
      return;
    }

    final email = _userEmail;
    print('Passkey login - email: $email');
    if (email == null || email.isEmpty) {
      showErrorSnackbar('User email not found. Please login again.');
      context.go(AppRoutes.login);
      return;
    }

    ref.showLoading('Signing in...');

    final success = await ref.read(authProvider.notifier).loginWithPasskey(
          email: email,
          passkey: _pin,
        );

    ref.hideLoading();

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (!user.hasPickedMembership) {
          context.go(AppRoutes.pickMembership);
        } else {
          // Check for pending invite token
          final pendingToken = await _checkPendingInvite();
          if (pendingToken != null && mounted) {
            context.go('${AppRoutes.joinCommunity}/$pendingToken');
          } else if (mounted) {
            context.go(AppRoutes.home);
          }
        }
      }
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Invalid passkey');
      setState(() {
        _pin = '';
      });
    }
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

  void _logout() {
    // Clear saved user info and go to login
    ref.read(appStartupServiceProvider).clearUserInfo();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _userName?.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Text(
              'Welcome back, 👋',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              firstName,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please confirm your PIN to access your account.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 190,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _pin.length > index
                            ? AppColors.primary
                            : const Color(0xFFE8E8E8),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Spacer(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                String? buttonText;
                Icon? buttonIcon;
                VoidCallback? onPressed;

                if (index < 9) {
                  buttonText = (index + 1).toString();
                  onPressed = () => _onNumberPressed(buttonText!);
                } else if (index == 9) {
                  buttonIcon =
                      const Icon(Icons.backspace_outlined, color: Colors.black);
                  onPressed = _onBackspacePressed;
                } else if (index == 10) {
                  buttonText = '0';
                  onPressed = () => _onNumberPressed(buttonText!);
                } else {
                  buttonIcon = Icon(
                    Icons.check,
                    color: _pin.length == 5
                        ? Colors.white
                        : const Color(0xFFBBBBBB),
                  );
                  onPressed = _onSubmitPressed;
                }

                return _buildKeypadButton(
                  text: buttonText,
                  icon: buttonIcon,
                  onPressed: onPressed,
                  isSubmit: index == 11,
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _logout,
                child: Text(
                  'Log out',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    Icon? icon,
    VoidCallback? onPressed,
    bool isSubmit = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: isSubmit && _pin.length == 5
              ? AppColors.primary
              : const Color(0xFFF3F3F3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}
