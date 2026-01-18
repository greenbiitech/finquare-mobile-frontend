import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';
import 'package:finsquare_mobile_app/features/community/presentation/providers/community_provider.dart';
import 'package:finsquare_mobile_app/features/auth/presentation/providers/auth_provider.dart';

// Colors matching old Greencard codebase
const Color _primaryColor = Color(0xFF21A8FB);
const Color _veryLightPrimaryColor = Color(0xFFE8F6FE);
const Color _greyBackground = Color(0xFFF3F3F3);
const Color _mainTextColor = Color(0xFF333333);

class MembersPage extends ConsumerStatefulWidget {
  final String communityId;

  const MembersPage({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  List<CommunityMember> _members = [];
  List<PendingInvite> _pendingInvites = [];
  Timer? _refreshTimer;

  List<String> get _tabs {
    // Only show Invites tab for users with admin privileges
    if (_hasAdminPrivileges()) {
      return ['Community Members', 'Admins', 'Invites'];
    } else {
      return ['Community Members', 'Admins'];
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch members when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMembers();
    });

    // Start periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchMembers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMembers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.getCommunityMembers(widget.communityId);

      if (response.success) {
        setState(() {
          _members = response.members;
          _pendingInvites = response.pendingInvites;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
      debugPrint('Error fetching members: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasAdminPrivileges() {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == null) return false;

    // Find current user in members list
    final userMembership = _members.where((m) => m.user.id == currentUserId).firstOrNull;

    if (userMembership == null) {
      // Fallback to community state
      final communityState = ref.read(communityProvider);
      final role = communityState.userRoleInActiveCommunity;
      return role == 'ADMIN' || role == 'CO_ADMIN';
    }

    return userMembership.role == 'ADMIN' || userMembership.role == 'CO_ADMIN';
  }

  bool _isMainAdmin() {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == null) return false;

    final userMembership = _members.where((m) => m.user.id == currentUserId).firstOrNull;

    if (userMembership == null) {
      final communityState = ref.read(communityProvider);
      return communityState.userRoleInActiveCommunity == 'ADMIN';
    }

    return userMembership.role == 'ADMIN';
  }

  List<CommunityMember> get _allMembers {
    // Sort members: Admin first, then Co-Admins, then regular members
    final sortedMembers = List<CommunityMember>.from(_members);
    sortedMembers.sort((a, b) {
      final aPriority = _getRolePriority(a.role);
      final bPriority = _getRolePriority(b.role);

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return a.user.fullName.compareTo(b.user.fullName);
    });

    return sortedMembers;
  }

  List<CommunityMember> get _adminMembers {
    return _allMembers
        .where((m) => m.role == 'ADMIN' || m.role == 'CO_ADMIN')
        .toList();
  }

  int _getRolePriority(String role) {
    switch (role) {
      case 'ADMIN':
        return 1;
      case 'CO_ADMIN':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityState = ref.watch(communityProvider);
    final communityName = communityState.activeCommunity?.name ?? 'Community';

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchMembers,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Header row with back button and title
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$communityName Members',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: _fetchMembers,
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    tooltip: 'Refresh Data',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tabs
              Row(
                children: _tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = index == _selectedTabIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? _veryLightPrimaryColor : _greyBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _primaryColor : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: FittedBox(
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? _mainTextColor : const Color(0xFF8E8E8E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Content based on selected tab
              Expanded(
                child: _isLoading && _members.isEmpty
                    ? _buildMemberShimmer()
                    : _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _hasAdminPrivileges()
          ? Tooltip(
              message: _selectedTabIndex == 0
                  ? 'Add Member'
                  : _selectedTabIndex == 1
                      ? 'Add Co-Admin'
                      : 'Send Invite',
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  if (_selectedTabIndex == 0) {
                    // Navigate to invite options screen with communityId
                    context.push('${AppRoutes.inviteLink}/${widget.communityId}');
                  } else if (_selectedTabIndex == 1) {
                    _showCoAdminSelectionModal();
                  } else if (_selectedTabIndex == 2) {
                    context.push('${AppRoutes.inviteLink}/${widget.communityId}');
                  }
                },
                backgroundColor: AppColors.primary,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Community Members
        return _buildMemberList(_allMembers);
      case 1: // Admins
        return _buildAdminList();
      case 2: // Invites
        return _buildInvitesList();
      default:
        return _buildMemberList(_allMembers);
    }
  }

  /// Shimmer loading for member list
  Widget _buildMemberShimmer() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: 6,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) => _buildSingleMemberShimmer(),
    );
  }

  Widget _buildSingleMemberShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Avatar shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and email shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 10,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<CommunityMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: members.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberItem(member);
      },
    );
  }

  Widget _buildAdminList() {
    final admins = _adminMembers;

    // Check if there's only the main admin (no co-admins)
    if (admins.length == 1 && admins[0].role == 'ADMIN') {
      return Column(
        children: [
          // Main admin member
          _buildMemberItem(admins[0]),

          const SizedBox(height: 32),

          // "No Co-Admins" section - only show for users with admin privileges
          if (_hasAdminPrivileges())
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No Co-Admins',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _mainTextColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Invite up to 3 co-admins to help you set up a community wallet and designate signatories.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _showCoAdminSelectionModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.all(8),
                    ),
                    child: Text(
                      'add co-admins',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // Show admin list with co-admins
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: admins.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final member = admins[index];
        return _buildMemberItem(member);
      },
    );
  }

  Widget _buildInvitesList() {
    if (_pendingInvites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending invites',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invites will appear here when sent',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _pendingInvites.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final invite = _pendingInvites[index];
        return _buildInviteItem(invite);
      },
    );
  }

  Widget _buildMemberItem(CommunityMember member) {
    final isCoAdmin = member.role == 'CO_ADMIN';
    final isCreator = member.role == 'ADMIN';
    final roleText = _getRoleDisplayText(member.role);

    return InkWell(
      onTap: () {
        // Navigate to member details
        _showMemberDetails(member);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCreator
                    ? Colors.amber.shade400
                    : _getAvatarColor(member.user.fullName),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getAvatarEmoji(member.user.fullName),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with Role Badge
                  Row(
                    children: [
                      Text(
                        member.user.fullName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _mainTextColor,
                        ),
                      ),
                      if (roleText != 'Member') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: isCreator
                                    ? _primaryColor
                                    : const Color(0xFFFFA412)),
                          ),
                          child: Text(
                            roleText,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: isCreator
                                  ? _primaryColor
                                  : const Color(0xFFFFA412),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    member.user.email,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF606060),
                    ),
                  ),
                ],
              ),
            ),

            // Remove button for co-admins only (X button)
            if (isCoAdmin && _isMainAdmin()) ...[
              const SizedBox(width: 8),
              Container(
                width: 16.67,
                height: 16.67,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF777777), width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRemoveAdminDialog(member),
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 10,
                        weight: 100,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInviteItem(PendingInvite invite) {
    final isExpired = invite.isExpired;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getAvatarColor(invite.name ?? invite.email),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getAvatarEmoji(invite.name ?? invite.email),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Invite Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.name ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _mainTextColor,
                  ),
                ),
                Text(
                  invite.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
                width: 1,
              ),
            ),
            child: Text(
              isExpired ? 'Expired' : 'Pending',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isExpired ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayText(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'CO_ADMIN':
        return 'Co-Admin';
      default:
        return 'Member';
    }
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

  void _showMemberDetails(CommunityMember member) {
    // TODO: Navigate to member details page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          member.user.fullName,
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${member.user.email}'),
            Text('Role: ${_getRoleDisplayText(member.role)}'),
            if (member.user.phoneNumber != null) Text('Phone: ${member.user.phoneNumber}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCoAdminSelectionModal() {
    // Get available members (only regular members, not admins or co-admins)
    final availableMembers = _members
        .where((m) => m.role == 'MEMBER')
        .toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No members available to promote to co-admin',
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoAdminSelectionModal(
        availableMembers: availableMembers,
        onCoAdminsSelected: (selectedUserIds) async {
          Navigator.of(context).pop();
          await _addCoAdmins(selectedUserIds);
        },
      ),
    );
  }

  Future<void> _addCoAdmins(List<String> userIds) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Adding co-admins...',
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.addCoAdmins(
        widget.communityId,
        userIds,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Co-admins added successfully!',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data
        await _fetchMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add co-admins: $e',
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRemoveAdminDialog(CommunityMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Co-Admin',
          style: TextStyle(fontFamily: AppTextStyles.fontFamily),
        ),
        content: Text(
          'Are you sure you want to remove ${member.user.fullName} as a co-admin? '
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
              _removeCoAdmin(member);
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

  Future<void> _removeCoAdmin(CommunityMember member) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removing co-admin...',
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      final repository = ref.read(communityRepositoryProvider);
      final response = await repository.removeCoAdmin(
        widget.communityId,
        member.user.id,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${member.user.fullName} removed as co-admin',
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data
        await _fetchMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: TextStyle(fontFamily: AppTextStyles.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove co-admin: $e',
            style: TextStyle(fontFamily: AppTextStyles.fontFamily),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Co-Admin Selection Modal
class _CoAdminSelectionModal extends StatefulWidget {
  final List<CommunityMember> availableMembers;
  final Function(List<String>) onCoAdminsSelected;

  const _CoAdminSelectionModal({
    required this.availableMembers,
    required this.onCoAdminsSelected,
  });

  @override
  State<_CoAdminSelectionModal> createState() => _CoAdminSelectionModalState();
}

class _CoAdminSelectionModalState extends State<_CoAdminSelectionModal> {
  final Set<String> _selectedUserIds = {};

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Co-Admins',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _mainTextColor,
                  ),
                ),
                Text(
                  '${_selectedUserIds.length}/3',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Member List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.availableMembers.length,
              itemBuilder: (context, index) {
                final member = widget.availableMembers[index];
                final isSelected = _selectedUserIds.contains(member.user.id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (_selectedUserIds.length < 3) {
                          _selectedUserIds.add(member.user.id);
                        }
                      } else {
                        _selectedUserIds.remove(member.user.id);
                      }
                    });
                  },
                  title: Text(
                    member.user.fullName,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    member.user.email,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  activeColor: _primaryColor,
                );
              },
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedUserIds.isEmpty
                    ? null
                    : () => widget.onCoAdminsSelected(_selectedUserIds.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(43),
                  ),
                ),
                child: Text(
                  'Add Co-Admins',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
