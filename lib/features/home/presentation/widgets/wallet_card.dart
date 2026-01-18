import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/widgets/animated_balance_text.dart';

// Colors matching old codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _greyIconColor = Color(0xFF8E8E8E);

class WalletCard extends ConsumerStatefulWidget {
  const WalletCard({super.key, this.onSetUpWallet});

  /// Callback when user taps "Set Up Wallet" button
  final VoidCallback? onSetUpWallet;

  @override
  ConsumerState<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends ConsumerState<WalletCard> {
  @override
  void initState() {
    super.initState();
    // Fetch balance when card is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBalanceIfNeeded();
    });
  }

  void _fetchBalanceIfNeeded() {
    final authState = ref.read(authProvider);
    final hasWallet = authState.user?.hasWallet ?? false;

    if (hasWallet) {
      final walletState = ref.read(walletProvider);
      // Fetch if first load or cache is stale
      if (walletState.isFirstLoad || walletState.isStale) {
        ref.read(walletProvider.notifier).fetchBalance();
      } else {
        // Silent refresh in background
        ref.read(walletProvider.notifier).refreshBalanceSilently();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasWallet = user?.hasWallet ?? false;

    if (!hasWallet) {
      return InactiveWalletCard(onSetUpWallet: widget.onSetUpWallet);
    }

    // Watch wallet provider for balance updates
    final walletState = ref.watch(walletProvider);

    return ActiveWalletCard(
      balance: walletState.balance,
      isFirstLoad: walletState.isFirstLoad,
      isLoading: walletState.isLoading,
    );
  }
}

class InactiveWalletCard extends StatelessWidget {
  const InactiveWalletCard({super.key, this.onSetUpWallet});

  final VoidCallback? onSetUpWallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _greyBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/svgs/todo.svg'),
          const SizedBox(height: 15),
          Row(
            children: [
              SvgPicture.asset('assets/svgs/home_wallet.svg'),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your wallet is your bank account for all activities, '
                  'debit and credit in Esusu, Savings, dues etc',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _greyTextColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          InkWell(
            onTap: onSetUpWallet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svgs/u_wallet.svg',
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Set Up Wallet',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveWalletCard extends StatefulWidget {
  const ActiveWalletCard({
    super.key,
    required this.balance,
    this.isFirstLoad = false,
    this.isLoading = false,
  });

  final String balance;
  final bool isFirstLoad;
  final bool isLoading;

  @override
  State<ActiveWalletCard> createState() => _ActiveWalletCardState();
}

class _ActiveWalletCardState extends State<ActiveWalletCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _greyBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (widget.isLoading) ...[
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
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isBalanceVisible
                  ? AnimatedBalanceText(
                      balance: widget.balance,
                      isFirstLoad: widget.isFirstLoad,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        color: Colors.black,
                      ),
                      subscriptFontSizeRatio: 0.58,
                    )
                  : Text(
                      '******',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
              const SizedBox(width: 10),
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
          InkWell(
            onTap: () => context.push(AppRoutes.topUp),
            child: Row(
              children: [
                SvgPicture.asset('assets/svgs/u_wallet.svg'),
                const SizedBox(width: 10),
                Text(
                  'Top Up Account',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
