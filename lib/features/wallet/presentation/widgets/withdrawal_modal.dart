import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/withdraw_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/widgets/withdrawal_pin_modal.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _greyIconColor = Color(0xFF595959);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8E8E8);

/// Show the withdrawal modal bottom sheet
void showWithdrawalModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const WithdrawalModal(),
  );
}

/// Withdrawal Modal - matching old Greencard withdrawal_modal.dart design 100%
///
/// Has three views:
/// 1. Initial view - Set up withdrawal account (shown if no saved account)
/// 2. Add account view - Enter account details and bank
/// 3. Withdraw view - Enter amount and confirm (shown if account exists)
class WithdrawalModal extends ConsumerStatefulWidget {
  const WithdrawalModal({super.key});

  @override
  ConsumerState<WithdrawalModal> createState() => _WithdrawalModalState();
}

class _WithdrawalModalState extends ConsumerState<WithdrawalModal> {
  // View state
  bool _showAddAccountView = false;
  bool _showWithdrawView = false;
  bool _isLoadingAccount = true;

  // Form controllers
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _bankSearchController = TextEditingController();

  // Bank selection and validation state
  Bank? _selectedBank;
  String? _accountHolderName;
  bool _isVerifyingAccount = false;
  bool _isAccountVerified = false;
  String? _accountNumberError;
  String? _amountError;
  Timer? _debounceTimer;

  // Saved withdrawal account
  WithdrawalAccount? _savedAccount;

  /// Calculate transfer fee: ₦10 flat + 0.75% of amount
  double _calculateFee(double amount) {
    const double flatFee = 10.0;
    const double percentageFee = 0.0075; // 0.75%
    return flatFee + (amount * percentageFee);
  }

  /// Get total amount to be debited (amount + fee)
  double _getTotalDebit(double amount) {
    return amount + _calculateFee(amount);
  }

