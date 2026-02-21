import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/widgets/contribution_pin_modal.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);
const Color _borderColor = Color(0xFFE0E0E0);

class ContributionPaymentPage extends ConsumerStatefulWidget {
  final String contributionId;
  final String contributionName;
  final String recipientName;
  final double amount; // For fixed: the fixed amount, For target: the target amount
  final ContributionType contributionType;
  final double? contributedSoFar; // For target type only

  const ContributionPaymentPage({
    super.key,
    required this.contributionId,
    required this.contributionName,
    required this.recipientName,
    required this.amount,
    this.contributionType = ContributionType.fixed,
    this.contributedSoFar,
  });

  @override
  ConsumerState<ContributionPaymentPage> createState() =>
      _ContributionPaymentPageState();
}

class _ContributionPaymentPageState
    extends ConsumerState<ContributionPaymentPage> {
  final _narrationController = TextEditingController();
  String _enteredAmount = '';

  double get _walletBalance {
    final balanceStr = ref.watch(walletBalanceProvider);
    return double.tryParse(balanceStr.replaceAll(',', '')) ?? 0.0;
  }

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0', 'en_US').format(amount);
  }

  String _formatCurrencyWithDecimals(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  double get _currentAmount {
    if (widget.contributionType == ContributionType.fixed) {
      return widget.amount;
    }
    return double.tryParse(_enteredAmount) ?? 0;
  }

  double get _remainingTarget {
    if (widget.contributionType == ContributionType.target) {
      return widget.amount - (widget.contributedSoFar ?? 0);
    }
    return 0;
  }

  void _addDigit(String digit) {
    // Prevent leading zeros
    if (_enteredAmount.isEmpty && digit == '0') return;

    // Limit to reasonable amount (10 digits)
    if (_enteredAmount.length >= 10) return;

    setState(() {
      _enteredAmount += digit;
    });
  }

  void _removeDigit() {
    if (_enteredAmount.isNotEmpty) {
      setState(() {
        _enteredAmount = _enteredAmount.substring(0, _enteredAmount.length - 1);
      });
    }
  }

  void _onConfirm() {
    final amount = _currentAmount;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > _walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show PIN modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContributionPinModal(
        contributionId: widget.contributionId,
        contributionName: widget.contributionName,
        recipientName: widget.recipientName,
        amount: amount,
        narration: _narrationController.text.trim(),
        onSuccess: () {
          context.go(
            AppRoutes.contributionPaymentSuccess,
            extra: {
              'contributionName': widget.contributionName,
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
    // For fixed type, use the original UI
    if (widget.contributionType == ContributionType.fixed) {
      return _buildFixedAmountUI();
    }

    // For flexible and target, use number pad UI
    return _buildFlexibleAmountUI();
  }

  /// UI for Fixed Amount contribution
  Widget _buildFixedAmountUI() {
    final hasEnoughBalance = widget.amount <= _walletBalance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Make Contribution',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contribution Info Card
                    _buildContributionInfoCard(),
                    const SizedBox(height: 24),

                    // Amount Section
                    Text(
                      'Contribution Amount',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _greyTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _greyBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '₦',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: _mainTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCurrencyWithDecimals(widget.amount),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _mainTextColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _contributionLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Fixed',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _contributionPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Wallet Balance
                    _buildWalletBalanceIndicator(hasEnoughBalance),
                    const SizedBox(height: 24),

                    // Narration Field
                    _buildNarrationField(),
                    const SizedBox(height: 24),

                    // Payment Summary
                    _buildPaymentSummary(widget.amount),
                  ],
                ),
              ),
            ),

            // Pay Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: hasEnoughBalance ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasEnoughBalance ? _contributionPrimary : _greyBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Pay ₦${_formatCurrencyWithDecimals(widget.amount)}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: hasEnoughBalance ? Colors.white : _greyTextColor,
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

  /// UI for Flexible/Target Amount contribution with number pad
  Widget _buildFlexibleAmountUI() {
    final amount = _currentAmount;
    final hasAmount = amount > 0;
    final hasEnoughBalance = amount <= _walletBalance;
    final isValid = hasAmount && hasEnoughBalance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Select Amount',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Amount Display Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Target progress info (only for target type)
                  if (widget.contributionType == ContributionType.target) ...[
                    _buildTargetProgressInfo(),
                    const SizedBox(height: 24),
                  ],

                  // Enter Amount label
                  Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _greyTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount Display
                  Text(
                    '₦${_enteredAmount.isEmpty ? '0' : _formatCurrency(double.parse(_enteredAmount))}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),

                  // Wallet balance hint
                  if (hasAmount && !hasEnoughBalance) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Insufficient balance (₦${_formatCurrency(_walletBalance)})',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Number Pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: _buildNumberPad(isValid),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetProgressInfo() {
    final contributed = widget.contributedSoFar ?? 0;
    final target = widget.amount;
    final remaining = _remainingTarget;
    final progress = contributed / target;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _contributionLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contributed',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: _greyTextColor,
                      ),
                    ),
                    Text(
                      '₦${_formatCurrency(contributed)}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: _greyTextColor,
                      ),
                    ),
                    Text(
                      '₦${_formatCurrency(remaining)}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _contributionPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(_contributionPrimary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Target: ₦${_formatCurrency(target)}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _mainTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool canSubmit) {
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
            _buildKeypadButton('submit', isSubmit: true, canSubmit: canSubmit),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(
    String value, {
    bool isBackspace = false,
    bool isSubmit = false,
    bool canSubmit = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          _removeDigit();
        } else if (isSubmit) {
          if (canSubmit) _onConfirm();
        } else {
          _addDigit(value);
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSubmit && canSubmit ? _mainTextColor : _greyBackground,
          shape: BoxShape.circle,
          border: !isSubmit && !isBackspace
              ? Border.all(color: _borderColor, width: 1)
              : null,
        ),
        child: Center(
          child: isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: _mainTextColor,
                  size: 24,
                )
              : isSubmit
                  ? Icon(
                      Icons.check,
                      color: canSubmit ? Colors.white : _greyTextColor,
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

  Widget _buildContributionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _contributionLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _contributionPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                widget.contributionName.isNotEmpty
                    ? widget.contributionName[0].toUpperCase()
                    : 'C',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _contributionPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contributionName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Recipient: ',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: _greyTextColor,
                      ),
                    ),
                    Text(
                      widget.recipientName,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _mainTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalanceIndicator(bool hasEnoughBalance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasEnoughBalance
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: hasEnoughBalance ? const Color(0xFF4CAF50) : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            'Wallet Balance: ',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: _greyTextColor,
            ),
          ),
          Text(
            '₦${_formatCurrencyWithDecimals(_walletBalance)}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasEnoughBalance ? const Color(0xFF4CAF50) : Colors.red,
            ),
          ),
          if (!hasEnoughBalance) ...[
            const Spacer(),
            Text(
              'Insufficient',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNarrationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Narration (Optional)',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _greyTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _narrationController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add a note for this contribution...',
            hintStyle: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: _greyTextColor.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: _contributionPrimary),
            ),
          ),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: _mainTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greyBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Amount', '₦${_formatCurrencyWithDecimals(amount)}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Transaction Fee', '₦0.00'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _borderColor),
          ),
          _buildSummaryRow(
            'Total',
            '₦${_formatCurrencyWithDecimals(amount)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? _mainTextColor : _greyTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _mainTextColor,
          ),
        ),
      ],
    );
  }
}
