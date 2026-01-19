import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class AddParticipantsPage extends StatefulWidget {
  final int totalParticipants;

  const AddParticipantsPage({
    super.key,
    this.totalParticipants = 12,
  });

  @override
  State<AddParticipantsPage> createState() => _AddParticipantsPageState();
}

class _AddParticipantsPageState extends State<AddParticipantsPage> {
  final List<_Participant> _selectedParticipants = [];
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for available members
  final List<_Participant> _availableMembers = [
    _Participant(
      id: '1',
      name: 'Chinonso Okafor',
      email: 'Chinonso@gmail.com',
      avatarColor: Colors.red.shade200,
      emoji: '👩‍🦱',
    ),
    _Participant(
      id: '2',
      name: 'Adeola Adebayo',
      email: 'Adeola@gmail.com',
      avatarColor: Colors.yellow.shade200,
      emoji: '👩',
    ),
    _Participant(
      id: '3',
      name: 'Ngozi Nwosu',
      email: 'Ngozi@gmail.com',
      avatarColor: Colors.purple.shade200,
      emoji: '👩‍🦳',
    ),
    _Participant(
      id: '4',
      name: 'Emeka Ibe',
      email: 'Emeka@gmail.com',
      avatarColor: Colors.pink.shade200,
      emoji: '👨‍🦱',
    ),
    _Participant(
      id: '5',
      name: 'Ify Uche',
      email: 'Ify@gmail.com',
      avatarColor: Colors.orange.shade200,
      emoji: '👨',
    ),
    _Participant(
      id: '6',
      name: 'Tunde Alabi',
      email: 'Tunde@gmail.com',
      avatarColor: Colors.amber.shade200,
      emoji: '👱',
    ),
    _Participant(
      id: '7',
      name: 'Emeka Nwosu',
      email: 'Emeka.nwosu@example.com',
      avatarColor: Colors.pink.shade200,
      emoji: '👨‍🦰',
    ),
    _Participant(
      id: '8',
      name: 'Adaobi Eze',
      email: 'Adaobi.eze@yahoo.com',
      avatarColor: Colors.blue.shade200,
      emoji: '👩‍🦰',
    ),
    _Participant(
      id: '9',
      name: 'Uche Nwankwo',
      email: 'Uche.nwankwo@outlook.com',
      avatarColor: Colors.pink.shade200,
      emoji: '🧔',
    ),
  ];

  int get _participantsLeft => widget.totalParticipants - _selectedParticipants.length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        availableMembers: _availableMembers,
        selectedParticipants: _selectedParticipants,
        onAdd: (participant) {
          if (_participantsLeft > 0) {
            setState(() {
              _selectedParticipants.add(participant);
            });
          }
        },
        searchController: _searchController,
      ),
    );
  }

  void _removeParticipant(_Participant participant) {
    setState(() {
      _selectedParticipants.removeWhere((p) => p.id == participant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: _showSelectMemberModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F3F3),
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
                                color: Color(0xFF606060),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Content based on state
                    Expanded(
                      child: _selectedParticipants.isEmpty
                          ? _buildEmptyState()
                          : _buildParticipantsList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: _selectedParticipants.isNotEmpty,
                onPressed: () {
                  context.push(AppRoutes.selectPayoutOrder);
                },
                title: 'Next',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          '$_participantsLeft left',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _esusuPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invite your participants to join this savings plan,',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF606060),
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
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
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
              '$_participantsLeft left',
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
        Expanded(
          child: ListView.separated(
            itemCount: _selectedParticipants.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (context, index) {
              final participant = _selectedParticipants[index];
              return _buildParticipantTile(participant);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(_Participant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: participant.avatarColor,
            child: Text(
              participant.emoji,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  participant.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeParticipant(participant),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
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
}

class _SelectMemberModal extends StatefulWidget {
  final List<_Participant> availableMembers;
  final List<_Participant> selectedParticipants;
  final Function(_Participant) onAdd;
  final TextEditingController searchController;

  const _SelectMemberModal({
    required this.availableMembers,
    required this.selectedParticipants,
    required this.onAdd,
    required this.searchController,
  });

  @override
  State<_SelectMemberModal> createState() => _SelectMemberModalState();
}

class _SelectMemberModalState extends State<_SelectMemberModal> {
  late List<_Participant> _filteredMembers;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredMembers = widget.availableMembers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = widget.availableMembers;
      } else {
        _filteredMembers = widget.availableMembers
            .where((member) =>
                member.name.toLowerCase().contains(query.toLowerCase()) ||
                member.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  bool _isAlreadySelected(_Participant participant) {
    return widget.selectedParticipants.any((p) => p.id == participant.id);
  }

  @override
  Widget build(BuildContext context) {
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
                color: Color(0xFFE0E0E0),
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
                      color: Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterMembers,
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
                          color: Color(0xFF9E9E9E),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF606060),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredMembers.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
                  final isSelected = _isAlreadySelected(member);
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
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberTile(_Participant member, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: member.avatarColor,
            child: Text(
              member.emoji,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  member.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isSelected
                ? null
                : () {
                    widget.onAdd(member);
                    setState(() {});
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _esusuPrimaryColor : null,
                border: Border.all(
                  color: _esusuPrimaryColor,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSelected ? 'Added' : 'Add',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : _esusuPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Participant {
  final String id;
  final String name;
  final String email;
  final Color avatarColor;
  final String emoji;

  _Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.emoji,
  });
}
