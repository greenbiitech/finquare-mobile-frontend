import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

enum PayoutOrderType {
  randomBallot,
  firstComeFirstServed,
}

class SelectPayoutOrderPage extends StatefulWidget {
  const SelectPayoutOrderPage({super.key});

  @override
  State<SelectPayoutOrderPage> createState() => _SelectPayoutOrderPageState();
}

class _SelectPayoutOrderPageState extends State<SelectPayoutOrderPage> {
  PayoutOrderType _selectedType = PayoutOrderType.randomBallot;

  void _showDisclaimerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DisclaimerModal(
        onAccept: () {
          Navigator.pop(context);
          context.push(AppRoutes.esusuSuccess);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 20),
                  Text(
                    'Select Payout Order',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Random Ballot option
                    _buildPayoutOption(
                      type: PayoutOrderType.randomBallot,
                      title: 'Random Ballot',
                      description: 'The system will randomly assign the payout order to all accepted members.',
                    ),
                    const SizedBox(height: 12),
                    // First Come, First Served option
                    _buildPayoutOption(
                      type: PayoutOrderType.firstComeFirstServed,
                      title: 'First Come, First Served',
                      description: 'Members who accepted the invitation earliest will get to chose their payout order.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: _showDisclaimerModal,
                title: 'Send Invites',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutOption({
    required PayoutOrderType type,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _esusuLightColor : Colors.white,
          border: Border.all(
            color: isSelected ? _esusuPrimaryColor : Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _esusuPrimaryColor : Color(0xFF9E9E9E),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _esusuPrimaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606060),
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

class _DisclaimerModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const _DisclaimerModal({
    required this.onAccept,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Disclaimer',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Subtitle
          Text(
            'FinSquare Esusu Disclaimer',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Disclaimer paragraphs
          Text(
            'FinSquare provides software to help your community manage rotational savings (Esusu).',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FinSquarre is only a tool for tracking and collecting payments.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Community members are responsible for all payments.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'By creating or joining an Esusu on FinSquare, you accept these terms and the risk of non-payment by other members.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Use FinSquare with people you trust.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 30),
          // Accept button
          DefaultButton(
            isButtonEnabled: true,
            onPressed: onAccept,
            title: 'Accept',
            buttonColor: _esusuPrimaryColor,
            height: 54,
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFF3F3F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
