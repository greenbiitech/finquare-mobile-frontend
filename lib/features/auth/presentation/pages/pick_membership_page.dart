import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';

class PickMembershipPage extends StatelessWidget {
  const PickMembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
              AppBackButton(),
              SizedBox(height: 20),
              Text(
                'What do you want to do 🤔',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Let's kick things off for you!",
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 60),
              // Communities Card
              _buildMembershipCard(
                backgroundImage: 'assets/images/community_card_bg.png',
                badge: 'Communities',
                badgeColor: AppColors.textPrimary,
                title: 'Onboard your Community',
                subtitle:
                    'Customize this app for your Staff cooperative, Old Students Assoc. or any social Group you belong to',
                textColor: AppColors.textOnPrimary,
                onTap: () {
                  context.push(AppRoutes.onboardCommunity);
                },
              ),
              SizedBox(height: 24),
              // FinSquare Card
              _buildMembershipCard(
                backgroundImage: 'assets/images/finsquare_card_bg.png',
                badge: 'FinSquare',
                badgeColor: AppColors.primary,
                title: 'Join the one BIG FinSquare Community',
                subtitle:
                    "You don't belong to any Group or they're not ready right now? That's okay! Join the FinSquare family",
                textColor: AppColors.textPrimary,
                onTap: () {
                  context.push(AppRoutes.individualMembership);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipCard({
    required String backgroundImage,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 7),
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 35, child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
