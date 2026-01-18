import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

/// Wallet Success Page
///
/// Final screen after wallet creation.
/// Shows success message and allows user to proceed to wallet tab.
class WalletSuccessPage extends ConsumerStatefulWidget {
  const WalletSuccessPage({super.key});

  @override
  ConsumerState<WalletSuccessPage> createState() => _WalletSuccessPageState();
}

class _WalletSuccessPageState extends ConsumerState<WalletSuccessPage> {
  bool _isNavigating = false;

  Future<void> _navigateToWallet() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Refresh user profile to update hasWallet status
    await ref.read(authProvider.notifier).refreshUserProfile();

    if (!mounted) return;

    // Navigate to home with wallet tab (index 3)
    context.go(AppRoutes.home, extra: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to exit'),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
          children: [
            const SizedBox(height: 100),
            // Success illustration
            SvgPicture.asset('assets/svgs/sucessful.svg'),
            const SizedBox(height: 20),
            Text(
              'Your wallet has been created',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You can now safely fund your wallet and carry out community finance activities',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Go to Wallet button
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.075,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(43),
                  ),
                ),
                onPressed: _isNavigating ? null : _navigateToWallet,
                child: _isNavigating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Go to Wallet',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}
