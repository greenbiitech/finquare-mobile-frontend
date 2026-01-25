import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:finsquare_mobile_app/features/esusu/presentation/providers/esusu_creation_provider.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class AddParticipantsPage extends ConsumerStatefulWidget {
  const AddParticipantsPage({super.key});

  @override
  ConsumerState<AddParticipantsPage> createState() => _AddParticipantsPageState();
}

class _AddParticipantsPageState extends ConsumerState<AddParticipantsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(esusuCreationProvider.notifier).loadCommunityMembers();
    });
  }

  int get _participantsLeft {
    final state = ref.read(esusuCreationProvider);
    return (state.numberOfParticipants ?? 0) - state.selectedParticipants.length;
  }

  void _showSelectMemberModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SelectMemberModal(
        onAdd: (member) {
          ref.read(esusuCreationProvider.notifier).addParticipant(member);
        },
        onRemove: (memberId) {
          ref.read(esusuCreationProvider.notifier).removeParticipant(memberId);
        },
      ),
    );
  }

  void _removeParticipant(String memberId) {
    ref.read(esusuCreationProvider.notifier).removeParticipant(memberId);
  }

  void _handleNext() {
    final state = ref.read(esusuCreationProvider);
    if (state.isParticipantsComplete) {
      context.push(AppRoutes.selectPayoutOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);
    final selectedParticipants = state.selectedParticipants;
    final totalRequired = state.numberOfParticipants ?? 0;
    final participantsLeft = totalRequired - selectedParticipants.length;

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
                      onTap: participantsLeft > 0 ? _showSelectMemberModal : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: participantsLeft > 0
                              ? const Color(0xFFF3F3F3)
                              : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              participantsLeft > 0
                                  ? 'Select Participant'
                                  : 'All participants added',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: participantsLeft > 0 ? Colors.black : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Content based on state
                    Expanded(
                      child: state.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _esusuPrimaryColor,
                              ),
                            )
                          : selectedParticipants.isEmpty
                              ? _buildEmptyState(totalRequired)
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
                isButtonEnabled: state.isParticipantsComplete,
                onPressed: _handleNext,
                title: 'Next',
                buttonColor: state.isParticipantsComplete
                    ? _esusuPrimaryColor
                    : Colors.grey.shade400,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(int totalRequired) {
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
          '$totalRequired required',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _esusuPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select participants from your community members',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF606060),
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
      List<EsusuCommunityMember> participants, int participantsLeft) {
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
                color:
                    participantsLeft > 0 ? _esusuPrimaryColor : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: participants.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _buildParticipantTile(participant);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(EsusuCommunityMember participant) {
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
                        participant.fullName,
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
                          color: _esusuPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _esusuPrimaryColor,
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
    final parts = name.split(' ');
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
  final Function(EsusuCommunityMember) onAdd;
  final Function(String) onRemove;

  const _SelectMemberModal({
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

  List<EsusuCommunityMember> _getFilteredMembers(
      List<EsusuCommunityMember> members) {
    if (_searchQuery.isEmpty) return members;
    return members
        .where((member) =>
            member.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            member.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  bool _isAlreadySelected(
      EsusuCommunityMember member, List<EsusuCommunityMember> selectedParticipants) {
    return selectedParticipants.any((p) => p.id == member.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esusuCreationProvider);
    final availableMembers = state.availableMembers;
    final selectedParticipants = state.selectedParticipants;
    final filteredMembers = _getFilteredMembers(availableMembers);
    final participantsLeft =
        (state.numberOfParticipants ?? 0) - selectedParticipants.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Member',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '$participantsLeft left',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _esusuPrimaryColor,
                        ),
                      ),
                    ],
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
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _esusuPrimaryColor,
                      ),
                    )
                  : filteredMembers.isEmpty
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
                            final isSelected =
                                _isAlreadySelected(member, selectedParticipants);
                            return _buildMemberTile(
                              member,
                              isSelected,
                              participantsLeft,
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: () => Navigator.pop(context),
                title: 'Done',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberTile(
    EsusuCommunityMember member,
    bool isSelected,
    int participantsLeft,
  ) {
    final canAdd = !isSelected && participantsLeft > 0;

    return Padding(
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
                        member.fullName,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _esusuPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _esusuPrimaryColor,
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
          GestureDetector(
            onTap: canAdd
                ? () {
                    widget.onAdd(member);
                    setState(() {});
                  }
                : isSelected
                    ? () {
                        widget.onRemove(member.id);
                        setState(() {});
                      }
                    : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _esusuPrimaryColor : null,
                border: Border.all(
                  color: canAdd || isSelected
                      ? _esusuPrimaryColor
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSelected ? 'Added' : 'Add',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : canAdd
                          ? _esusuPrimaryColor
                          : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
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
