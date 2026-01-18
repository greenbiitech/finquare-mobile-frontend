import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

/// Data model for info tiles displayed on the activate community wallet page
class CommunityWalletInfoTileModel {
  final String iconPath;
  final String title;
  final String subtitle;

  const CommunityWalletInfoTileModel({
    required this.iconPath,
    required this.title,
    required this.subtitle,
  });
}

/// Activate Community Wallet Page
///
/// This page is shown when the community wallet has not been created yet.
/// It displays the benefits of having a community wallet and provides
/// a button to start the community wallet setup flow.
/// Only Admin can create a community wallet.
class ActivateCommunityWalletPage extends ConsumerWidget {
  const ActivateCommunityWalletPage({super.key});

  static const List<CommunityWalletInfoTileModel> _infoTiles = [
    CommunityWalletInfoTileModel(
      iconPath: 'assets/svgs/frame_2609038.svg',
      title: 'Collect Community Funds',
      subtitle: 'Receive payments from Dues, Esusu, and Contributions into one central wallet',
    ),
    CommunityWalletInfoTileModel(
      iconPath: 'assets/svgs/frame_2609038_1.svg',
      title: 'Track Community Finances',
      subtitle: 'View all transactions and generate statements for transparency',
    ),
    CommunityWalletInfoTileModel(
      iconPath: 'assets/svgs/frame_2609038_2.svg',
      title: 'Secure and Accountable',
      subtitle: 'Funds are protected with designated signatories for oversight',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActivateCommunityWalletWidget(infoTiles: _infoTiles);
  }
}

class _ActivateCommunityWalletWidget extends ConsumerStatefulWidget {
  const _ActivateCommunityWalletWidget({required this.infoTiles});

  final List<CommunityWalletInfoTileModel> infoTiles;

  @override
  ConsumerState<_ActivateCommunityWalletWidget> createState() =>
      _ActivateCommunityWalletWidgetState();
}

class _ActivateCommunityWalletWidgetState extends ConsumerState<_ActivateCommunityWalletWidget> {
  void _onSetUpCommunityWallet() {
    final communityState = ref.read(communityProvider);
    final communityId = communityState.activeCommunity?.id;

    if (communityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active community found')),
      );
      return;
    }

    context.push('${AppRoutes.communityWalletSetup}/$communityId');
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final communityName = communityState.activeCommunity?.name ?? 'your community';
    final isAdmin = communityState.activeCommunity?.isAdmin ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/svgs/walletsvg.svg',
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Activate Community Wallet',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up a wallet for $communityName to manage community finances.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF606060),
          ),
        ),
        const SizedBox(height: 20),
        _CommunityWalletInfoTileList(tiles: widget.infoTiles, iconHeight: 40),
        const SizedBox(height: 40),
        if (isAdmin) ...[
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
              onPressed: _onSetUpCommunityWallet,
              child: Text(
                'Set Up Community Wallet',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ] else ...[
          // Co-Admin sees message that only Admin can create
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF8E8E8E),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only the community Admin can create the community wallet.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF606060),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class _CommunityWalletInfoTileList extends StatelessWidget {
  final List<CommunityWalletInfoTileModel> tiles;
  final double iconHeight;

  const _CommunityWalletInfoTileList({required this.tiles, this.iconHeight = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tiles.map((tile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CommunityWalletInfoTile(
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

class _CommunityWalletInfoTile extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final double iconHeight;

  const _CommunityWalletInfoTile({
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
