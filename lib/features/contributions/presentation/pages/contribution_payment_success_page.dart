import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _contributionPrimary = Color(0xFFF83181);

class ContributionPaymentSuccessPage extends ConsumerStatefulWidget {
  final String contributionName;
  final String recipientName;
  final double amount;

  const ContributionPaymentSuccessPage({
    super.key,
    required this.contributionName,
    required this.recipientName,
    required this.amount,
  });

  @override
  ConsumerState<ContributionPaymentSuccessPage> createState() =>
      _ContributionPaymentSuccessPageState();
}

class _ContributionPaymentSuccessPageState
    extends ConsumerState<ContributionPaymentSuccessPage> {
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

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  void _viewContribution() {
    // Navigate back to the contribution detail or list
    context.go(AppRoutes.contributionsList);
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
                  'Payment Successful!',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Amount
                Text(
                  '₦${_formatCurrency(widget.amount)}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _contributionPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Success Description
                Text(
                  'Your contribution to ${widget.contributionName} has been successfully processed.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Transaction Details Card
                _buildTransactionCard(),
                const Spacer(),
                // View Contribution Button
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: _viewContribution,
                  title: 'View Contribution',
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

  Widget _buildTransactionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Contribution', widget.contributionName),
          const SizedBox(height: 12),
          _buildDetailRow('Recipient', widget.recipientName),
          const SizedBox(height: 12),
          _buildDetailRow('Date', _formatDate(DateTime.now())),
          const SizedBox(height: 12),
          _buildDetailRow('Status', 'Completed', isStatus: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: const Color(0xFF606060),
          ),
        ),
        isStatus
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              )
            : Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
