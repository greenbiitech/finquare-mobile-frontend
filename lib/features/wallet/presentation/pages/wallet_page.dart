import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/wallet/data/wallet_repository.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/widgets/animated_balance_text.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/widgets/withdrawal_modal.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/activate_community_wallet_page.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _greyIconColor = Color(0xFF8E8E8E);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8E8E8);
const Color _inactiveTabBackground = Color(0xFFF3F3F3);
const Color _inactiveTabTextColor = Color(0xFF8E8E8E);

/// Wallet tab enum
enum WalletTab { personal, community }

/// Provider for transaction history
final transactionHistoryProvider = FutureProvider.autoDispose<List<WalletTransaction>>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  try {
    final response = await repository.getTransactionHistory(limit: 20);
    return response.transactions;
  } catch (e) {
    return [];
  }
});

/// Provider for community wallet status (family provider to accept communityId)
final communityWalletStatusProvider = FutureProvider.autoDispose.family<GetCommunityWalletResponse?, String>((ref, communityId) async {
  if (communityId.isEmpty) return null;
  final repository = ref.watch(walletRepositoryProvider);
  try {
    return await repository.getCommunityWallet(communityId);
  } catch (e) {
    return null;
  }
});

/// Polling interval for balance refresh while on wallet page
/// Using 30 seconds to avoid overwhelming the 9PSB API
const Duration _pollingInterval = Duration(seconds: 30);

