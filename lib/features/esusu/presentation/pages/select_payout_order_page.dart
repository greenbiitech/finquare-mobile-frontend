import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

class SelectPayoutOrderPage extends ConsumerStatefulWidget {
  const SelectPayoutOrderPage({super.key});

  @override
  ConsumerState<SelectPayoutOrderPage> createState() =>
      _SelectPayoutOrderPageState();
}

class _SelectPayoutOrderPageState extends ConsumerState<SelectPayoutOrderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Default to random if not already selected
      final state = ref.read(esusuCreationProvider);
      if (state.payoutOrderType == null) {
        ref
            .read(esusuCreationProvider.notifier)
            .setPayoutOrderType(PayoutOrderType.random);
      }
    });
  }

  void _showDisclaimerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DisclaimerModal(
        onAccept: _handleCreateEsusu,
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleCreateEsusu() async {
    Navigator.pop(context); // Close the modal

    final success =
        await ref.read(esusuCreationProvider.notifier).createEsusu();

    if (success && mounted) {
      context.push(AppRoutes.esusuSuccess);
    } else if (mounted) {
      final state = ref.read(esusuCreationProvider);
      _showErrorDialog(state.error ?? 'Failed to create Esusu');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);
    final selectedType = state.payoutOrderType ?? PayoutOrderType.random;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                          type: PayoutOrderType.random,
                          title: 'Random Ballot',
                          description:
                              'The system will randomly assign the payout order to all accepted members.',
                          selectedType: selectedType,
                          onTap: () {
                            ref
                                .read(esusuCreationProvider.notifier)
                                .setPayoutOrderType(PayoutOrderType.random);
                          },
                        ),
                        const SizedBox(height: 12),
                        // First Come, First Served option
                        _buildPayoutOption(
                          type: PayoutOrderType.firstComeFirstServed,
                          title: 'First Come, First Served',
                          description:
                              'Members who accepted the invitation earliest will get to choose their payout order.',
                          selectedType: selectedType,
                          onTap: () {
                            ref
                                .read(esusuCreationProvider.notifier)
                                .setPayoutOrderType(
                                    PayoutOrderType.firstComeFirstServed);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DefaultButton(
                    isButtonEnabled: !state.isLoading,
                    onPressed: _showDisclaimerModal,
                    title: 'Send Invites',
                    buttonColor: _esusuPrimaryColor,
                    height: 54,
                  ),
                ),
              ],
            ),
            // Loading overlay
            if (state.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _esusuPrimaryColor,
                  ),
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
    required PayoutOrderType selectedType,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _esusuLightColor : Colors.white,
          border: Border.all(
            color: isSelected ? _esusuPrimaryColor : const Color(0xFFE0E0E0),
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
                  color:
                      isSelected ? _esusuPrimaryColor : const Color(0xFF9E9E9E),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
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
                      color: const Color(0xFF606060),
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

class _DisclaimerModal extends ConsumerStatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const _DisclaimerModal({
    required this.onAccept,
    required this.onCancel,
  });

  @override
  ConsumerState<_DisclaimerModal> createState() => _DisclaimerModalState();
}

class _DisclaimerModalState extends ConsumerState<_DisclaimerModal> {
  bool _isLoading = false;

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
    });

    widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);

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
                color: const Color(0xFFE0E0E0),
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
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FinSquare is only a tool for tracking and collecting payments.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Community members are responsible for all payments.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'By creating or joining an Esusu on FinSquare, you accept these terms and the risk of non-payment by other members.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Use FinSquare with people you trust.',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          // Accept button
          DefaultButton(
            isButtonEnabled: !_isLoading && !state.isLoading,
            onPressed: _handleAccept,
            title: _isLoading || state.isLoading ? 'Creating...' : 'Accept',
            buttonColor: _esusuPrimaryColor,
            height: 54,
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: TextButton(
              onPressed: _isLoading || state.isLoading ? null : widget.onCancel,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF3F3F3),
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
                  color: _isLoading || state.isLoading
                      ? Colors.grey
                      : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
