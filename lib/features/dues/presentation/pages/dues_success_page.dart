import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/dues/data/models/due_creation_data.dart';

class DuesSuccessPage extends StatelessWidget {
  final DueCreationData? dueData;

  const DuesSuccessPage({super.key, this.dueData});

  @override
  Widget build(BuildContext context) {
    final data = dueData ?? DueCreationData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                // Success Title
                Text(
                  'Due Created Successfully!',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF020014),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Success Description
                Text(
                  'Your due has been created and all community members will be notified automatically.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606060),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Due Details Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE9ECEF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Details',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF020014),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildDetailRow('Title', data.title ?? 'N/A'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Amount', 'NGN ${data.amount?.toStringAsFixed(0) ?? '0'}'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Frequency', data.frequency ?? 'N/A'),
                      const SizedBox(height: 10),
                      _buildDetailRow('Start Date', _formatDate(data.startDate)),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Auto Deduction',
                          data.automaticDeduction == true
                              ? 'Enabled'
                              : 'Disabled'),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          'Auto Reminder',
                          data.automaticReminder == true
                              ? 'Enabled'
                              : 'Disabled'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Action Buttons
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: () {
                    // Navigate to Dashboard with Hub tab selected
                    context.go(AppRoutes.dashboard);
                  },
                  title: 'Go to Hub',
                  buttonColor: Color(0xFF21A8FB),
                  height: 54,
                ),
                const SizedBox(height: 15),
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: () {
                    // Navigate back to dashboard
                    context.go(AppRoutes.dashboard);
                  },
                  title: 'Create Another Due',
                  buttonColor: Colors.grey,
                  height: 54,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF606060),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF020014),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
