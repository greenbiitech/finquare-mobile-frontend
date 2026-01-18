import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _mainTextColor = Color(0xFF333333);

/// Create Hub Page - Static UI matching old Greencard design exactly
/// Shows options to create different types of hubs
/// Logic to be added later
class CreateHubPage extends ConsumerWidget {
  const CreateHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, show all options. Later, filter based on community type
    // (Greencard shows only Group Buying and Target Savings)
    final bool isGreencardCommunity = false; // TODO: Get from community provider

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // Header with back button and title
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 20),
                  Text(
                    'Create',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Hub options
              if (isGreencardCommunity) ...[
                // Greencard Community - Limited options (uses hub folder SVGs with 40x40)
                _buildHubCard(
                  context: context,
                  title: 'Group Buying',
                  description:
                      'Buy together, save together. Pool resources with your community to get better deals on bulk purchases.',
                  svgPath: 'assets/svgs/hub/group_buying.svg',
                  svgWidth: 40,
                  svgHeight: 40,
                  onTap: () {
                    // TODO: Navigate to Group Buying creation
                  },
                ),
                const SizedBox(height: 20),
                _buildHubCard(
                  context: context,
                  title: 'Target Savings',
                  description:
                      'Set a goal. Save with purpose. Hit your target. Whether it\'s a gadget, rent, or a big plan — get there faster.',
                  svgPath: 'assets/svgs/hub/target_savings.svg',
                  svgWidth: 40,
                  svgHeight: 40,
                  onTap: () {
                    // TODO: Navigate to Target Savings creation
                  },
                ),
              ] else ...[
                // Regular Community - All options (uses root-level SVGs - large illustrations)
                // Note: Only Dues has a complete flow in old codebase
                _buildHubCard(
                  context: context,
                  title: 'Esusu (Rotating Savings)',
                  description:
                      'Join or start an Esusu — take turns, grow wealth, stay committed. Community-powered saving made simple.',
                  svgPath: 'assets/svgs/esusu.svg',
                ),
                const SizedBox(height: 20),
                _buildHubCard(
                  context: context,
                  title: 'Contributions',
                  description:
                      'Contribute with ease, track with clarity. Keep group finances transparent and on track.',
                  svgPath: 'assets/svgs/contributions.svg',
                ),
                const SizedBox(height: 20),
                _buildHubCard(
                  context: context,
                  title: 'Dues',
                  description:
                      'Collect dues without the chase — track, remind, and receive in one place. For smoother group contributions and less stress.',
                  svgPath: 'assets/svgs/dues.svg',
                  onTap: () {
                    context.push(AppRoutes.duesWelcome);
                  },
                ),
                const SizedBox(height: 20),
                _buildHubCard(
                  context: context,
                  title: 'Target Savings',
                  description:
                      'Set a goal. Save with purpose. Hit your target. Whether it\'s a gadget, rent, or a big plan — get there faster.',
                  svgPath: 'assets/svgs/target_savings.svg',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hub card matching old design exactly - with SVG icons
  /// For Greencard community: uses fixed 40x40 dimensions
  /// For regular community: uses natural SVG size (no dimensions)
  Widget _buildHubCard({
    required BuildContext context,
    required String title,
    required String description,
    required String svgPath,
    double? svgWidth,
    double? svgHeight,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _greyBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _mainTextColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _mainTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // SVG icon matching old design
            SvgPicture.asset(
              svgPath,
              width: svgWidth,
              height: svgHeight,
            ),
          ],
        ),
      ),
    );
  }
}
