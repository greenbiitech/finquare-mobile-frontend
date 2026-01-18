import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/home/presentation/widgets/user_info_card.dart';
import 'package:finsquare_mobile_app/features/home/presentation/widgets/wallet_card.dart';
import 'package:finsquare_mobile_app/features/home/presentation/widgets/activity_section.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, this.onNavigateToWallet});

  /// Callback to navigate to the Wallet tab
  final VoidCallback? onNavigateToWallet;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch active community when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCommunityIfNeeded();
    });
  }

  void _fetchCommunityIfNeeded() {
    final communityState = ref.read(communityProvider);
    if (communityState.activeCommunity == null) {
      ref.read(communityProvider.notifier).fetchActiveCommunity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to create hub/community action
          },
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const UserInfoCard(),
              const SizedBox(height: 20),
              WalletCard(onSetUpWallet: widget.onNavigateToWallet),
              const SizedBox(height: 20),
              const ActivitySection(),
            ],
          ),
        ),
      ),
    );
  }
}
