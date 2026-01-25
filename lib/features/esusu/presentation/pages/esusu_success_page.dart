import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class EsusuSuccessPage extends ConsumerStatefulWidget {
  const EsusuSuccessPage({super.key});

  @override
  ConsumerState<EsusuSuccessPage> createState() => _EsusuSuccessPageState();
}

class _EsusuSuccessPageState extends ConsumerState<EsusuSuccessPage> {
  bool _confettiLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchConfetti();
    });
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

  void _navigateToHub() {
    // Reset the esusu creation state
    ref.read(esusuCreationProvider.notifier).reset();
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
                  'Invites have been sent and savings will start once all members accept',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606060),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // View Esusu Button
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: _navigateToHub,
                  title: 'View Esusu',
                  buttonColor: _esusuPrimaryColor,
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
            color: Color(0xFF4CAF50).withValues(alpha: 0.1),
          ),
        ),
        // Middle circle
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4CAF50).withValues(alpha: 0.2),
          ),
        ),
        // Inner darker circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4CAF50),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.check,
            color: Colors.white,
            size: 60,
          ),
        ),
      ],
    );
  }
}
