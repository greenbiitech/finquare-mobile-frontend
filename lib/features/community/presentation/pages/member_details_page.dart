import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/services/snackbar_service.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

// Colors matching old Greencard codebase
const Color _mainTextColor = Color(0xFF333333);

class MemberDetailsPage extends ConsumerStatefulWidget {
  final String communityId;
  final CommunityMember member;
  final String currentUserRole; // 'ADMIN', 'CO_ADMIN', or 'MEMBER'
  final VoidCallback? onMemberUpdated;

  const MemberDetailsPage({
    super.key,
    required this.communityId,
    required this.member,
    required this.currentUserRole,
    this.onMemberUpdated,
  });

  @override
  ConsumerState<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends ConsumerState<MemberDetailsPage> {
  bool _isLoading = false;

  bool get _isCurrentUserAdmin => widget.currentUserRole == 'ADMIN';
  bool get _isCurrentUserCoAdmin => widget.currentUserRole == 'CO_ADMIN';
  bool get _hasAdminPrivileges => _isCurrentUserAdmin || _isCurrentUserCoAdmin;

  bool get _isMemberAdmin => widget.member.role == 'ADMIN';
  bool get _isMemberCoAdmin => widget.member.role == 'CO_ADMIN';
  bool get _isMemberRegular => widget.member.role == 'MEMBER';

  // Check if this is the current user viewing their own profile
  bool get _isViewingSelf {
    final authState = ref.read(authProvider);
    return authState.user?.id == widget.member.user.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Header row with back button and title
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Profile Picture
              _buildProfilePicture(),

              const SizedBox(height: 16),

              // Member Name
              Text(
                widget.member.user.fullName,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Member Role
              Text(
                _getMemberRoleText(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Details Card
              _buildDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(widget.member.user.fullName),
      ),
      child: Center(
        child: Text(
          _getAvatarEmoji(widget.member.user.fullName),
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Section
          _buildDetailRow(
            label: 'Name',
            value: widget.member.user.fullName,
          ),

          const SizedBox(height: 24),

          // Phone Number Section
          _buildDetailRow(
            label: 'Phone Number',
            value: widget.member.user.phoneNumber ?? 'No phone number',
            showVerification: widget.member.user.phoneNumber != null,
          ),

          const SizedBox(height: 24),

          // Email Section
          _buildDetailRow(
            label: 'Email',
            value: widget.member.user.email,
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(
            color: Colors.grey.shade200,
            height: 32,
          ),

          const SizedBox(height: 8),

          // Actions Section - Only show for users with admin privileges and not viewing self
          if (_hasAdminPrivileges && !_isViewingSelf) ...[
            // For regular members
            if (_isMemberRegular) ...[
              // Make Co-Admin (only main admin can do this)
              if (_isCurrentUserAdmin) ...[
                _buildActionRow(
                  icon: Icons.people,
                  iconColor: Colors.green,
                  title: 'Make co-admin',
                  onTap: _makeCoAdmin,
                ),
                const SizedBox(height: 16),
              ],

              // Remove Member (both admin and co-admin can remove regular members)
              _buildActionRow(
                icon: Icons.delete,
                iconColor: Colors.red,
                title: 'Remove Member',
                onTap: _removeMember,
              ),
            ]

            // For co-admins (only main admin can manage co-admins)
            else if (_isMemberCoAdmin && _isCurrentUserAdmin) ...[
              // Remove Co-Admin
              _buildActionRow(
                icon: Icons.people,
                iconColor: Colors.orange,
                title: 'Remove Co-Admin',
                onTap: _removeCoAdmin,
              ),

              const SizedBox(height: 16),

              // Remove Member
              _buildActionRow(
                icon: Icons.delete,
                iconColor: Colors.red,
                title: 'Remove Member',
                onTap: _removeMember,
              ),
            ],
            // Note: Community Admin (isMemberAdmin = true) cannot be removed by anyone
          ],

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool showVerification = false,
  }) {
    return Column(
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
            if (showVerification)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      child: Opacity(
        opacity: _isLoading ? 0.5 : 1.0,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _getMemberRoleText() {
    if (_isMemberAdmin) return 'Community Admin';
    if (_isMemberCoAdmin) return 'Co-Admin';
    return 'Community Member';
  }

  String _getAvatarEmoji(String name) {
    if (name.isEmpty) return '👤';
    final firstChar = name[0].toUpperCase();
    final emojiMap = {
      'A': '😊', 'B': '😎', 'C': '🤓', 'D': '😍', 'E': '🤩',
      'F': '😇', 'G': '🤗', 'H': '😋', 'I': '🤠', 'J': '😴',
      'K': '🤡', 'L': '👻', 'M': '👽', 'N': '🤖', 'O': '👾',
      'P': '🎃', 'Q': '👺', 'R': '👹', 'S': '💀', 'T': '👻',
      'U': '👽', 'V': '🤖', 'W': '👾', 'X': '🎃', 'Y': '👺',
      'Z': '👹',
    };
    return emojiMap[firstChar] ?? '👤';
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _makeCoAdmin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Make Co-Admin',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Are you sure you want to make ${widget.member.user.fullName} a co-admin? '
          'They will have administrative privileges in the community.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmMakeCoAdmin();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text(
              'Make Co-Admin',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMakeCoAdmin() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.addCoAdmins(
        widget.communityId,
        [widget.member.user.id],
      );

      if (!mounted) return;

      if (response.success) {
        showSuccessSnackbar('${widget.member.user.fullName} is now a co-admin.');
        widget.onMemberUpdated?.call();
        Navigator.of(context).pop();
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to make co-admin: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeCoAdmin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Co-Admin',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.member.user.fullName} as a co-admin? '
          'They will return to being a regular member.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmRemoveCoAdmin();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(
              'Remove Co-Admin',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveCoAdmin() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.removeCoAdmin(
        widget.communityId,
        widget.member.user.id,
      );

      if (!mounted) return;

      if (response.success) {
        showSuccessSnackbar('${widget.member.user.fullName} is no longer a co-admin.');
        widget.onMemberUpdated?.call();
        Navigator.of(context).pop();
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to remove co-admin: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeMember() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Member',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Are you sure you want to remove ${widget.member.user.fullName} from the community? '
          'This action cannot be undone.',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmRemoveMember();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Remove',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.removeMember(
        widget.communityId,
        widget.member.user.id,
      );

      if (!mounted) return;

      if (response.success) {
        showSuccessSnackbar('${widget.member.user.fullName} has been removed from the community.');
        widget.onMemberUpdated?.call();
        Navigator.of(context).pop();
      } else {
        showErrorSnackbar(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to remove member: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