  @override
  void initState() {
    super.initState();
    _accountNumberController.addListener(_debounceVerification);
    _loadSavedWithdrawalAccount();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _bankSearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load saved withdrawal account from backend
  Future<void> _loadSavedWithdrawalAccount() async {
    try {
      final repository = ref.read(walletRepositoryProvider);
      final savedAccount = await repository.getWithdrawalAccount();

      if (savedAccount != null && mounted) {
        setState(() {
          _savedAccount = savedAccount;
          _selectedBank = Bank(
            code: savedAccount.bankCode,
            name: savedAccount.bankName,
          );
          _accountNumberController.text = savedAccount.accountNumber;
          _accountHolderName = savedAccount.accountName;
          _isAccountVerified = true;
          _showWithdrawView = true;
          _isLoadingAccount = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingAccount = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAccount = false;
        });
      }
    }
  }

  /// Save withdrawal account to backend
  Future<void> _saveWithdrawalAccount() async {
    if (_selectedBank == null ||
        _accountHolderName == null ||
        _accountNumberController.text.isEmpty) {
      return;
    }

    try {
      final repository = ref.read(walletRepositoryProvider);
      final request = CreateWithdrawalAccountRequest(
        bankCode: _selectedBank!.code,
        bankName: _selectedBank!.name,
        accountNumber: _accountNumberController.text,
        accountName: _accountHolderName!,
      );

      final savedAccount = await repository.saveWithdrawalAccount(request);

      if (mounted) {
        setState(() {
          _savedAccount = savedAccount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Withdrawal account saved successfully',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save withdrawal account. Please try again.',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _debounceVerification() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _verifyAccountDetails();
    });
  }

  Future<void> _verifyAccountDetails() async {
    final accountNumber = _accountNumberController.text;

    if (accountNumber.length != 10 || _selectedBank == null || _isVerifyingAccount) {
      return;
    }

    setState(() {
      _isVerifyingAccount = true;
      _isAccountVerified = false;
      _accountHolderName = null;
    });

    try {
      await ref.read(withdrawProvider.notifier).resolveAccount(
        accountNumber,
        _selectedBank!.code,
      );

      final state = ref.read(withdrawProvider);
      if (state.isAccountResolved && state.resolvedAccount != null) {
        setState(() {
          _isVerifyingAccount = false;
          _isAccountVerified = true;
          _accountHolderName = state.resolvedAccount!.accountName;
        });
      } else {
        setState(() {
          _isVerifyingAccount = false;
          _isAccountVerified = false;
        });
      }
    } catch (e) {
      setState(() {
        _isVerifyingAccount = false;
        _isAccountVerified = false;
      });
    }
  }

  void _validateAccountNumber(String value) {
    setState(() {
      _accountNumberError = null;
      _isAccountVerified = false;
      _accountHolderName = null;
    });

    if (value.isEmpty) {
      setState(() => _accountNumberError = 'Account number is required');
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      setState(() => _accountNumberError = 'Account number must contain only digits');
      return;
    }

    if (value.length != 10) {
      setState(() => _accountNumberError = 'Account number must be exactly 10 digits');
      return;
    }

    if (_selectedBank != null) {
      _debounceVerification();
    }
  }

  void _validateAmount(String value) {
    if (value.isEmpty) {
      setState(() => _amountError = null);
      return;
    }

    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) {
      setState(() => _amountError = 'Amount must contain only numbers');
      return;
    }

    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      setState(() => _amountError = 'Invalid amount');
      return;
    }

    if (amount < 100) {
      setState(() => _amountError = 'Minimum withdrawal amount is ₦100');
      return;
    }

    // Check wallet balance including fees
    final walletState = ref.read(walletProvider);
    final walletBalance = double.tryParse(walletState.balance) ?? 0.0;
    final totalDebit = _getTotalDebit(amount);

    if (totalDebit > walletBalance) {
      final maxWithdrawable = walletBalance - _calculateFee(walletBalance * 0.99);
      setState(() => _amountError = 'Insufficient balance for amount + fees. Max: ₦${maxWithdrawable.toStringAsFixed(2)}');
      return;
    }

    setState(() => _amountError = null);
  }

  bool _isWithdrawEnabled() {
    if (_amountError != null || _amountController.text.isEmpty) return false;

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || amount < 100) return false;

    if (!_isAccountVerified || _accountHolderName == null) return false;
    if (_selectedBank == null) return false;

    final walletState = ref.read(walletProvider);
    final walletBalance = double.tryParse(walletState.balance) ?? 0.0;
    final totalDebit = _getTotalDebit(amount);
    if (totalDebit > walletBalance) return false;

    return true;
  }

  void _initiateWithdrawal() {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || _selectedBank == null || _accountHolderName == null) return;

    // Close current modal first
    Navigator.pop(context);

