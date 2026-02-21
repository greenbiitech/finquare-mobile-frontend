import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/overlay_loader_service.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';
import 'package:intl/intl.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

/// Admin slot selection page during Esusu creation flow
/// This is shown when admin is participating AND payout order is FCFS
class AdminSlotSelectionPage extends ConsumerStatefulWidget {
  const AdminSlotSelectionPage({super.key});

  @override
  ConsumerState<AdminSlotSelectionPage> createState() =>
      _AdminSlotSelectionPageState();
}

class _AdminSlotSelectionPageState
    extends ConsumerState<AdminSlotSelectionPage> {
  int? _selectedSlot;
  bool _isSubmitting = false;

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '₦${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMMM').format(date);
    final year = date.year;
    return '$day$suffix $month $year';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedSlot == null) return;

    setState(() => _isSubmitting = true);

    // Save admin's selected slot
    ref.read(esusuCreationProvider.notifier).setAdminSelectedSlot(_selectedSlot);

    // Create the Esusu
    ref.showLoading('Creating Esusu...');

    final success =
        await ref.read(esusuCreationProvider.notifier).createEsusu();

    ref.hideLoading();

    if (success && mounted) {
      context.push(AppRoutes.esusuSuccess);
    } else if (mounted) {
      setState(() => _isSubmitting = false);
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
    final totalSlots = state.numberOfParticipants ?? 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Pick Your Slot',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    _buildInfoCard(state),
                    const SizedBox(height: 24),

                    // Pick your slot header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pick your slot',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          '$totalSlots Available',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8E8E8E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      'As the creator, you get to pick your payout slot first.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: const Color(0xFF8E8E8E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slots Grid
                    _buildSlotsGrid(totalSlots),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _selectedSlot != null && !_isSubmitting
                          ? _handleConfirm
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _esusuPrimaryColor,
                    disabledBackgroundColor: const Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm & Create Esusu',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedSlot != null
                                ? Colors.white
                                : const Color(0xFFBDBDBD),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(EsusuCreationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBDAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.esusuName,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          if (state.description != null && state.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              state.description!,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E8E8E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Purple divider
          const SizedBox(height: 16),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: _esusuPrimaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          // Details grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Contribution Amount',
                  _formatCurrency(state.contributionAmount ?? 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Frequency',
                  state.frequency?.displayName ?? 'Monthly',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Target Members',
                  (state.numberOfParticipants ?? 0).toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  'Start date',
                  state.collectionDate != null
                      ? _formatDate(state.collectionDate!)
                      : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E8E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotsGrid(int totalSlots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        final slotNumber = index + 1;
        final isSelected = _selectedSlot == slotNumber;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slotNumber;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _esusuPrimaryColor.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _esusuPrimaryColor
                    : const Color(0xFF333333),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                slotNumber.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? _esusuPrimaryColor
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
