import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

class WelcomeCommunityPage extends ConsumerStatefulWidget {
  const WelcomeCommunityPage({super.key});

  @override
  ConsumerState<WelcomeCommunityPage> createState() => _WelcomeCommunityPageState();
}

class _WelcomeCommunityPageState extends ConsumerState<WelcomeCommunityPage> {
  @override
  void initState() {
    super.initState();
    // Launch confetti when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchConfetti();
    });
  }

  void _launchConfetti() {
    // Launch multiple confetti bursts over time
    final bursts = [
      {'delay': 0, 'x': 0.5, 'y': 0.3, 'particles': 100, 'spread': 70},
      {'delay': 200, 'x': 0.2, 'y': 0.4, 'particles': 50, 'spread': 100},
      {'delay': 400, 'x': 0.8, 'y': 0.4, 'particles': 50, 'spread': 100},
      {'delay': 700, 'x': 0.5, 'y': 0.5, 'particles': 80, 'spread': 80},
      {'delay': 1000, 'x': 0.3, 'y': 0.3, 'particles': 60, 'spread': 90},
      {'delay': 1300, 'x': 0.7, 'y': 0.3, 'particles': 60, 'spread': 90},
      {'delay': 1600, 'x': 0.5, 'y': 0.4, 'particles': 100, 'spread': 70},
      {'delay': 2000, 'x': 0.2, 'y': 0.5, 'particles': 50, 'spread': 100},
      {'delay': 2300, 'x': 0.8, 'y': 0.5, 'particles': 50, 'spread': 100},
      {'delay': 2600, 'x': 0.5, 'y': 0.3, 'particles': 80, 'spread': 80},
    ];

    for (final burst in bursts) {
      Future.delayed(Duration(milliseconds: burst['delay'] as int), () {
        if (mounted) {
          Confetti.launch(
            context,
            options: ConfettiOptions(
              particleCount: burst['particles'] as int,
              spread: (burst['spread'] as int).toDouble(),
              x: burst['x'] as double,
              y: burst['y'] as double,
            ),
          );
        }
      });
    }
  }

  Future<void> _navigateToHome() async {
    final creationState = ref.read(communityCreationProvider);
    final communityId = creationState.createdCommunity?.id;

    if (communityId != null) {
      // Switch to the newly created community
      await ref.read(communityProvider.notifier).switchActiveCommunity(communityId);
    }

    // Refresh community data
    await ref.read(communityProvider.notifier).fetchAllCommunityData();

    // Reset the community creation state
    ref.read(communityCreationProvider.notifier).reset();

    // Navigate to Dashboard and clear all previous routes
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityCreationProvider);
    final communityName = state.createdCommunity?.name ?? 'your Community';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              SizedBox(height: 150),
              SvgPicture.asset('assets/svgs/sucessful.svg'),
              SizedBox(height: 20),
              Text(
                'Welcome to $communityName!',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Take advantage of community financing, gain access to '
                'credit, and enjoy exclusive discounts on various products and services.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: _navigateToHome,
            child: Text(
              "Let's Go",
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
