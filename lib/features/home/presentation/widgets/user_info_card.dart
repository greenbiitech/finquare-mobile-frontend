import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final communityState = ref.watch(communityProvider);
    final user = authState.user;
    final community = communityState.activeCommunity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // SVG as background
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/svgs/membership_avatars.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          // Foreground content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar image - show community logo if available
                _buildAvatar(context, community?.logo, community?.color),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Community name with icon
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              community?.name ?? 'FinSquare Community',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Role with icon
                      Row(
                        children: [
                          Icon(
                            _getRoleIcon(community?.role),
                            size: 12,
                            color: _getRoleColor(community?.role),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRoleDisplayText(community?.role),
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              color: _getRoleColor(community?.role),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'ADMIN':
        return Colors.purple;
      case 'CO_ADMIN':
        return Colors.orange;
      case 'MEMBER':
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'ADMIN':
        return Icons.star;
      case 'CO_ADMIN':
        return Icons.admin_panel_settings;
      case 'MEMBER':
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayText(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'CO_ADMIN':
        return 'Co-Admin';
      case 'MEMBER':
      default:
        return 'Member';
    }
  }

  Widget _buildAvatar(BuildContext context, String? logoUrl, String? colorHex) {
    final size = MediaQuery.of(context).size.width * 0.10;
    final borderColor = _parseColor(colorHex) ?? AppColors.primary;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            logoUrl,
            height: size,
            width: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/avatar_default.png',
                height: size,
                width: size,
                fit: BoxFit.cover,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                height: size,
                width: size,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: borderColor,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/avatar_default.png',
          height: size,
          width: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }
}
