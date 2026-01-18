import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/withdraw_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _greyIconColor = Color(0xFF595959);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8F5E9);

/// Withdraw Page - matching old Greencard withdrawal_modal.dart design
///
/// Has three views:
/// 1. Initial view - Set up withdrawal account
/// 2. Add account view - Enter account details and bank
/// 3. Withdraw view - Enter amount and confirm
class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  // View state
  bool _showAddAccountView = false;
  bool _showWithdrawView = false;

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

  @override
  void initState() {
    super.initState();
    _accountNumberController.addListener(_debounceVerification);
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _bankSearchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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

    // Check wallet balance
    final walletState = ref.read(walletProvider);
    final walletBalance = double.tryParse(walletState.balance) ?? 0.0;

    if (amount > walletBalance) {
      setState(() => _amountError = 'Insufficient balance. Available: ₦${walletBalance.toStringAsFixed(2)}');
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
    if (amount > walletBalance) return false;

    return true;
  }

  Future<void> _initiateWithdrawal() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null || _selectedBank == null || _accountHolderName == null) return;

    // Show PIN entry dialog
    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return;

    final success = await ref.read(withdrawProvider.notifier).withdraw(
      amount: amount,
      destinationAccountNumber: _accountNumberController.text,
      destinationBankCode: _selectedBank!.code,
      destinationAccountName: _accountHolderName!,
      narration: 'Withdrawal to ${_selectedBank!.name}',
      transactionPin: pin,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Withdrawal successful'),
          backgroundColor: AppColors.primary,
        ),
      );
      // Refresh wallet balance
      ref.read(walletProvider.notifier).refreshBalance();
      Navigator.pop(context);
    }
  }

  Future<String?> _showPinDialog() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Transaction PIN'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'PIN'),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          onChanged: (value) => pin = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pin),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_showWithdrawView) {
                            setState(() {
                              _showWithdrawView = false;
                              _showAddAccountView = true;
                            });
                          } else if (_showAddAccountView) {
                            setState(() => _showAddAccountView = false);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Withdraw from Wallet',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      'Withdraw your funds instantly to your specified account',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
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
            child: const Center(
              child: Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 48,
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
                  ? () => setState(() {
                        _showAddAccountView = false;
                        _showWithdrawView = true;
                      })
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
          const SizedBox(height: 40),
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
    final bankListAsync = ref.watch(bankListProvider);

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
              // Bank List
              Expanded(
                child: bankListAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text('Unable to load banks'),
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
                            Text('No banks found'),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
