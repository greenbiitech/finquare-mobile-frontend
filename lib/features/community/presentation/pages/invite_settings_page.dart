import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

class InviteSettingsPage extends ConsumerStatefulWidget {
  final String communityId;

  const InviteSettingsPage({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<InviteSettingsPage> createState() => _InviteSettingsPageState();
}

class _InviteSettingsPageState extends ConsumerState<InviteSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRegenerating = false;
  String? _errorMessage;
  InviteLinkConfig? _config;
  bool _isCopied = false;

  // Form state
  JoinType _selectedJoinType = JoinType.open;
  DateTime? _expiresAt;
  bool _hasExpiry = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.getInviteLinkConfig(widget.communityId);

      if (!mounted) return;

      if (response.success && response.config != null) {
        setState(() {
          _config = response.config;
          _selectedJoinType = response.config!.joinType;
          _expiresAt = response.config!.expiresAt;
          _hasExpiry = response.config!.expiresAt != null;
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
        _errorMessage = 'Failed to load invite settings';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final request = UpdateInviteLinkConfigRequest(
        joinType: _selectedJoinType,
        expiresAt: _hasExpiry ? _expiresAt : null,
      );

      final response = await repo.updateInviteLinkConfig(
        widget.communityId,
        request,
      );

      if (!mounted) return;

      if (response.success && response.config != null) {
        setState(() {
          _config = response.config;
          _isSaving = false;
        });
        _showSnackBar('Settings saved successfully', isSuccess: true);
      } else {
        setState(() {
          _errorMessage = response.message;
          _isSaving = false;
        });
        _showSnackBar(response.message, isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save settings';
        _isSaving = false;
      });
      _showSnackBar('Failed to save settings', isSuccess: false);
    }
  }

  Future<void> _regenerateLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Invite Link?'),
        content: const Text(
          'This will create a new invite link and deactivate the current one. '
          'Anyone with the old link will no longer be able to join.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRegenerating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.regenerateInviteLink(widget.communityId);

      if (!mounted) return;

      if (response.success && response.config != null) {
        setState(() {
          _config = response.config;
          _selectedJoinType = response.config!.joinType;
          _expiresAt = response.config!.expiresAt;
          _hasExpiry = response.config!.expiresAt != null;
          _isRegenerating = false;
        });
        _showSnackBar('New invite link generated', isSuccess: true);
      } else {
        setState(() {
          _errorMessage = response.message;
          _isRegenerating = false;
        });
        _showSnackBar(response.message, isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to regenerate link';
        _isRegenerating = false;
      });
      _showSnackBar('Failed to regenerate link', isSuccess: false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_config?.inviteLink == null) return;

    await Clipboard.setData(ClipboardData(text: _config!.inviteLink));
    setState(() {
      _isCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });

    _showSnackBar('Link copied to clipboard', isSuccess: true);
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expiresAt = picked;
        _hasExpiry = true;
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
        title: const Text(
          'Invite Settings',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _config == null) {
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
              onPressed: _loadConfig,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invite Link Card
                _buildInviteLinkCard(),
                const SizedBox(height: 24),

                // Join Type Section
                _buildSectionTitle('Join Settings'),
                const SizedBox(height: 12),
                _buildJoinTypeCard(),
                const SizedBox(height: 24),

                // Expiry Section
                _buildSectionTitle('Link Expiry'),
                const SizedBox(height: 12),
                _buildExpiryCard(),
                const SizedBox(height: 24),

                // Stats Section
                _buildSectionTitle('Usage Statistics'),
                const SizedBox(height: 12),
                _buildStatsCard(),
                const SizedBox(height: 24),

                // Management Section
                _buildSectionTitle('Community Management'),
                const SizedBox(height: 12),
                _buildManagementCard(),
                const SizedBox(height: 24),

                // Actions Section
                _buildSectionTitle('Link Actions'),
                const SizedBox(height: 12),
                _buildActionsCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Fixed Save Button at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(43),
                ),
              ),
              onPressed: _isSaving ? null : _saveConfig,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInviteLinkCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Invite Link',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isCopied ? AppColors.success : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isCopied ? Icons.check : Icons.copy,
                    size: 20,
                    color: _isCopied ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _config?.inviteLink ?? 'Loading...',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTypeCard() {
    return Container(
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
      child: Column(
        children: [
          _buildJoinTypeOption(
            JoinType.open,
            'Open to All',
            'Anyone with the link can join immediately',
            Icons.public,
          ),
          const Divider(height: 24),
          _buildJoinTypeOption(
            JoinType.approvalRequired,
            'Approval Required',
            'New members need your approval to join',
            Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTypeOption(
    JoinType type,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedJoinType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedJoinType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<JoinType>(
              value: type,
              groupValue: _selectedJoinType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedJoinType = value;
                  });
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard() {
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Set Expiry Date',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _hasExpiry,
                onChanged: (value) {
                  setState(() {
                    _hasExpiry = value;
                    if (!value) {
                      _expiresAt = null;
                    } else if (_expiresAt == null) {
                      _expiresAt = DateTime.now().add(const Duration(days: 7));
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_hasExpiry) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectExpiryDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                          : 'Select date',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
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
          Expanded(
            child: _buildStatItem(
              'Members Joined',
              '${_config?.usedCount ?? 0}',
              Icons.people_outline,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.border,
          ),
          Expanded(
            child: _buildStatItem(
              'Status',
              _config?.isActive == true ? 'Active' : 'Inactive',
              Icons.circle,
              statusColor: _config?.isActive == true ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: statusColor != null ? 12 : 24,
          color: statusColor ?? AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard() {
    return Container(
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
      child: Column(
        children: [
          _buildManagementItem(
            icon: Icons.people_outline,
            title: 'View Members',
            subtitle: 'See all members in your community',
            onTap: () {
              context.push('${AppRoutes.communityMembers}/${widget.communityId}');
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildManagementItem(
            icon: Icons.how_to_reg_outlined,
            title: 'Join Requests',
            subtitle: _selectedJoinType == JoinType.approvalRequired
                ? 'Review pending membership requests'
                : 'No pending requests (open access)',
            onTap: () {
              context.push('${AppRoutes.joinRequests}/${widget.communityId}');
            },
            showBadge: _selectedJoinType == JoinType.approvalRequired,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Approval Mode',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
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
      child: Column(
        children: [
          _buildActionItem(
            icon: Icons.refresh,
            title: 'Regenerate Link',
            subtitle: 'Create a new link and deactivate the current one',
            onTap: _isRegenerating ? null : _regenerateLink,
            isLoading: _isRegenerating,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isDestructive ? Colors.red : AppColors.textSecondary,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
