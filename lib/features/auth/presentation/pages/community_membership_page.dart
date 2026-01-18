import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

class CommunityMembershipPage extends ConsumerStatefulWidget {
  const CommunityMembershipPage({super.key});

  @override
  ConsumerState<CommunityMembershipPage> createState() =>
      _CommunityMembershipPageState();
}

class _CommunityMembershipPageState
    extends ConsumerState<CommunityMembershipPage> {
  @override
  void initState() {
    super.initState();
    // Launch confetti when page loads (community just created!)
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

  Future<void> _skipToHome() async {
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

    // Navigate to Dashboard
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextButton(
              onPressed: _skipToHome,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/mesh_gradient.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Foreground Content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  // Communities Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Communities',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Title
                  Text(
                    'A mobile app for your Community that you can call your own',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'Swipe to see more benefits for your plan',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: _HorizontalCardList(),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            onPressed: () {
              context.push(AppRoutes.inviteLink);
            },
            child: Text(
              'Invite members',
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

class _HorizontalCardList extends StatelessWidget {
  const _HorizontalCardList();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': 'Community dues',
        'description':
            'Collect dues without the chase — track, remind, and receive in one place. For smoother group contributions and less stress.',
        'image': 'assets/svgs/community_1.svg',
        'color': 0xFFF1F9FA,
      },
      {
        'title': 'Esusu (Rotational Savings)',
        'description':
            'Esusu, the modern way. Take turns receiving lump sums in a secure and transparent way.',
        'image': 'assets/svgs/community_2.svg',
        'color': 0xFFF7F2FB,
      },
      {
        'title': 'Group Buying',
        'description':
            'Buy together, pay less. Enjoy exclusive discounts on essentials like groceries, healthcare, gym memberships, and more!',
        'image': 'assets/svgs/community_3.svg',
        'color': 0xFFF8ECDF,
      },
      {
        'title': 'Cooperative loans',
        'description':
            'Access loans via your cooperative at low interest rates. They handle applications, disbursements, and repayments through the FinSquare App.',
        'image': 'assets/svgs/amicotwo.svg',
        'color': 0xFFF3F3F3,
      },
      {
        'title': 'Target savings',
        'description':
            "Save together and reach goals faster! Whether it's rent, foodstuff, or travel, FinSquare helps your group stay accountable.",
        'image': 'assets/svgs/community_5.svg',
        'color': 0xFFF3F3F3,
      },
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cardData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 16),
            child: _buildCard(
              title: cardData[index]['title']!,
              description: cardData[index]['description']!,
              imagePath: cardData[index]['image']!,
              color: cardData[index]['color']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required String imagePath,
    required int color,
  }) {
    return Container(
      width: 280,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.buttonInactive,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Center(
            child: SvgPicture.asset(imagePath),
          ),
        ],
      ),
    );
  }
}