    // Show PIN entry modal (matching old design)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => WithdrawalPinModal(
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountHolderName!,
        bankName: _selectedBank!.name,
        bankCode: _selectedBank!.code,
        amount: amount,
      ),
    ).then((success) {
      if (success == true && mounted) {
        // Navigate to success page
        context.push(AppRoutes.withdrawalSuccess);
      }
    });
  }

  void _showBankSelectionModal() {
    _bankSearchController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBankSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final withdrawState = ref.watch(withdrawProvider);

    // Listen for errors
    ref.listen(withdrawProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: _isLoadingAccount
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Home Bar
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
                // Horizontal Divider
                Container(height: 1, color: const Color(0xFFF4F4F4)),
                const SizedBox(height: 16),
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdraw from Wallet',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Withdraw your funds instantly to your specified account',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Dynamic Content
                Expanded(
                  child: _showWithdrawView
                      ? _buildWithdrawView(withdrawState)
                      : _showAddAccountView
                          ? _buildAddAccountView()
                          : _buildInitialView(),
                ),
              ],
            ),
    );
  }

  /// Initial view - Set up withdrawal account
  Widget _buildInitialView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Icon Section - matching old design
          Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(70),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svgs/u_money-withdraw.svg',
                width: 51,
                height: 51,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Text Section
          Text(
            'Set up withdrawal account',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _mainTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect a bank account to instantly withdraw your funds',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _greyTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Add Account Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => _showAddAccountView = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              child: Text(
                'Add Withdrawal account',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Add account view - Enter account details
  Widget _buildAddAccountView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Account Number Input
          Text(
            'Account Number',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: _greyIconColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: _validateAccountNumber,
            decoration: InputDecoration(
              hintText: 'Enter account number',
              errorText: _accountNumberError,
              counterText: '',
              filled: true,
              fillColor: _greyBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          // Bank Selection
          Text(
            'Bank',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: _greyIconColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showBankSelectionModal,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _greyBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedBank?.name ?? 'Select',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: _greyIconColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF595959),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Account Verification Status
          if (_isVerifyingAccount)
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _greyBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Verifying account...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: _greyIconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (_isAccountVerified && _accountHolderName != null)
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _veryLightPrimaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _accountHolderName!,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: _greyIconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Add Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isAccountVerified
                  ? () async {
                      // Save withdrawal account to backend
                      await _saveWithdrawalAccount();
                      if (mounted) {
                        setState(() {
                          _showAddAccountView = false;
                          _showWithdrawView = true;
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAccountVerified ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Withdraw view - Enter amount and confirm
  Widget _buildWithdrawView(WithdrawState withdrawState) {
    final walletState = ref.watch(walletProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: _validateAmount,
            decoration: InputDecoration(
              labelText: 'Amount To Withdraw',
              hintText: 'Enter amount',
              prefixText: '₦ ',
              prefixStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              errorText: _amountError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Available Balance Display
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Available Balance: ₦${walletState.balance}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          // Fee Breakdown (only show when amount is entered)
          Builder(
            builder: (context) {
              final amount = double.tryParse(
                _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
              );
              if (amount == null || amount < 100) {
                return const SizedBox(height: 24);
              }
              final fee = _calculateFee(amount);
              final totalDebit = _getTotalDebit(amount);
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), // Light amber background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount to receive:',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '₦${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transfer fee:',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '₦${fee.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total debit:',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '₦${totalDebit.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Destination Account Label
          Text(
            'Destination Account',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: _greyIconColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Destination Account Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _veryLightPrimaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBank?.name ?? 'Bank Name',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _greyIconColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _accountNumberController.text,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _greyIconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 39,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _veryLightPrimaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.account_balance,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Change Text
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => setState(() {
                  _showWithdrawView = false;
                  _showAddAccountView = true;
                  // Reset for new account entry
                  _accountNumberController.clear();
                  _selectedBank = null;
                  _accountHolderName = null;
                  _isAccountVerified = false;
                }),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: _greyIconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Withdraw Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: withdrawState.isLoading || !_isWithdrawEnabled()
                  ? null
                  : _initiateWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWithdrawEnabled() ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              child: withdrawState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Withdraw',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Bank selection bottom sheet
  Widget _buildBankSelectionSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Bank',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _bankSearchController,
                  onChanged: (query) => setModalState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search banks...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _bankSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _bankSearchController.clear();
                              setModalState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Bank List - Use Consumer to properly watch provider changes
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final bankListAsync = ref.watch(bankListProvider);
                    return bankListAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                            const SizedBox(height: 16),
                            const Text('Unable to load banks'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(bankListProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (banks) {
                        final searchQuery = _bankSearchController.text.toLowerCase();
                        final filteredBanks = searchQuery.isEmpty
                            ? banks
                            : banks.where((bank) => bank.name.toLowerCase().contains(searchQuery)).toList();

                        if (filteredBanks.isEmpty && searchQuery.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No banks found'),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredBanks.length,
                          itemBuilder: (context, index) {
                            final bank = filteredBanks[index];
                            return ListTile(
                              title: Text(
                                bank.name,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedBank = bank;
                                  _isAccountVerified = false;
                                  _accountHolderName = null;
                                });
                                Navigator.pop(context);
                                if (_accountNumberController.text.length == 10) {
                                  _debounceVerification();
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
