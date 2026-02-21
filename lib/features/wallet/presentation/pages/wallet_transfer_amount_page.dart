import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/widgets/transfer_pin_modal.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/internal_transfer_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';

// Colors
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);
const Color _borderColor = Color(0xFFE0E0E0);

/// Wallet Transfer Amount Page - Screen 2
/// User enters amount and narration for the transfer
class WalletTransferAmountPage extends ConsumerStatefulWidget {
  final String recipientUserId;
  final String recipientName;
  final String? recipientMaskedEmail;
  final String? recipientAvatar;

  const WalletTransferAmountPage({
    super.key,
    required this.recipientUserId,
    required this.recipientName,
    this.recipientMaskedEmail,
    this.recipientAvatar,
  });

  @override
  ConsumerState<WalletTransferAmountPage> createState() => _WalletTransferAmountPageState();
}

class _WalletTransferAmountPageState extends ConsumerState<WalletTransferAmountPage> {
  final _amountController = TextEditingController();
  final _narrationController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum transfer amount is ₦100')),
      );
      return;
    }

    // Check if amount exceeds balance
    final balance = ref.read(walletBalanceProvider);
    final balanceValue = double.tryParse(balance) ?? 0.0;
    if (amount > balanceValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    // Show PIN modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferPinModal(
        recipientUserId: widget.recipientUserId,
        recipientName: widget.recipientName,
        amount: amount,
        narration: _narrationController.text.trim(),
        onSuccess: () {
          // Navigate to success page
          context.go(
            AppRoutes.transferSuccess,
            extra: {
              'recipientName': widget.recipientName,
              'amount': amount,
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAmount = _amountController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Transfer',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Recipient Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _greyBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _greyTextColor.withValues(alpha: 0.2),
                      backgroundImage: widget.recipientAvatar != null
                          ? NetworkImage(widget.recipientAvatar!)
                          : null,
                      child: widget.recipientAvatar == null
                          ? Text(
                              widget.recipientName.isNotEmpty
                                  ? widget.recipientName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _mainTextColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Name and Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.recipientName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _mainTextColor,
                            ),
                          ),
                          if (widget.recipientMaskedEmail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.recipientMaskedEmail!,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                color: _greyTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _greyTextColor,
                  ),
                  prefixText: '\u20A6 ',
                  prefixStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    color: _mainTextColor,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 6),

              // Available Balance hint
              Builder(
                builder: (context) {
                  final balance = ref.watch(walletBalanceProvider);
                  final balanceValue = double.tryParse(balance) ?? 0.0;
                  final formattedBalance = NumberFormat('#,##0.00', 'en_US').format(balanceValue);

                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Available: ₦$formattedBalance',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: _greyTextColor.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Narration Field
              TextField(
                controller: _narrationController,
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: 'Narration',
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _greyTextColor,
                  ),
                  hintText: 'whats this for?',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _greyTextColor.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: _mainTextColor,
                ),
              ),

              const Spacer(),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: hasAmount ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasAmount ? _mainTextColor : _greyBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasAmount ? Colors.white : _greyTextColor,
                    ),
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
}
