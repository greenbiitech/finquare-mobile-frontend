import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _greyIconColor = Color(0xFF595959);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8F5E9);

/// Top Up Page - Selection Screen
///
/// Shows top up method options: Bank Transfer and Card (coming soon)
/// Matching the old Greencard design.
class TopUpPage extends ConsumerStatefulWidget {
  const TopUpPage({super.key});

  @override
  ConsumerState<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends ConsumerState<TopUpPage> {
  bool _showBankDetails = false;
  bool _isLoading = false;
  String? _error;
  String _accountNumber = '';
  String _accountName = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchAccountDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final response = await walletRepo.getBalance();

      if (mounted) {
        setState(() {
          _accountNumber = response.accountNumber;
          _accountName = response.accountName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch account details';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareDetails() {
    SharePlus.instance.share(ShareParams(
      text: 'Account Number: $_accountNumber\nAccount Name: $_accountName\nBank: 9PSB',
    ));
  }

  void _onBankTransferTapped() {
    setState(() {
      _showBankDetails = true;
    });
    _fetchAccountDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_showBankDetails) {
              setState(() {
                _showBankDetails = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Top up',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: _showBankDetails ? _buildBankDetailsView() : _buildMethodSelectionView(),
    );
  }

  /// Method selection view - matching old WalletTopUpScreen design
  Widget _buildMethodSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select method',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _mainTextColor,
            ),
          ),
          const SizedBox(height: 30),
          // Bank Transfer Option
          InkWell(
            onTap: _onBankTransferTapped,
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 25,
                  color: Colors.black,
                ),
                const SizedBox(width: 15),
                Text(
                  'Top up with Bank Transfer',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          // Card Option (Coming Soon)
          Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                size: 25,
                color: Colors.black,
              ),
              const SizedBox(width: 15),
              Text(
                'Top up with Card',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _mainTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: _veryLightPrimaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Coming soon',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bank details view - matching old TopUpBank design
  Widget _buildBankDetailsView() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: _greyTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAccountDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top up with Bank Transfer',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Make transfer into your account below to top up your wallet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 40),
          // Account Information Card - matching old design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _greyBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF303030),
                  ),
                ),
                const SizedBox(height: 20),
                // Account Name Row
                _buildAccountDetailRow(
                  label: 'Account Name',
                  value: _accountName,
                  isLoading: _isLoading,
                  onCopy: () => _copyToClipboard(_accountName, 'Account name'),
                ),
                const SizedBox(height: 20),
                // Account Number Row
                _buildAccountDetailRow(
                  label: 'Account Number',
                  value: _accountNumber,
                  isLoading: _isLoading,
                  onCopy: () => _copyToClipboard(_accountNumber, 'Account number'),
                ),
                const SizedBox(height: 20),
                // Bank Name Row
                _buildAccountDetailRow(
                  label: 'Bank Name',
                  value: '9PSB',
                  isLoading: _isLoading,
                  onCopy: () => _copyToClipboard('9PSB', 'Bank name'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Share Details Button - matching old design
          InkWell(
            onTap: _shareDetails,
            child: Row(
              children: [
                Text(
                  'Share Details',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.share_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Account detail row - matching old design
  Widget _buildAccountDetailRow({
    required String label,
    required String value,
    required bool isLoading,
    required VoidCallback onCopy,
  }) {
    return InkWell(
      onTap: value.isNotEmpty ? onCopy : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _greyIconColor,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 90,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    )
                  : Text(
                      _removePrefix(value),
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF141414),
                      ),
                    ),
            ],
          ),
          Icon(
            Icons.copy_outlined,
            size: 25,
            color: _greyIconColor,
          ),
        ],
      ),
    );
  }

  /// Remove GREENBII/ or FINSQUARE/ prefix from account name if it exists
  String _removePrefix(String value) {
    if (value.startsWith('GREENBII/')) {
      return value.replaceFirst('GREENBII/', '');
    }
    if (value.startsWith('FINSQUARE/')) {
      return value.replaceFirst('FINSQUARE/', '');
    }
    return value;
  }
}
