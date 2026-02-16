import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

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

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    // Simulate API call delay (dummy implementation)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // For dummy implementation, accept PIN "1234" as valid
    if (_pin == '1234') {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      setState(() {
        _isProcessing = false;
        _error = 'Invalid PIN. Try 1234 for demo.';
        _pin = '';
      });
    }
  }

  void _onForgotPin() {
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
                onPressed: _onForgotPin,
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
