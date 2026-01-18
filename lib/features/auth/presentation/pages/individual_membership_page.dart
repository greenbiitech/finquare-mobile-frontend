import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

class IndividualMembershipPage extends ConsumerWidget {
  const IndividualMembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60),
                  AppBackButton(),
                  SizedBox(height: 20),
                  // FinSquare Community Badge
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'FinSquare Community',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Title
                  Text(
                    'Join the one BIG FinSquare Community',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  // Subtitle
                  Text(
                    'Recommended for individuals and households. Swipe to see more benefits for your plan',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 50),
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
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(43),
              ),
            ),
            onPressed: () async {
              ref.showLoading('Joining community...');
              try {
                final success = await ref
                    .read(communityProvider.notifier)
                    .joinDefaultCommunity();
                ref.hideLoading();

                if (success && context.mounted) {
                  showSuccessSnackbar('Welcome to FinSquare Community!');
                  context.push(AppRoutes.welcomeCommunity);
                } else if (context.mounted) {
                  final error = ref.read(communityProvider).error;
                  showErrorSnackbar(error ?? 'Failed to join community');
                }
              } catch (e) {
                ref.hideLoading();
                showErrorSnackbar('An unexpected error occurred');
              }
            },
            child: Text(
              'Continue',
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
    final List<Map<String, String>> cardData = [
      {
        'title': 'Food and Groceries',
        'description':
            'Enjoy heavy discounts on packaged food, fresh food and other cooking products straight from manufacturers.',
        'image': 'assets/svgs/frame.svg',
      },
      {
        'title': 'Health & Wellness',
        'description': 'Access Healthcare services, gym and fitness centers',
        'image': 'assets/svgs/containermem.svg',
      },
      {
        'title': 'Technology and Digital Resources',
        'description':
            'E-Commerce softwares such as invoicing app, online shop and book-keeping tools',
        'image': 'assets/svgs/amicotwo.svg',
      },
      {
        'title': 'Community Benefits',
        'description':
            'Group Buying and sharing. You can buy bulk items with other members and enjoy even more cost saving.',
        'image': 'assets/svgs/rafiki.svg',
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
  }) {
    return Container(
      width: 280,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
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
