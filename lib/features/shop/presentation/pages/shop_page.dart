import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

// Colors matching old Greencard codebase
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _greyTextColor = Color(0xFF606060);
const Color _mainTextColor = Color(0xFF333333);
const Color _veryLightPrimaryColor = Color(0xFFE8F5E9);

/// Shop Page - Static UI matching old Greencard design
/// Logic to be added later
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  // Cart count - static for now, will be fetched from cart provider later
  final int _cartCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and cart icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  // Cart Icon with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined),
                        onPressed: () {
                          // TODO: Navigate to cart
                        },
                      ),
                      if (_cartCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 20),
              // Categories Section
              Text(
                'Categories',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _mainTextColor,
                ),
              ),
              const SizedBox(height: 20),
              // Category Items Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryItem(Icons.devices, 'Electronics'),
                  _buildCategoryItem(Icons.handyman_outlined, 'Services'),
                  _buildCategoryItem(Icons.computer, 'Technology'),
                ],
              ),
              const SizedBox(height: 20),
              // Explore Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _mainTextColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // TODO: Navigate to view all stores
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Store List (Horizontal)
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildStoreItem(index),
                ),
              ),
              const SizedBox(height: 20),
              // Featured Products Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Products',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _mainTextColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // TODO: Navigate to view all products
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Product List (Horizontal)
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildProductItem(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search bar widget - matching old design
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _greyBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products, stores...',
          hintStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: _greyTextColor,
          ),
          prefixIcon: Icon(Icons.search, color: _greyTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (value) {
          // TODO: Search functionality
        },
      ),
    );
  }

  /// Category item widget - matching old design
  Widget _buildCategoryItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _veryLightPrimaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mainTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Store item widget - matching old design
  Widget _buildStoreItem(int index) {
    final storeNames = ['Fashion Hub', 'Tech Store', 'Home Essentials'];
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to store page
      },
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 90,
                color: _greyBackground,
                child: Icon(
                  Icons.store,
                  size: 40,
                  color: _greyTextColor,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              storeNames[index % storeNames.length],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  /// Product item widget - matching old design
  Widget _buildProductItem(int index) {
    final productNames = ['Wireless Earbuds', 'Smart Watch', 'Power Bank'];
    final productPrices = ['₦15,000', '₦45,000', '₦8,500'];

    return GestureDetector(
      onTap: () {
        // TODO: Show product details bottom sheet
      },
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 160,
                height: 120,
                color: _greyBackground,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 50,
                  color: _greyTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              productNames[index % productNames.length],
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _mainTextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Group Buy badge (optional)
            if (index == 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Group Buy',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              productPrices[index % productPrices.length],
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
