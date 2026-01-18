import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors from old codebase
const Color _mainTextColor = Color(0xFF333333);

/// Confirm Transaction PIN Page
///
/// Final step in wallet setup flow.
/// User confirms their 4-digit PIN to create the wallet.
class ConfirmTransactionPinPage extends ConsumerStatefulWidget {
  const ConfirmTransactionPinPage({super.key, required this.firstPin});

  final String firstPin;

  @override
  ConsumerState<ConfirmTransactionPinPage> createState() =>
      _ConfirmTransactionPinPageState();
}

class _ConfirmTransactionPinPageState
    extends ConsumerState<ConfirmTransactionPinPage> {
  String _pin = '';
  bool _isSubmitting = false;

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
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
    if (_isSubmitting) return;

    if (_pin.length != 4) {
      showErrorSnackbar('Please enter a 4-digit PIN.');
      HapticFeedback.heavyImpact();
      return;
    }

    if (widget.firstPin != _pin) {
      showErrorSnackbar('PIN does not match');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final request = CompleteStep5Request(transactionPin: _pin);
      final response = await walletRepo.completeStep5(request);

      if (!mounted) return;

      if (response.success) {
        HapticFeedback.heavyImpact();
        context.go(AppRoutes.walletSuccess);
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to create wallet. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              // Back button
              const AppBackButton(),
              const SizedBox(height: 22),
              // Title
              Text(
                'Confirm your Transaction pin',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _mainTextColor,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              "Pick a 4-digit PIN that even a ninja couldn't guess. (But you can, obviously!)",
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF606060),
              ),
            ),
            const Spacer(),
            // PIN input display
            Center(
              child: Container(
                width: 160,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
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
            // Numeric Keypad
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
                  buttonIcon =
                      const Icon(Icons.backspace_outlined, color: Colors.black);
                  onPressed = _onBackspacePressed;
                } else if (index == 10) {
                  buttonText = '0';
                  onPressed = () => _onNumberPressed(buttonText!);
                } else {
                  // index == 11 - Submit button
                  if (_isSubmitting) {
                    return Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  buttonIcon = Icon(
                    Icons.check,
                    color: Color(_pin.length == 4 ? 0xFFFFFFFF : 0xFFBBBBBB),
                  );
                  onPressed = _onSubmitPressed;
                  color = _pin.length == 4 ? AppColors.primary : null;
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
          color: color ?? const Color(0xFFF3F3F3),
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
                    color: _mainTextColor,
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}
