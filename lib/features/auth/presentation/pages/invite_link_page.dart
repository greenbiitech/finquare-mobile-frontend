import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_creation_provider.dart';

class InviteLinkPage extends ConsumerWidget {
  /// Optional communityId - if provided, we're inviting to an existing community
  final String? communityId;

  const InviteLinkPage({super.key, this.communityId});

  /// Check if we're inviting to an existing community (not creation flow)
  bool get _isExistingCommunityFlow => communityId != null;

  void _goBack(BuildContext context) {
    context.pop();
  }

  void _goToDashboard(BuildContext context) {
    context.go(AppRoutes.home);
  }

  void _goToInviteSettings(BuildContext context, String communityId) {
    context.push('${AppRoutes.inviteSettings}/$communityId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityCreationProvider);

    // Use provided communityId for existing community flow, or get from state for creation flow
    final effectiveCommunityId = _isExistingCommunityFlow
        ? communityId
        : state.createdCommunity?.id;
    final communityName = _isExistingCommunityFlow
        ? 'your community'  // Could fetch name from provider if needed
        : (state.createdCommunity?.name ?? 'your community');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _isExistingCommunityFlow
            ? IconButton(
                onPressed: () => _goBack(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              )
            : null,
        actions: _isExistingCommunityFlow
            ? null
            : [
                TextButton(
                  onPressed: () => _goToDashboard(context),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/svgs/pana.svg'),
                  const SizedBox(height: 40),
                  Text(
                    'Invite your members',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Choose how you want to invite people to $communityName',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
              child: Column(
                children: [
                  // Email invites button
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
                      onPressed: () {
                        if (_isExistingCommunityFlow && communityId != null) {
                          context.push('${AppRoutes.inviteMembers}/$communityId');
                        } else {
                          context.push(AppRoutes.inviteMembers);
                        }
                      },
                      child: Text(
                        'Send Email Invites',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Generate shareable link button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(43),
                        ),
                      ),
                      onPressed: effectiveCommunityId != null
                          ? () => _goToInviteSettings(context, effectiveCommunityId)
                          : null,
                      icon: Icon(
                        Icons.link,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      label: Text(
                        'Create Shareable Link',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
