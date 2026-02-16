import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/contributions/data/contributions_repository.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/providers/contribution_creation_provider.dart';

const Color _contributionPrimary = Color(0xFFF83181);

class ContributionAddParticipantsPage extends ConsumerStatefulWidget {
  const ContributionAddParticipantsPage({super.key});

  @override
  ConsumerState<ContributionAddParticipantsPage> createState() =>
      _ContributionAddParticipantsPageState();
}

class _ContributionAddParticipantsPageState
    extends ConsumerState<ContributionAddParticipantsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMembers();
    });
  }

  Future<void> _loadMembers() async {
    await ref.read(contributionCreationProvider.notifier).loadCommunityMembers();
  }

  void _showSelectMemberModal() {
    final state = ref.read(contributionCreationProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SelectMemberModal(
        availableMembers: state.availableMembers,
        selectedParticipants: state.selectedParticipants,
        onAdd: (member) {
          ref.read(contributionCreationProvider.notifier).addParticipant(member);
        },
        onRemove: (memberId) {
          ref.read(contributionCreationProvider.notifier).removeParticipant(memberId);
        },
      ),
    );
  }

  void _removeParticipant(String memberId) {
    ref.read(contributionCreationProvider.notifier).removeParticipant(memberId);
  }

  void _addAllMembers() {
    ref.read(contributionCreationProvider.notifier).addAllEligibleMembers();
  }

  Future<void> _handleNext() async {
    final state = ref.read(contributionCreationProvider);
    if (state.selectedParticipants.isEmpty) return;

    // Create the contribution
    final success = await ref
        .read(contributionCreationProvider.notifier)
        .createContribution();

    if (success && mounted) {
      // Trigger refresh on contribution list and hub
      ref.read(contributionListRefreshTriggerProvider.notifier).state++;
      ref.read(contributionHubRefreshTriggerProvider.notifier).state++;
      context.push(AppRoutes.contributionSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contributionCreationProvider);
    final selectedParticipants = state.selectedParticipants;
    final eligibleMembers = state.eligibleMembers;
    final participantsLeft = eligibleMembers.length - selectedParticipants.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 20),
                  Text(
                    'Add participants',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add participant label
                    Text(
                      'Add participant',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Select Participant dropdown
                    GestureDetector(
                      onTap: state.isLoading ? null : _showSelectMemberModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Participant',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            if (state.isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _contributionPrimary,
                                ),
                              )
                            else
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Error message
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Content based on state
                    Expanded(
                      child: state.isLoading
                          ? _buildLoadingState()
                          : selectedParticipants.isEmpty
                              ? _buildEmptyState(eligibleMembers.length)
                              : _buildParticipantsList(
                                  selectedParticipants, participantsLeft),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled:
                    selectedParticipants.isNotEmpty && !state.isLoading,
                onPressed: _handleNext,
                title: state.isLoading ? 'Creating...' : 'Create',
                buttonColor: selectedParticipants.isNotEmpty && !state.isLoading
                    ? _contributionPrimary
                    : Colors.grey.shade400,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: _contributionPrimary,
      ),
    );
  }

  Widget _buildEmptyState(int eligibleCount) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'No Participants',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invite your participants to join this Contribution,',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF606060),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Add all members button
        if (eligibleCount > 0)
          OutlinedButton(
            onPressed: _addAllMembers,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _contributionPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: Text(
              'add all members ($eligibleCount)',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _contributionPrimary,
              ),
            ),
          ),
        const SizedBox(height: 30),
        // Skeleton placeholders
        _buildSkeletonRow(),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        _buildSkeletonRow(),
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        _buildSkeletonRow(),
      ],
    );
  }

  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(
    List<ContributionCommunityMember> selectedParticipants,
    int participantsLeft,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Participants header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Participants',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              participantsLeft > 0 ? '$participantsLeft left' : 'All added',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: participantsLeft > 0 ? _contributionPrimary : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: selectedParticipants.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (context, index) {
              final participant = selectedParticipants[index];
              return _buildParticipantTile(participant);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(ContributionCommunityMember participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(participant.fullName),
            backgroundImage: participant.photo != null
                ? NetworkImage(participant.photo!)
                : null,
            child: participant.photo == null
                ? Text(
                    _getInitials(participant.fullName),
                    style: const TextStyle(
                      fontSize: 18,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.isCurrentUser
                            ? '${participant.fullName} (You)'
                            : participant.fullName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (participant.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _contributionPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _contributionPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  participant.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeParticipant(participant.id),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.cancel_outlined,
                color: Color(0xFF9E9E9E),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
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

class _SelectMemberModal extends ConsumerStatefulWidget {
  final List<ContributionCommunityMember> availableMembers;
  final List<ContributionCommunityMember> selectedParticipants;
  final Function(ContributionCommunityMember) onAdd;
  final Function(String) onRemove;

  const _SelectMemberModal({
    required this.availableMembers,
    required this.selectedParticipants,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  ConsumerState<_SelectMemberModal> createState() => _SelectMemberModalState();
}

class _SelectMemberModalState extends ConsumerState<_SelectMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContributionCommunityMember> _getFilteredMembers() {
    if (_searchQuery.isEmpty) return widget.availableMembers;
    return widget.availableMembers
        .where((member) =>
            member.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            member.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool _isSelected(String memberId) {
    // Read from the provider to get real-time updates
    final state = ref.watch(contributionCreationProvider);
    return state.selectedParticipants.any((p) => p.id == memberId);
  }

  void _toggleMember(ContributionCommunityMember member) {
    if (_isSelected(member.id)) {
      widget.onRemove(member.id);
    } else {
      widget.onAdd(member);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _getFilteredMembers();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Select Member',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search members',
                        hintStyle: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9E9E),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF606060),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredMembers.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No members available'
                            : 'No members found',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          color: const Color(0xFF606060),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredMembers.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        final isSelected = _isSelected(member.id);
                        return _buildMemberTile(member, isSelected);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: () => Navigator.pop(context),
                title: 'Done',
                buttonColor: _contributionPrimary,
                height: 54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberTile(ContributionCommunityMember member, bool isSelected) {
    final hasWallet = member.hasActiveWallet;
    final canAdd = !isSelected && hasWallet;

    return GestureDetector(
      onTap: !hasWallet ? () => _showNoWalletMessage(member.fullName) : null,
      child: Opacity(
        opacity: hasWallet ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(member.fullName),
                backgroundImage:
                    member.photo != null ? NetworkImage(member.photo!) : null,
                child: member.photo == null
                    ? Text(
                        _getInitials(member.fullName),
                        style: const TextStyle(
                          fontSize: 18,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.isCurrentUser
                                ? '${member.fullName} (You)'
                                : member.fullName,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: hasWallet ? Colors.black : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _contributionPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _contributionPrimary,
                              ),
                            ),
                          ),
                        ],
                        if (!hasWallet) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No wallet',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasWallet)
                GestureDetector(
                  onTap: canAdd
                      ? () => _toggleMember(member)
                      : isSelected
                          ? () => _toggleMember(member)
                          : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _contributionPrimary : null,
                      border: Border.all(
                        color: _contributionPrimary,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isSelected ? 'Added' : 'Add',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _contributionPrimary,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ineligible',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoWalletMessage(String memberName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$memberName hasn\'t set up their wallet yet. Only members with active wallets can participate in Contributions.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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
