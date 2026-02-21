import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

/// Data model for info tiles displayed on the activate wallet page
class InfoTileModel {
  final String iconPath;
  final String title;
  final String subtitle;

  const InfoTileModel({
    required this.iconPath,
    required this.title,
    required this.subtitle,
  });
}

/// Activate Wallet Page
///
/// This page is shown when the user's hasWallet is false.
/// It displays the benefits of activating a wallet and provides
/// a button to start the wallet setup flow.
class ActivateWalletPage extends ConsumerWidget {
  const ActivateWalletPage({super.key});

  static const List<InfoTileModel> _infoTiles = [
    InfoTileModel(
      iconPath: 'assets/svgs/frame_2609038.svg',
      title: 'Participate in Community Finance',
      subtitle: 'Your wallet is like your bank account for debit and credit in Esusu, Savings, dues etc',
    ),
    InfoTileModel(
      iconPath: 'assets/svgs/frame_2609038_1.svg',
      title: 'Track your transactions',
      subtitle: 'Generate statements and track your money trail Reply',
    ),
    InfoTileModel(
      iconPath: 'assets/svgs/frame_2609038_2.svg',
      title: 'Secure and Convenient',
      subtitle: 'Your funds are safe, and payments are hassle-free',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get hasWallet from user state when logic is integrated
    // final hasWallet = ref.watch(authProvider).user?.hasWallet ?? false;
    // if (hasWallet) return WalletDashboard();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _ActivateWalletWidget(infoTiles: _infoTiles),
        ),
      ),
    );
  }
}

class _ActivateWalletWidget extends ConsumerStatefulWidget {
  const _ActivateWalletWidget({required this.infoTiles});

  final List<InfoTileModel> infoTiles;

  @override
  ConsumerState<_ActivateWalletWidget> createState() =>
      _ActivateWalletWidgetState();
}

class _ActivateWalletWidgetState extends ConsumerState<_ActivateWalletWidget> {
  bool _isLoading = false;

  Future<void> _onSetUpWallet() async {
    setState(() => _isLoading = true);

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final progress = await walletRepo.getSetupProgress();

      if (!mounted) return;

      // BVN/NIN flow routes require fresh Mono API session - can't resume mid-flow
      const identityFlowRoutes = [
        AppRoutes.selectVerificationType,
        AppRoutes.bvnValidation,
        AppRoutes.ninValidation,
        AppRoutes.selectVerificationMethod,
        AppRoutes.verifyBvnCredentials,
        AppRoutes.verifyOtp,
      ];

      // If there's a resume route and it's not the current page or an identity flow route, navigate there
      final resumeRoute = progress.resumeRoute;
      if (resumeRoute != null &&
          resumeRoute.isNotEmpty &&
          resumeRoute != AppRoutes.activateWallet &&
          !identityFlowRoutes.contains(resumeRoute)) {
        context.push(resumeRoute, extra: progress);
      } else {
        // Start from beginning - Select BVN or NIN verification
        context.push(AppRoutes.selectVerificationType);
      }
    } catch (e) {
      if (!mounted) return;
      // If error fetching progress, just start from beginning
      context.push(AppRoutes.selectVerificationType);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        Text(
          'Wallet',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SvgPicture.asset(
            'assets/svgs/walletsvg.svg',
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Activate Your Wallet',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        _InfoTileList(tiles: widget.infoTiles, iconHeight: 40),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: _isLoading ? null : _onSetUpWallet,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Set Up Wallet Now',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 9),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _InfoTileList extends StatelessWidget {
  final List<InfoTileModel> tiles;
  final double iconHeight;

  const _InfoTileList({required this.tiles, this.iconHeight = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tiles.map((tile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _InfoTile(
            iconPath: tile.iconPath,
            title: tile.title,
            subtitle: tile.subtitle,
            iconHeight: iconHeight,
          ),
        );
      }).toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final double iconHeight;

  const _InfoTile({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.iconHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(iconPath, height: iconHeight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
