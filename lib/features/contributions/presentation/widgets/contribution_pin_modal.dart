import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);

/// Contribution PIN Modal
/// Custom PIN keypad modal for contribution payments
class ContributionPinModal extends ConsumerStatefulWidget {
  final String contributionId;
  final String contributionName;
  final String recipientName;
  final double amount;
  final String? narration;
  final VoidCallback onSuccess;

  const ContributionPinModal({
    super.key,
    required this.contributionId,
    required this.contributionName,
    required this.recipientName,
    required this.amount,
    this.narration,
    required this.onSuccess,
  });

  @override
  ConsumerState<ContributionPinModal> createState() =>
      _ContributionPinModalState();
}

class _ContributionPinModalState extends ConsumerState<ContributionPinModal> {
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

  Future<void> _processPayment() async {
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
      final repository = ref.read(contributionsRepositoryProvider);
      final response = await repository.makeContribution(
        widget.contributionId,
        amount: widget.amount,
        transactionPin: _pin,
        narration: widget.narration,
      );

      if (!mounted) return;

      if (response.success) {
        // Refresh wallet balance
        ref.read(walletProvider.notifier).refreshBalance();

        // Refresh contribution list
        ref.read(contributionListRefreshTriggerProvider.notifier).state++;

        Navigator.of(context).pop();
        widget.onSuccess();
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
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString();

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
                : _extractErrorMessage(errorMessage);
        _pin = '';
      });

      // Close modal if locked out
      if (_failedAttempts >= _maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  String _extractErrorMessage(String error) {
    // Try to extract meaningful message from error
    if (error.contains('Exception:')) {
      return error.split('Exception:').last.trim();
    }
    if (error.contains('message:')) {
      final match = RegExp(r'message:\s*([^,}]+)').firstMatch(error);
      if (match != null) return match.group(1)?.trim() ?? 'Payment failed';
    }
    return 'Payment failed. Please try again.';
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
                color: _contributionPrimary,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _greyTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Enter transaction Pin',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle with contribution info
              Text(
                'Contributing to ${widget.contributionName}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  color: _greyTextColor,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  final isCurrentDigit =
                      index == _pin.length - 1 && _pin.isNotEmpty;

                  return Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: _contributionLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFilled
                            ? _contributionPrimary
                            : _contributionLight,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isFilled
                          ? isCurrentDigit
                              ? Text(
                                  _pin[index],
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: _contributionPrimary,
                                  ),
                                )
                              : Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: _contributionPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Forgot PIN
              TextButton(
                onPressed: _showForgotPinDialog,
                child: Text(
                  'Forgot pin',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _contributionPrimary,
                  ),
                ),
              ),

              // Error Message
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Processing indicator
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _contributionPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Processing payment...',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: _greyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Number Pad
              _buildNumberPad(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('1'),
            _buildKeypadButton('2'),
            _buildKeypadButton('3'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('4'),
            _buildKeypadButton('5'),
            _buildKeypadButton('6'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('7'),
            _buildKeypadButton('8'),
            _buildKeypadButton('9'),
          ],
        ),
        const SizedBox(height: 16),
        // Row 4: Backspace, 0, Submit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton('backspace', isBackspace: true),
            _buildKeypadButton('0'),
            _buildKeypadButton('submit', isSubmit: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String value,
      {bool isBackspace = false, bool isSubmit = false}) {
    final isEnabled = !_isProcessing;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              if (isBackspace) {
                _removeDigit();
              } else if (isSubmit) {
                _processPayment();
              } else {
                _addDigit(value);
              }
            }
          : null,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSubmit && _pin.length == 4
              ? _contributionPrimary
              : _greyBackground,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: _isProcessing && isSubmit
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : isBackspace
                  ? Icon(
                      Icons.backspace_outlined,
                      color: _mainTextColor,
                      size: 24,
                    )
                  : isSubmit
                      ? Icon(
                          Icons.check,
                          color:
                              _pin.length == 4 ? Colors.white : _greyTextColor,
                          size: 28,
                        )
                      : Text(
                          value,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: _mainTextColor,
                          ),
                        ),
        ),
      ),
    );
  }
}
