import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/internal_transfer_provider.dart';

// Colors
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);
const Color _borderColor = Color(0xFFE0E0E0);
const Color _successGreen = Color(0xFF4CAF50);
const Color _successBgColor = Color(0xFFE8F5E9);

/// Wallet Transfer Page - Screen 1
/// User enters email or phone number to find recipient
class WalletTransferPage extends ConsumerStatefulWidget {
  const WalletTransferPage({super.key});

  @override
  ConsumerState<WalletTransferPage> createState() => _WalletTransferPageState();
}

class _WalletTransferPageState extends ConsumerState<WalletTransferPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Validates if input is a valid Nigerian phone number (11 digits starting with 07/08/09)
  bool _isValidNigerianPhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length != 11) return false;
    return RegExp(r'^0[789]\d{9}$').hasMatch(cleaned);
  }

  /// Validates if input is a valid 10-digit account number
  bool _isValidAccountNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length != 10) return false;
    return RegExp(r'^\d{10}$').hasMatch(cleaned);
  }

  /// Returns true if input is valid (either valid phone or valid account number)
  bool _isValidInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return _isValidNigerianPhone(trimmed) || _isValidAccountNumber(trimmed);
  }

  void _onInputChanged(String value) {
    // Clear previous result when input changes
    final state = ref.read(recipientControllerProvider);
    if (state.isFound || state.error != null) {
      ref.read(recipientControllerProvider.notifier).reset();
    }
    setState(() {}); // Trigger rebuild to update button state
  }

  Future<void> _searchRecipient() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    await ref.read(recipientControllerProvider.notifier).lookupRecipient(input);
  }

  void _onNext() {
    final state = ref.read(recipientControllerProvider);
    final recipient = state.recipient;
    if (recipient == null || recipient.userId == null) return;

    context.push(
      AppRoutes.walletTransferAmount,
      extra: {
        'recipientUserId': recipient.userId,
        'recipientName': recipient.fullName ?? 'Unknown',
        'recipientMaskedEmail': recipient.maskedEmail,
        'recipientAvatar': recipient.profilePhoto,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipientState = ref.watch(recipientControllerProvider);
    final hasRecipient = recipientState.isFound;
    final isSearching = recipientState.isSearching;
    final error = recipientState.error;
    final recipient = recipientState.recipient;

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

              // Phone/Account Number Input
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                onChanged: _onInputChanged,
                onSubmitted: (_) => _searchRecipient(),
                decoration: InputDecoration(
                  hintText: 'Phone Number or Account Number',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: _greyTextColor,
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
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 16),

              // Recipient Result Card (shown when found)
              if (hasRecipient && recipient != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _successBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _successGreen, width: 1),
                  ),
                  child: Row(
                    children: [
                      // Profile photo or avatar
                      if (recipient.profilePhoto != null)
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(recipient.profilePhoto!),
                        )
                      else
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _successGreen.withValues(alpha: 0.2),
                          child: Text(
                            (recipient.fullName ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: _successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipient.fullName ?? 'Unknown',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _mainTextColor,
                              ),
                            ),
                            if (recipient.maskedEmail != null)
                              Text(
                                recipient.maskedEmail!,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  color: _greyTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: _successGreen,
                        size: 24,
                      ),
                    ],
                  ),
                ),

              // Error Message
              if (error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _greyBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _greyTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transfers only happen between FinSquare users, and do not work with other banks. Make sure the recipient has a FinSquare account.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: _greyTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Search/Next Button
              Builder(
                builder: (context) {
                  final isValidInput = _isValidInput(_controller.text);
                  final isEnabled = isValidInput && !isSearching;
                  final showNext = hasRecipient;

                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isEnabled
                          ? (showNext ? _onNext : _searchRecipient)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnabled ? _mainTextColor : _greyBackground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isSearching
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              showNext ? 'Next' : 'Search',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isEnabled ? Colors.white : _greyTextColor,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
