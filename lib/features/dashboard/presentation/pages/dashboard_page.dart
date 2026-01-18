import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:finsquare_mobile_app/features/shop/presentation/pages/shop_page.dart';
import 'package:finsquare_mobile_app/features/hub/presentation/pages/hub_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/activate_wallet_page.dart';
import 'package:finsquare_mobile_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:finsquare_mobile_app/features/options/presentation/pages/options_page.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late int _currentIndex;

  /// Navigate to the Wallet tab (index 3)
  void _navigateToWalletTab() {
    setState(() {
      _currentIndex = 3;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> _buildPages(bool hasWallet) {
    return [
      HomePage(onNavigateToWallet: _navigateToWalletTab),
      const ShopPage(),
      const HubPage(),
      hasWallet ? const WalletPage() : const ActivateWalletPage(),
      const OptionsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasWallet = authState.user?.hasWallet ?? false;
    final pages = _buildPages(hasWallet);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        items: [
          _buildNavItem(
            'assets/svgs/home_outline.svg',
            'assets/svgs/home_active.svg',
            'Home',
          ),
          _buildNavItem(
            'assets/svgs/shop.svg',
            'assets/svgs/shop_active.svg',
            'Shop',
          ),
          _buildNavItem(
            'assets/svgs/community.svg',
            'assets/svgs/community_active.svg',
            'Hub',
          ),
          _buildNavItem(
            'assets/svgs/wallet_outline.svg',
            'assets/svgs/wallet_active.svg',
            'Wallet',
          ),
          _buildNavItem(
            'assets/svgs/options.svg',
            'assets/svgs/person_active.svg',
            'Options',
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String iconPath,
    String activeIconPath,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(iconPath),
      activeIcon: SvgPicture.asset(activeIconPath),
      label: label,
    );
  }
}
