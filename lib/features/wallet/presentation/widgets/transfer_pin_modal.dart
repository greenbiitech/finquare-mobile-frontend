import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/internal_transfer_provider.dart';

// Colors
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);

/// Transfer PIN Modal - Screen 3
/// Custom PIN keypad modal for wallet-to-wallet transfer
class TransferPinModal extends ConsumerStatefulWidget {
  final String recipientUserId;
  final String recipientName;
  final double amount;
  final String? narration;
  final VoidCallback onSuccess;

  const TransferPinModal({
    super.key,
    required this.recipientUserId,
    required this.recipientName,
    required this.amount,
    this.narration,
    required this.onSuccess,
  });

  @override
  ConsumerState<TransferPinModal> createState() => _TransferPinModalState();
}

class _TransferPinModalState extends ConsumerState<TransferPinModal> {
  String _pin = '';
  bool _isProcessing = false;
  String? _error;

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

  Future<void> _processTransfer() async {
    if (_pin.length != 4 || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final (success, errorMessage) = await ref.read(internalTransferControllerProvider.notifier).transfer(
      recipientUserId: widget.recipientUserId,
      amount: widget.amount,
      narration: widget.narration,
      transactionPin: _pin,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      setState(() {
        _isProcessing = false;
        _error = errorMessage ?? 'Transfer failed';
        _pin = ''; // Clear PIN on error
      });
    }
  }

  void _onForgotPin() {
    // TODO: Navigate to forgot PIN flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot PIN flow coming soon')),
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
              const SizedBox(height: 24),

              // PIN Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  final isCurrentDigit = index == _pin.length - 1 && _pin.isNotEmpty;

                  return Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: _greyBackground,
                      borderRadius: BorderRadius.circular(8),
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
                                    color: _greyTextColor,
                                  ),
                                )
                              : Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: _mainTextColor,
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
                onPressed: _onForgotPin,
                child: Text(
                  'Forgot pin',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _greyTextColor,
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

  Widget _buildKeypadButton(String value, {bool isBackspace = false, bool isSubmit = false}) {
    final isEnabled = !_isProcessing;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              if (isBackspace) {
                _removeDigit();
              } else if (isSubmit) {
                _processTransfer();
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
              ? _mainTextColor
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
                          color: _pin.length == 4 ? Colors.white : _greyTextColor,
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
