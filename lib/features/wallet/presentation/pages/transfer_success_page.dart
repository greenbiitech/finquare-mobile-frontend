import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';

// Colors
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);

/// Transfer Success Page - Screen 4
/// Shows success message with confetti animation
class TransferSuccessPage extends StatelessWidget {
  final String recipientName;
  final double amount;

  const TransferSuccessPage({
    super.key,
    required this.recipientName,
    required this.amount,
  });

  void _onGetReceipt(BuildContext context) {
    // TODO: Implement receipt generation/download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt feature coming soon')),
    );
  }

  void _onDone(BuildContext context) {
    // Navigate back to wallet tab (index 3 in dashboard)
    context.go('${AppRoutes.home}?tab=3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Success Animation with Confetti
              Stack(
                alignment: Alignment.center,
                children: [
                  // Confetti SVG (if available)
                  SvgPicture.asset(
                    'assets/svgs/sucessful.svg',
                    width: 280,
                    height: 280,
                    placeholderBuilder: (context) => _buildSuccessIcon(),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Success Title
              Text(
                'Transfer successful',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 12),

              // Success Message
              Text(
                'Your transfer has been processed.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: _greyTextColor,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Get Receipt Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _onGetReceipt(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mainTextColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Get receipt',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Done Button (text button)
              TextButton(
                onPressed: () => _onDone(context),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _greyTextColor,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback success icon if SVG is not available
  Widget _buildSuccessIcon() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade400,
            _mainTextColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _mainTextColor,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    );
  }
}
