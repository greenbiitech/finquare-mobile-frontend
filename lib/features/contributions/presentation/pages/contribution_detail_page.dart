import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);

/// Provider for fetching contribution details
final contributionDetailProvider = FutureProvider.autoDispose
    .family<ContributionDetailsResponse, String>((ref, contributionId) async {
  final repository = ref.watch(contributionsRepositoryProvider);
  return repository.getContributionDetails(contributionId);
});

class ContributionDetailPage extends ConsumerStatefulWidget {
  final String contributionId;

  const ContributionDetailPage({
    super.key,
    required this.contributionId,
  });

  @override
  ConsumerState<ContributionDetailPage> createState() =>
      _ContributionDetailPageState();
}

class _ContributionDetailPageState
    extends ConsumerState<ContributionDetailPage> {
  int _selectedTabIndex = 0; // 0 = Contributions, 1 = Participants
  bool _isAmountVisible = true;

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(contributionDetailProvider(widget.contributionId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: detailsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _contributionPrimary),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load contribution details',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    color: const Color(0xFF606060),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(
                        contributionDetailProvider(widget.contributionId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (response) {
            final contribution = response.contribution;
            if (contribution == null) {
              return const Center(child: Text('Contribution not found'));
            }
            return _buildContent(contribution);
          },
        ),
      ),
    );
  }

  Widget _buildContent(ContributionDetails contribution) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 12),
              // Contribution image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _contributionLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: contribution.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          contribution.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultIcon(contribution.name),
                        ),
                      )
                    : _buildDefaultIcon(contribution.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contribution.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    if (contribution.description != null &&
                        contribution.description!.isNotEmpty)
                      Text(
                        contribution.description!,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Show menu
                },
                icon: const Icon(Icons.more_vert, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Summary Card
                _buildSummaryCard(contribution),
                const SizedBox(height: 20),

                // Tabs
                Row(
                  children: [
                    _buildTab('Contributions', 0),
                    const SizedBox(width: 12),
                    _buildTab('Participants', 1),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab content
                _buildTabContent(contribution),
              ],
            ),
          ),
        ),

        // Make Contribution Button (only if user is participant and accepted)
        if (contribution.isParticipant &&
            contribution.myInviteStatus == ContributionInviteStatus.accepted)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _navigateToPayment(contribution),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _contributionPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Make Contribution',
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
      ],
    );
  }

  Widget _buildDefaultIcon(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'C',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _contributionPrimary,
        ),
      ),
    );
  }

  void _navigateToPayment(ContributionDetails contribution) {
    double amount = 0;
    switch (contribution.type) {
      case ContributionType.fixed:
        amount = contribution.amount ?? 0;
        break;
      case ContributionType.target:
        amount = contribution.amount ?? 0;
        break;
      case ContributionType.flexible:
        amount = 0; // User will enter amount
        break;
    }

    context.push(
      AppRoutes.contributionPayment,
      extra: {
        'contributionId': contribution.id,
        'contributionName': contribution.name,
        'recipientName': contribution.recipientName ?? 'Community Wallet',
        'amount': amount,
        'contributionType': contribution.type,
        'totalContributed': contribution.totalContributed,
        'targetAmount': contribution.amount,
      },
    );
  }

  Widget _buildSummaryCard(ContributionDetails contribution) {
    final remaining = contribution.type == ContributionType.target &&
            contribution.amount != null
        ? contribution.amount! - contribution.totalContributed
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _contributionLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total contribution label
          Text(
            'Total contribution',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF606060),
            ),
          ),
          const SizedBox(height: 8),

          // Amount with visibility toggle
          Row(
            children: [
              Text(
                _isAmountVisible
                    ? '₦${_formatAmount(contribution.totalContributed)}'
                    : '₦*****',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              if (_isAmountVisible)
                Text(
                  '.00',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAmountVisible = !_isAmountVisible;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFCCDD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAmountVisible ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Container(height: 1, color: const Color(0xFFFFCCDD)),
          const SizedBox(height: 12),

          // Recipient and Deadline row
          Row(
            children: [
              // Recipient
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(
                    contribution.recipientName ?? 'Community Wallet'),
                child: Text(
                  _getInitials(
                      contribution.recipientName ?? 'Community Wallet'),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    Text(
                      contribution.recipientName ?? 'Community Wallet',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Deadline
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Deadline',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF606060),
                    ),
                  ),
                  Text(
                    contribution.deadline != null
                        ? DateFormat('dd MMM yyyy').format(contribution.deadline!)
                        : 'No deadline',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar (only for target contributions)
          if (contribution.type == ContributionType.target &&
              contribution.amount != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (contribution.progress / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          _contributionPrimary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  remaining != null && remaining > 0
                      ? '₦${_formatAmount(remaining)} till target'
                      : 'Target reached!',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _contributionLight : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected ? Border.all(color: _contributionPrimary, width: 1) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(isSelected ? 0xFF333333 : 0xFF8E8E8E),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ContributionDetails contribution) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildContributionsList(contribution);
      case 1:
        return _buildParticipantsList(contribution);
      default:
        return const SizedBox();
    }
  }

  Widget _buildContributionsList(ContributionDetails contribution) {
    // Filter participants who have contributed
    final contributedParticipants = contribution.participants
        .where((p) => p.totalContributed > 0)
        .toList();

    if (contributedParticipants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No contributions yet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: contributedParticipants.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE0E0E0),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final participant = contributedParticipants[index];
          return _buildContributionTile(participant);
        },
      ),
    );
  }

  Widget _buildContributionTile(ContributionParticipantDetail participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(participant.fullName),
            backgroundImage:
                participant.photo != null ? NetworkImage(participant.photo!) : null,
            child: participant.photo == null
                ? Text(
                    _getInitials(participant.fullName),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _contributionLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${participant.entryCount} contribution${participant.entryCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _contributionPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+₦${_formatAmount(participant.totalContributed)}',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(ContributionDetails contribution) {
    if (contribution.participants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No participants yet',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF606060),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: contribution.participants.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE0E0E0),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final participant = contribution.participants[index];
          return _buildParticipantTile(participant);
        },
      ),
    );
  }

  Widget _buildParticipantTile(ContributionParticipantDetail participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(participant.fullName),
            backgroundImage:
                participant.photo != null ? NetworkImage(participant.photo!) : null,
            child: participant.photo == null
                ? Text(
                    _getInitials(participant.fullName),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                _buildInviteStatusChip(participant.inviteStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteStatusChip(ContributionInviteStatus status) {
    Color bgColor;
    String text;

    switch (status) {
      case ContributionInviteStatus.accepted:
        bgColor = const Color(0xFFD0F5CE);
        text = 'Accepted';
        break;
      case ContributionInviteStatus.declined:
        bgColor = const Color(0xFFFFE0E0);
        text = 'Declined';
        break;
      case ContributionInviteStatus.invited:
        bgColor = const Color(0xFFFAEFBF);
        text = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final formatted = amount.toStringAsFixed(0);
      final result = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        count++;
        result.write(formatted[i]);
        if (count % 3 == 0 && i != 0) {
          result.write(',');
        }
      }
      return result.toString().split('').reversed.join('');
    }
    return amount.toStringAsFixed(0);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    return colors[name.hashCode % colors.length];
  }
}
