import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

class CommunityMembersPage extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityMembersPage({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends ConsumerState<CommunityMembersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _communityName = '';
  List<CommunityMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.getCommunityMembers(widget.communityId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _communityName = response.communityName;
          _members = response.members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load members';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Community Members',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (_communityName.isNotEmpty)
              Text(
                _communityName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: AppColors.primary,
      child: Column(
        children: [
          // Members count header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              '${_members.length} ${_members.length == 1 ? 'Member' : 'Members'}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Members list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return _buildMemberCard(member);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Members Yet',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your invite link to grow your community',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(CommunityMember member) {
    final isAdmin = member.role == 'ADMIN';
    final isCoAdmin = member.role == 'CO_ADMIN';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(member.user.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.user.fullName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin || isCoAdmin) ...[
                      const SizedBox(width: 8),
                      _buildRoleBadge(isAdmin ? 'Admin' : 'Co-Admin'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.user.email,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(member.joinedAt),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
