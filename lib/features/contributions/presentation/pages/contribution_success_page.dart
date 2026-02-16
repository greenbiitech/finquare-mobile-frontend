import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/providers/contribution_creation_provider.dart';

const Color _contributionPrimary = Color(0xFFF83181);

class ContributionSuccessPage extends ConsumerStatefulWidget {
  const ContributionSuccessPage({super.key});

  @override
  ConsumerState<ContributionSuccessPage> createState() =>
      _ContributionSuccessPageState();
}

class _ContributionSuccessPageState
    extends ConsumerState<ContributionSuccessPage> {
  bool _confettiLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchConfetti();
    });
  }

  String get _inviteLink {
    final state = ref.read(contributionCreationProvider);
    final inviteCode = state.createdContribution?.inviteCode ?? 'unknown';
    return 'Finsquare/$inviteCode';
  }

  String get _contributionName {
    final state = ref.read(contributionCreationProvider);
    return state.createdContribution?.name ?? state.contributionName;
  }

  int get _participantCount {
    final state = ref.read(contributionCreationProvider);
    return state.createdContribution?.participantCount ?? state.selectedParticipants.length;
  }

  void _launchConfetti() {
    if (_confettiLaunched) return;
    _confettiLaunched = true;

    final bursts = [
      {'delay': 0, 'particles': 50, 'spread': 70, 'x': 0.5, 'y': 0.3},
      {'delay': 200, 'particles': 30, 'spread': 50, 'x': 0.3, 'y': 0.4},
      {'delay': 400, 'particles': 30, 'spread': 50, 'x': 0.7, 'y': 0.4},
      {'delay': 600, 'particles': 40, 'spread': 60, 'x': 0.5, 'y': 0.5},
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

  void _copyInviteLink() {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invite link copied!',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        backgroundColor: _contributionPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewContribution() {
    // Reset the provider
    ref.read(contributionCreationProvider.notifier).reset();
    // Navigate to dashboard with Hub tab selected (index 2)
    context.go(AppRoutes.dashboard, extra: 2);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const Spacer(),
                // Success Icon with multiple circles
                _buildSuccessIcon(),
                const SizedBox(height: 40),
                // Success Title
                Text(
                  'Invites sent',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Success Description
                Text(
                  '$_participantCount invitation${_participantCount > 1 ? 's' : ''} sent for "$_contributionName". The Contribution will become active once participants accept.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Invite Link Section
                _buildInviteLinkSection(),
                const Spacer(),
                // View Contribution Button
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: _viewContribution,
                  title: 'view contribution',
                  buttonColor: _contributionPrimary,
                  height: 54,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer light circle
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          ),
        ),
        // Middle circle
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
          ),
        ),
        // Inner darker circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildInviteLinkSection() {
    return Column(
      children: [
        Text(
          'Invite link',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _inviteLink,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF606060),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _copyInviteLink,
              child: const Icon(
                Icons.copy_outlined,
                size: 20,
                color: Color(0xFF606060),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
