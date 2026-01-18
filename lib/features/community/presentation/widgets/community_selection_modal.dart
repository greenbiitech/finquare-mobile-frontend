import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

class CommunitySelectionModal extends StatelessWidget {
  final List<UserCommunity> userCommunities;
  final String? currentCommunityId;
  final Function(UserCommunity) onCommunitySelected;
  final VoidCallback onCreateNewCommunity;

  const CommunitySelectionModal({
    super.key,
    required this.userCommunities,
    required this.currentCommunityId,
    required this.onCommunitySelected,
    required this.onCreateNewCommunity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(
                  'Select Community',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          // Community List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: userCommunities.length,
              itemBuilder: (context, index) {
                final community = userCommunities[index];
                final isCurrentCommunity = community.id == currentCommunityId;

                return InkWell(
                  onTap: () => onCommunitySelected(community),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentCommunity
                            ? AppColors.primary
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Community Logo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: community.logo != null
                                ? Colors.transparent
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: community.logo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.network(
                                    community.logo!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                        child: Icon(
                                          Icons.group,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),

                        const SizedBox(width: 16),

                        // Community Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRoleDisplayText(community.role),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Current Community Indicator
                        if (isCurrentCommunity)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Create New Community Option
          Container(
            margin: const EdgeInsets.all(20),
            child: InkWell(
              onTap: onCreateNewCommunity,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Create Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Create Text
                    Text(
                      'Create a new Community',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom padding for safe area
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getRoleDisplayText(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'CO_ADMIN':
        return 'Co-Admin';
      case 'MEMBER':
        return 'Member';
      default:
        return 'Member';
    }
  }
}
