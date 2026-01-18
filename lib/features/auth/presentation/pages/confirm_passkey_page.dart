import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/pages/join_community_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class ConfirmPasskeyPage extends ConsumerStatefulWidget {
  const ConfirmPasskeyPage({super.key, required this.pin});

  final String pin;

  @override
  ConsumerState<ConfirmPasskeyPage> createState() => _ConfirmPasskeyPageState();
}

class _ConfirmPasskeyPageState extends ConsumerState<ConfirmPasskeyPage> {
  String _pin = '';

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

  Future<void> _onSubmitPressed() async {
    HapticFeedback.heavyImpact();

    if (_pin.length < 5) {
      showWarningSnackbar('Please enter a 5-digit PIN');
      return;
    }

    if (_pin != widget.pin) {
      showErrorSnackbar('PINs do not match. Please try again.');
      setState(() {
        _pin = '';
      });
      return;
    }

    // PINs match, create passkey on server
    ref.showLoading('Creating passkey...');

    final success = await ref.read(authProvider.notifier).createPasskey(_pin);

    ref.hideLoading();

    if (success && mounted) {
      showSuccessSnackbar('Passkey created successfully!');
      // Check for pending invite token
      final pendingToken = await _checkPendingInvite();
      if (pendingToken != null && mounted) {
        // User came from invite link - go directly to join community
        context.go('${AppRoutes.joinCommunity}/$pendingToken');
      } else if (mounted) {
        context.push(AppRoutes.pickMembership);
      }
    } else {
      final error = ref.read(authProvider).error;
      showErrorSnackbar(error ?? 'Failed to create passkey');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60),
            AppBackButton(),
            SizedBox(height: 20),
            Text(
              'Confirm passkey',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Re-enter your 5-digit PIN to confirm.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF606060),
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
                            : Color(0xFFE8E8E8),
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
                Color? color;

                if (index < 9) {
                  buttonText = (index + 1).toString();
                  onPressed = () => _onNumberPressed(buttonText!);
                } else if (index == 9) {
                  buttonIcon = const Icon(Icons.backspace_outlined, color: Colors.black);
                  onPressed = _onBackspacePressed;
                } else if (index == 10) {
                  buttonText = '0';
                  onPressed = () => _onNumberPressed(buttonText!);
                } else {
                  buttonIcon = Icon(
                    Icons.check,
                    color: Color(_pin.length == 5 ? 0xFFFFFFFF : 0xFFBBBBBB),
                  );
                  onPressed = _onSubmitPressed;
                  color = _pin.length == 5 ? AppColors.primary : null;
                }

                return _buildKeypadButton(
                  text: buttonText,
                  icon: buttonIcon,
                  onPressed: onPressed,
                  color: color,
                );
              },
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
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        width: 58,
        decoration: BoxDecoration(
          color: color ?? Color(0xFFF3F3F3),
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
                    color: Color(0xFF333333),
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}
