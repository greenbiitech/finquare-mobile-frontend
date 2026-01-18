import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/features/community/data/community_repository.dart';

class JoinRequestsPage extends ConsumerStatefulWidget {
  final String communityId;

  const JoinRequestsPage({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends ConsumerState<JoinRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  List<JoinRequest> _pendingRequests = [];
  List<JoinRequest> _processedRequests = [];
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repo = ref.read(communityRepositoryProvider);

      // Load all requests
      final response = await repo.getJoinRequests(widget.communityId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _pendingRequests = response.requests
              .where((r) => r.status == JoinRequestStatus.pending)
              .toList();
          _processedRequests = response.requests
              .where((r) => r.status != JoinRequestStatus.pending)
              .toList();
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
        _errorMessage = 'Failed to load requests';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(JoinRequest request) async {
    setState(() {
      _processingIds.add(request.id);
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.approveJoinRequest(request.id);

      if (!mounted) return;

      if (response.success) {
        _showSnackBar('Request approved successfully', isSuccess: true);
        await _loadRequests();
      } else {
        _showSnackBar(response.message, isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Failed to approve request', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(request.id);
        });
      }
    }
  }

  Future<void> _rejectRequest(JoinRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request?'),
        content: Text(
          'Are you sure you want to reject ${request.user.fullName}\'s request to join?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _processingIds.add(request.id);
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      final response = await repo.rejectJoinRequest(request.id);

      if (!mounted) return;

      if (response.success) {
        _showSnackBar('Request rejected', isSuccess: true);
        await _loadRequests();
      } else {
        _showSnackBar(response.message, isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Failed to reject request', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(request.id);
        });
      }
    }
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
          'Join Requests',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Pending (${_pendingRequests.length})'),
            Tab(text: 'History (${_processedRequests.length})'),
          ],
        ),
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
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: AppColors.primary,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Pending Requests',
        subtitle: 'New join requests will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildPendingRequestCard(request);
      },
    );
  }

  Widget _buildHistoryList() {
    if (_processedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No History',
        subtitle: 'Approved and rejected requests will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _processedRequests.length,
      itemBuilder: (context, index) {
        final request = _processedRequests[index];
        return _buildHistoryCard(request);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
            child: Icon(
              icon,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestCard(JoinRequest request) {
    final isProcessing = _processingIds.contains(request.id);

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
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(request.user.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.user.fullName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.user.email,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(request.createdAt),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isProcessing ? null : () => _rejectRequest(request),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isProcessing ? null : () => _approveRequest(request),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(JoinRequest request) {
    final isApproved = request.status == JoinRequestStatus.approved;

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
          _buildAvatar(request.user.fullName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.user.fullName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.user.email,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isApproved ? 'Approved' : 'Rejected',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isApproved ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(request.respondedAt ?? request.createdAt),
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
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