/// Wallet Page
///
/// Shows wallet balance and action buttons (Top Up, Withdraw).
/// Balance is fetched from the centralized WalletProvider.
/// Uses pull-to-refresh for manual updates.
/// Polls for fresh balance every 30 seconds while page is active.
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  bool _isBalanceVisible = true;
  Timer? _pollingTimer;
  WalletTab _selectedTab = WalletTab.personal;

  @override
  void initState() {
    super.initState();
    // Fetch balance when page opens and start polling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBalanceIfNeeded();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Start polling for balance updates every 30 seconds
  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      // Silent refresh - no loading indicator
      ref.read(walletProvider.notifier).refreshBalanceSilently();
    });
  }

  /// Stop polling when leaving the page
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _fetchBalanceIfNeeded() {
    final walletState = ref.read(walletProvider);
    // Always fetch fresh when opening wallet page
    if (walletState.isFirstLoad || walletState.isStale) {
      ref.read(walletProvider.notifier).fetchBalance();
    } else {
      // Silent refresh in background
      ref.read(walletProvider.notifier).refreshBalanceSilently();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(walletProvider.notifier).refreshBalance();
    ref.invalidate(transactionHistoryProvider);
  }

  void _onTopUp() {
    context.push(AppRoutes.topUp);
  }

  void _onWithdraw() {
    showWithdrawalModal(context);
  }

  /// Check if community tab should be visible
  /// Only show for Admin/Co-Admin and not for default FinSquare Community
  bool _shouldShowCommunityTab(CommunityState communityState) {
    final activeCommunity = communityState.activeCommunity;
    if (activeCommunity == null) return false;

    // Don't show for default FinSquare Community (everyone is just a member)
    if (activeCommunity.isDefault) return false;

    // Only show for Admin or Co-Admin
    return activeCommunity.hasAdminPrivileges;
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final communityState = ref.watch(communityProvider);
    final showCommunityTab = _shouldShowCommunityTab(communityState);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title - matching old design
                  Text(
                    'Wallet',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Wallet Tabs
                  _buildWalletTabs(showCommunityTab),
                  const SizedBox(height: 18),
                  // Content based on selected tab
                  if (_selectedTab == WalletTab.personal) ...[
                    // Personal Wallet Content
                    // Wallet Balance Container - matching old design exactly
                    walletState.isFirstLoad && walletState.isLoading
                        ? _buildWalletBalanceShimmer()
                        : _buildWalletBalanceContainer(walletState),
                    const SizedBox(height: 20),
                    // Transactions Header - matching old design
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _mainTextColor,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // TODO: Navigate to all transactions
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Transaction List
                    _buildTransactionList(),
                  ] else ...[
                    // Community Wallet Content
                    _buildCommunityWalletContent(communityState),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build wallet tabs row
  Widget _buildWalletTabs(bool showCommunityTab) {
    return Row(
      children: [
        // Personal Wallet Tab
        _buildTab(
          label: 'Personal wallet',
          isSelected: _selectedTab == WalletTab.personal,
          onTap: () {
            setState(() {
              _selectedTab = WalletTab.personal;
            });
          },
        ),
        // Community Tab (only if Admin/Co-Admin and not default community)
        if (showCommunityTab) ...[
          const SizedBox(width: 20),
          _buildTab(
            label: 'Community wallet',
            isSelected: _selectedTab == WalletTab.community,
            onTap: () {
              setState(() {
                _selectedTab = WalletTab.community;
              });
            },
          ),
        ],
      ],
    );
  }

  /// Build individual tab widget
  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? _veryLightPrimaryColor : _inactiveTabBackground,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF4A4A4A) : _inactiveTabTextColor,
          ),
        ),
      ),
    );
  }

  /// Build community wallet content
  Widget _buildCommunityWalletContent(CommunityState communityState) {
    final communityId = communityState.activeCommunity?.id ?? '';
    final walletStatusAsync = ref.watch(communityWalletStatusProvider(communityId));

    return walletStatusAsync.when(
      loading: () => _buildCommunityWalletShimmer(),
      error: (error, stack) => _buildCommunityWalletError(),
      data: (walletResponse) {
        if (walletResponse == null || !walletResponse.hasWallet) {
          return const ActivateCommunityWalletPage();
        }
        // Show wallet dashboard
        return _buildCommunityWalletDashboard(walletResponse);
      },
    );
  }

  /// Shimmer loading for community wallet
  Widget _buildCommunityWalletShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Error state for community wallet
  Widget _buildCommunityWalletError() {
    final communityState = ref.read(communityProvider);
    final communityId = communityState.activeCommunity?.id ?? '';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(
            'Failed to load wallet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(communityWalletStatusProvider(communityId)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Build community wallet dashboard when wallet exists
  Widget _buildCommunityWalletDashboard(GetCommunityWalletResponse walletResponse) {
    final wallet = walletResponse.wallet!;
    final balance = wallet.balanceAsDouble;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance Container
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _greyBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Community Wallet Balance',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _greyIconColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '₦${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: wallet.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wallet.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: wallet.isActive ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Signatories Section
        Text(
          'Signatories',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _mainTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ...wallet.signatories.map((signatory) => _buildSignatoryTile(signatory)),
        const SizedBox(height: 20),
        // Approval Rule Section
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _greyBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approval Rule',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _greyIconColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatApprovalRule(wallet.approvalRule),
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
      ],
    );
  }

  /// Build signatory tile
  Widget _buildSignatoryTile(WalletSignatory signatory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              signatory.fullName.isNotEmpty ? signatory.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signatory.fullName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  signatory.label ?? signatory.role,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: _greyTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format approval rule for display
  String _formatApprovalRule(String rule) {
    switch (rule) {
      case 'THIRTY_PERCENT':
        return 'Any 1 signatory (30%)';
      case 'FIFTY_PERCENT':
        return 'Any 2 signatories (50%)';
      case 'SEVENTY_FIVE_PERCENT':
        return 'At least 2 signatories including Admin (75%)';
      case 'HUNDRED_PERCENT':
        return 'All 3 signatories required (100%)';
      default:
        return rule;
    }
  }

  /// Shimmer loading state for wallet balance - matching old design
  Widget _buildWalletBalanceShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _greyBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Wallet Balance Label Shimmer
            Container(height: 12, width: 100, color: Colors.white),
            const SizedBox(height: 20),
            // Balance Amount Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 24, width: 120, color: Colors.white),
                const SizedBox(width: 10),
                Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 7),
            // Action Buttons Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(height: 24, width: 24, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 50, color: Colors.white),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    Container(height: 24, width: 24, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 60, color: Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Wallet balance container - matching old design
  Widget _buildWalletBalanceContainer(WalletState walletState) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _greyBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wallet Balance label - centered like old design
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wallet Balance',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _greyIconColor,
                ),
              ),
              if (walletState.isLoading && !walletState.isFirstLoad) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_greyIconColor),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Balance display with visibility toggle - matching old design
          walletState.error != null && walletState.balance == '0.00'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to fetch balance',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => ref.read(walletProvider.notifier).fetchBalance(),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _isBalanceVisible
                        ? AnimatedBalanceText(
                            balance: walletState.balance,
                            isFirstLoad: walletState.isFirstLoad,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            '******',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                    const SizedBox(width: 10),
                    // Visibility toggle button - matching old design
                    Container(
                      height: 30,
                      width: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8E8E8),
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: IconButton(
                          icon: Icon(
                            _isBalanceVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _isBalanceVisible = !_isBalanceVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
          const Divider(),
          const SizedBox(height: 7),
          // Action buttons - Top Up and Withdraw - matching old design
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Up Button
              InkWell(
                onTap: _onTopUp,
                child: Column(
                  children: [
                    // Using icon similar to old SVG style
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Top Up',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: _greyTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              // Withdraw Button
              InkWell(
                onTap: _onWithdraw,
                child: Column(
                  children: [
                    // Using icon similar to old SVG style
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Withdraw',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: _greyTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return transactionsAsync.when(
      loading: () => _buildTransactionShimmer(),
      error: (error, stack) => _buildTransactionErrorState(),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState();
        }
        return _buildTransactionItems(transactions);
      },
    );
  }

  /// Transaction shimmer loading - matching old design
  Widget _buildTransactionShimmer() {
    return Column(
      children: List.generate(3, (index) => _buildSingleTransactionShimmer()),
    );
  }

  Widget _buildSingleTransactionShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF4F4F4), width: 1),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          // Icon Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Transaction Details Shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: 120,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 10,
                    width: 80,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          // Amount Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 14,
              width: 80,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state for transactions - matching old design
  Widget _buildTransactionErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              'Failed to load transactions',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                color: _mainTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                textBaseline: TextBaseline.alphabetic,
                color: _greyTextColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(transactionHistoryProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state - matching old design with SVG icon
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using no_activity.svg if available, otherwise fallback to icon
            SvgPicture.asset(
              'assets/svgs/no_activity.svg',
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(_greyIconColor, BlendMode.srcIn),
            ),
            const SizedBox(height: 12),
            Text(
              'No Transactions yet',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                color: _mainTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Easily add funds to your wallet for smooth community transactions and shopping experiences.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: _greyTextColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Transaction items - matching old design
  Widget _buildTransactionItems(List<WalletTransaction> transactions) {
    // Sort transactions by date (newest first)
    final sortedTransactions = List<WalletTransaction>.from(transactions)
      ..sort((a, b) {
        final aDate = a.date ?? DateTime(1970);
        final bDate = b.date ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final displayCount = sortedTransactions.length <= 5
        ? sortedTransactions.length
        : 5;

    return Column(
      children: List.generate(displayCount, (index) {
        final tx = sortedTransactions[index];
        return _buildTransactionItem(tx);
      }),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    final isCredit = tx.isCredit;
    final reason = (tx.narration ?? (isCredit ? 'Credit' : 'Debit')).replaceAll('_', ' ');

    return InkWell(
      onTap: () {
        // TODO: Navigate to transaction details
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF4F4F4), // neutral-100
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon Container - matching old design
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _veryLightPrimaryColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.formattedDate,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            // Amount - matching old design colors
            Text(
              tx.formattedAmount,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCredit ? AppColors.primary : _greyTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
