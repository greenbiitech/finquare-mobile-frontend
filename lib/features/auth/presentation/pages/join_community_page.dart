import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/network/api_client.dart';
import 'package:finsquare_mobile_app/core/services/services.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

/// Key for storing pending invite token
const String kPendingInviteTokenKey = 'pending_invite_token';

/// State for join community page
enum JoinCommunityState {
  loading,
  loaded,
  joining,
  joined,
  pendingApproval,
  alreadyMember,
  error,
  invalidInvite,
  requiresAuth, // User needs to sign up or login first
}

class JoinCommunityPage extends ConsumerStatefulWidget {
  final String inviteToken;

  const JoinCommunityPage({
    super.key,
    required this.inviteToken,
  });

  @override
  ConsumerState<JoinCommunityPage> createState() => _JoinCommunityPageState();
}

class _JoinCommunityPageState extends ConsumerState<JoinCommunityPage> {
  JoinCommunityState _state = JoinCommunityState.loading;
  InviteDetails? _inviteDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInviteDetails();
  }

  Future<void> _loadInviteDetails() async {
    try {
      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.getInviteDetails(widget.inviteToken);

      if (!mounted) return;

      if (response.success && response.invite != null) {
        if (response.invite!.isValid) {
          setState(() {
            _inviteDetails = response.invite;
            _state = JoinCommunityState.loaded;
          });
        } else {
          setState(() {
            _state = JoinCommunityState.invalidInvite;
            _errorMessage = response.invite!.invalidReason ?? 'This invite link is no longer valid';
          });
        }
      } else {
        setState(() {
          _state = JoinCommunityState.error;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = JoinCommunityState.error;
        _errorMessage = 'Failed to load invite details';
      });
    }
  }

  Future<void> _joinCommunity() async {
    setState(() {
      _state = JoinCommunityState.joining;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.joinViaInvite(widget.inviteToken);

      if (!mounted) return;

      if (response.success) {
        switch (response.resultType) {
          case JoinResultType.joined:
            setState(() {
              _state = JoinCommunityState.joined;
            });
            _launchConfetti();
            break;
          case JoinResultType.pendingApproval:
            setState(() {
              _state = JoinCommunityState.pendingApproval;
            });
            break;
          case JoinResultType.alreadyMember:
            setState(() {
              _state = JoinCommunityState.alreadyMember;
            });
            break;
          case JoinResultType.alreadyRequested:
            setState(() {
              _state = JoinCommunityState.pendingApproval;
            });
            break;
        }
      } else {
        setState(() {
          _state = JoinCommunityState.error;
          _errorMessage = response.message;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        // User is not authenticated
        setState(() {
          _state = JoinCommunityState.requiresAuth;
        });
      } else {
        setState(() {
          _state = JoinCommunityState.error;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = JoinCommunityState.error;
        _errorMessage = 'Failed to join community';
      });
    }
  }

  void _launchConfetti() {
    final bursts = [
      {'delay': 0, 'x': 0.5, 'y': 0.3, 'particles': 100, 'spread': 70},
      {'delay': 200, 'x': 0.2, 'y': 0.4, 'particles': 50, 'spread': 100},
      {'delay': 400, 'x': 0.8, 'y': 0.4, 'particles': 50, 'spread': 100},
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

  void _navigateToHome() {
    // Clear the pending invite
    ref.read(pendingInviteLinkProvider.notifier).clear();
    context.go(AppRoutes.home);
  }

  void _goBack() {
    // Clear the pending invite
    ref.read(pendingInviteLinkProvider.notifier).clear();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Color _getCommunityColor() {
    if (_inviteDetails?.communityColor != null) {
      try {
        final colorStr = _inviteDetails!.communityColor!.replaceFirst('#', '');
        return Color(int.parse('FF$colorStr', radix: 16));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _goBack,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case JoinCommunityState.loading:
        return _buildLoadingState();
      case JoinCommunityState.loaded:
        return _buildLoadedState();
      case JoinCommunityState.joining:
        return _buildJoiningState();
      case JoinCommunityState.joined:
        return _buildJoinedState();
      case JoinCommunityState.pendingApproval:
        return _buildPendingApprovalState();
      case JoinCommunityState.alreadyMember:
        return _buildAlreadyMemberState();
      case JoinCommunityState.requiresAuth:
        return _buildRequiresAuthState();
      case JoinCommunityState.error:
      case JoinCommunityState.invalidInvite:
        return _buildErrorState();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading invite details...',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState() {
    final communityColor = _getCommunityColor();
    final isApprovalRequired = _inviteDetails?.joinType == JoinType.approvalRequired;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Community Logo/Initial
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: communityColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: communityColor, width: 3),
            ),
            child: _inviteDetails?.communityLogo != null
                ? ClipOval(
                    child: Image.network(
                      _inviteDetails!.communityLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCommunityInitial(communityColor),
                    ),
                  )
                : _buildCommunityInitial(communityColor),
          ),
          const SizedBox(height: 24),
          // Community Name
          Text(
            _inviteDetails?.communityName ?? 'Community',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Invitation Message
          Text(
            "You've been invited to join this community!",
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.people_outline,
                  'Join Type',
                  isApprovalRequired ? 'Approval Required' : 'Open to All',
                ),
                if (isApprovalRequired) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your request will be sent to the community admin for approval',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Join Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: communityColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: _joinCommunity,
              child: Text(
                isApprovalRequired ? 'Request to Join' : 'Join Community',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Cancel Button
          TextButton(
            onPressed: _goBack,
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInitial(Color color) {
    final name = _inviteDetails?.communityName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoiningState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Joining community...',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedState() {
    final communityName = _inviteDetails?.communityName ?? 'the community';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Spacer(),
          SvgPicture.asset('assets/svgs/sucessful.svg'),
          const SizedBox(height: 20),
          Text(
            'Welcome to $communityName!',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'You have successfully joined the community. '
            'Enjoy all the benefits of being a member!',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
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
              onPressed: _navigateToHome,
              child: const Text(
                "Let's Go",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty,
              size: 50,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Request Sent!',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Your request to join ${_inviteDetails?.communityName ?? 'the community'} '
            'has been sent to the admin for approval. '
            "You'll be notified once your request is reviewed.",
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
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
              onPressed: _navigateToHome,
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlreadyMemberState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "You're Already a Member!",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'You are already a member of ${_inviteDetails?.communityName ?? 'this community'}.',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
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
              onPressed: _navigateToHome,
              child: const Text(
                'Go to Home',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRequiresAuthState() {
    final communityColor = _getCommunityColor();
    final communityName = _inviteDetails?.communityName ?? 'this community';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Community Logo/Initial
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: communityColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: communityColor, width: 3),
            ),
            child: _inviteDetails?.communityLogo != null
                ? ClipOval(
                    child: Image.network(
                      _inviteDetails!.communityLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCommunityInitial(communityColor),
                    ),
                  )
                : _buildCommunityInitial(communityColor),
          ),
          const SizedBox(height: 24),
          // Community Name
          Text(
            communityName,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Message
          const Text(
            "You've been invited to join this community!",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Auth Required Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Required',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an account or sign in to join this community',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Sign Up Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: communityColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: () async {
                // Save invite token for after auth completes
                const storage = FlutterSecureStorage();
                await storage.write(
                  key: kPendingInviteTokenKey,
                  value: widget.inviteToken,
                );
                // Navigate to signup
                if (mounted) {
                  context.go(AppRoutes.signup);
                }
              },
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Login Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: communityColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: () async {
                // Save invite token for after auth completes
                const storage = FlutterSecureStorage();
                await storage.write(
                  key: kPendingInviteTokenKey,
                  value: widget.inviteToken,
                );
                // Navigate to login
                if (mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: communityColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Cancel Button
          TextButton(
            onPressed: _goBack,
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _state == JoinCommunityState.invalidInvite
                  ? Icons.link_off
                  : Icons.error_outline,
              size: 50,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _state == JoinCommunityState.invalidInvite
                ? 'Invalid Invite Link'
                : 'Something Went Wrong',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'An unexpected error occurred',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
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
              onPressed: _goBack,
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
