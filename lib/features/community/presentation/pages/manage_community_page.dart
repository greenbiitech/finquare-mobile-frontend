import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';

class ManageCommunityPage extends ConsumerStatefulWidget {
  final String communityId;

  const ManageCommunityPage({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<ManageCommunityPage> createState() =>
      _ManageCommunityPageState();
}

class _ManageCommunityPageState extends ConsumerState<ManageCommunityPage> {
  bool _isLoading = false;
  String? _inviteLink;
  bool _isLoadingInviteLink = true;

  @override
  void initState() {
    super.initState();
    _loadInviteLink();
  }

  Future<void> _loadInviteLink() async {
    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.getInviteLink(widget.communityId);

      if (mounted && response.success) {
        setState(() {
          _inviteLink = response.inviteLink;
          _isLoadingInviteLink = false;
        });
      } else {
        setState(() {
          _isLoadingInviteLink = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInviteLink = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final community = communityState.activeCommunity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Header row with back button and title
                  Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Manage Community',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Community Logo Section
                  _buildCommunityLogo(community),

                  const SizedBox(height: 8),

                  // Change Logo Button
                  TextButton(
                    onPressed: _showChangeLogoDialog,
                    child: Text(
                      'Change Logo',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Community Name
                  Text(
                    community?.name ?? 'Community',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  // Community Admin Badge
                  Text(
                    'Community Admin',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Community Details Section
                  _buildDetailSection(
                    label: 'Community Name',
                    value: community?.name ?? 'N/A',
                    onTap: _showEditNameDialog,
                  ),

                  const SizedBox(height: 24),

                  _buildDetailSection(
                    label: 'Description',
                    value: community?.description?.isNotEmpty == true
                        ? community!.description!
                        : 'No description provided',
                    onTap: _showEditDescriptionDialog,
                  ),

                  const SizedBox(height: 24),

                  _buildDetailSection(
                    label: 'Community link',
                    value: _isLoadingInviteLink
                        ? 'Loading...'
                        : (_inviteLink ?? 'No invite link available'),
                    onTap: _inviteLink != null ? _copyCommunityLink : null,
                    showCopyIcon: _inviteLink != null,
                  ),

                  const SizedBox(height: 24),

                  _buildColorSection(community),
                ],
              ),
            ),
    );
  }

  Widget _buildCommunityLogo(ActiveCommunity? community) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: community?.logo != null && community!.logo!.isNotEmpty
            ? Image.network(
                community.logo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildLogoPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  );
                },
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Yellow
            Color(0xFFDC143C), // Red
            Color(0xFF4169E1), // Blue
            Color(0xFFFFFFFF), // White
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
      ),
      child: Center(
        child: Text(
          'Logo ipsum',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String label,
    required String value,
    VoidCallback? onTap,
    bool showCopyIcon = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Icon(
                  showCopyIcon ? Icons.copy : Icons.arrow_forward_ios,
                  size: 16,
                  color: showCopyIcon ? AppColors.primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(ActiveCommunity? community) {
    // Parse the color from the community color string
    Color currentColor;
    try {
      final colorString = community?.color ?? '#FF0000';
      currentColor =
          Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      currentColor = Colors.red; // Default fallback
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getColorName(currentColor),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showColorPicker,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.red || color.value == 0xFFFF0000) return 'Red';
    if (color == Colors.blue || color.value == 0xFF0000FF) return 'Blue';
    if (color == Colors.green || color.value == 0xFF00FF00) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.teal) return 'Teal';
    return 'Custom';
  }

  void _showChangeLogoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Logo',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Logo upload functionality will be implemented soon.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Community Name',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Community name editing will be implemented soon.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Description',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Description editing will be implemented soon.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  void _copyCommunityLink() {
    if (_inviteLink == null) return;

    Clipboard.setData(ClipboardData(text: _inviteLink!));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Community link copied to clipboard!',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Color',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Color picker will be implemented soon.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}
