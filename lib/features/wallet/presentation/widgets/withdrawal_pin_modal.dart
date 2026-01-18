import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_page.dart';

/// Custom PIN keypad modal for withdrawal - matching old Greencard design
class WithdrawalPinModal extends ConsumerStatefulWidget {
  final String accountNumber;
  final String accountName;
  final String bankName;
  final String bankCode;
  final double amount;

  const WithdrawalPinModal({
    super.key,
    required this.accountNumber,
    required this.accountName,
    required this.bankName,
    required this.bankCode,
    required this.amount,
  });

  @override
  ConsumerState<WithdrawalPinModal> createState() => _WithdrawalPinModalState();
}

class _WithdrawalPinModalState extends ConsumerState<WithdrawalPinModal> {
  String _pin = '';
  bool _isProcessing = false;
  String? _error;
  int _failedAttempts = 0;
  static const int _maxAttempts = 3;

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = null;
      });
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = null;
      });
    }
  }

  Future<void> _processWithdrawal() async {
    if (_pin.length != 4 || _isProcessing) return;

    // Check if locked out
    if (_failedAttempts >= _maxAttempts) {
      setState(() {
        _error = 'Too many failed attempts. Please try again later.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final repository = ref.read(walletRepositoryProvider);
      final response = await repository.withdraw(
        amount: widget.amount,
        destinationAccountNumber: widget.accountNumber,
        destinationBankCode: widget.bankCode,
        destinationAccountName: widget.accountName,
        narration: 'Withdrawal to ${widget.bankName} - ${widget.accountNumber}',
        transactionPin: _pin,
      );

      if (!mounted) return;

      if (response.success) {
        // Refresh wallet balance and transaction history
        ref.read(walletProvider.notifier).refreshBalance();
        ref.invalidate(transactionHistoryProvider);

        // Close PIN modal and navigate to success page
        Navigator.of(context).pop(true);
      } else {
        _failedAttempts++;
        final remainingAttempts = _maxAttempts - _failedAttempts;
        setState(() {
          _isProcessing = false;
          _error = remainingAttempts > 0
              ? '${response.message}. $remainingAttempts attempt(s) remaining.'
              : 'Too many failed attempts. Please try again later.';
          _pin = '';
        });

        // Close modal if locked out
        if (_failedAttempts >= _maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString();
      final isTimeoutError = errorMessage.contains('timeout') ||
          errorMessage.contains('aborted') ||
          errorMessage.contains('taking longer');

      if (isTimeoutError) {
        // Don't assume success on timeout - show pending message
        ref.read(walletProvider.notifier).refreshBalance();
        ref.invalidate(transactionHistoryProvider);
        setState(() {
          _isProcessing = false;
        });

        // Show pending dialog and close
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Transaction Processing'),
              content: const Text(
                'Your withdrawal is being processed. Please check your balance and transaction history shortly.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Check if it's a PIN error
        final isPinError = errorMessage.toLowerCase().contains('pin') ||
            errorMessage.toLowerCase().contains('incorrect') ||
            errorMessage.toLowerCase().contains('invalid');

        if (isPinError) {
          _failedAttempts++;
        }

        final remainingAttempts = _maxAttempts - _failedAttempts;
        setState(() {
          _isProcessing = false;
          _error = _failedAttempts >= _maxAttempts
              ? 'Too many failed attempts. Please try again later.'
              : isPinError && remainingAttempts > 0
                  ? 'Invalid PIN. $remainingAttempts attempt(s) remaining.'
                  : 'Withdrawal failed. Please try again.';
          _pin = '';
        });

        // Close modal if locked out
        if (_failedAttempts >= _maxAttempts) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop(false);
        }
      }
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Forgot PIN?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'To reset your transaction PIN, please go to Settings > Security > Reset Transaction PIN.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Container(
                width: 51,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  const SizedBox(height: 42),

                  // Title and PIN Display
                  SizedBox(
                    width: 225,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter transaction Pin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF282637),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // PIN Display
                        Row(
                          children: List.generate(4, (index) {
                            final isFilled = index < _pin.length;
                            return Container(
                              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isFilled
                                    ? const Color(0xFFE8E8E8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE8E8E8),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: isFilled
                                    ? Text(
                                        '*',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF5B5966),
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),

                        // Error message
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),

                        // Forgot PIN link
                        GestureDetector(
                          onTap: _showForgotPinDialog,
                          child: Text(
                            'Forgot PIN?',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 42),

                  // Processing indicator
                  if (_isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Processing withdrawal...',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Keypad
                  SizedBox(
                    width: 310,
                    child: Wrap(
                      spacing: 68,
                      runSpacing: 20,
                      children: [
                        // Numbers 1-9
                        for (int i = 1; i <= 9; i++)
                          _buildKeypadButton(
                            text: i.toString(),
                            onTap: _isProcessing ? null : () => _addDigit(i.toString()),
                          ),

                        // Delete button
                        _buildKeypadButton(
                          icon: Icons.backspace_outlined,
                          onTap: _isProcessing ? null : _removeDigit,
                        ),

                        // 0
                        _buildKeypadButton(
                          text: '0',
                          onTap: _isProcessing ? null : () => _addDigit('0'),
                        ),

                        // Confirm button
                        _buildKeypadButton(
                          icon: Icons.check,
                          backgroundColor: _pin.length == 4 && !_isProcessing
                              ? AppColors.primary
                              : Colors.grey,
                          iconColor: Colors.white,
                          onTap: _pin.length == 4 && !_isProcessing
                              ? _processWithdrawal
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom spacing
                  const SizedBox(height: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    Color backgroundColor = const Color(0xFFF3F3F3),
    Color textColor = const Color(0xFF333333),
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(37.5),
        ),
        child: Center(
          child: text != null
              ? Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                )
              : Icon(icon, size: 24, color: iconColor ?? textColor),
        ),
      ),
    );
  }
}
