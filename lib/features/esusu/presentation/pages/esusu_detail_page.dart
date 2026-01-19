import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

enum ParticipantStatus {
  accepted,
  pending,
  declined,
}

class EsusuDetailPage extends StatefulWidget {
  final String esusuId;
  final String esusuName;

  const EsusuDetailPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
  });

  @override
  State<EsusuDetailPage> createState() => _EsusuDetailPageState();
}

class _EsusuDetailPageState extends State<EsusuDetailPage> {
  int _selectedTabIndex = 0; // 0 = Accepted, 1 = Pending, 2 = Declined

  // Dummy data
  final List<_Participant> _acceptedParticipants = [
    _Participant(
      name: 'Chinelo Okafor',
      email: 'ChineloO@gmail.com',
      avatarColor: Colors.brown.shade300,
      slot: 1,
    ),
    _Participant(
      name: 'Adaobi Nwankwo',
      email: 'AdaobiN@gmail.com',
      avatarColor: Colors.brown.shade400,
      slot: 5,
    ),
    _Participant(
      name: 'Emeka Uche',
      email: 'EmekaU@gmail.com',
      avatarColor: Colors.orange.shade300,
      slot: 3,
    ),
    _Participant(
      name: 'Ifeoma Ajayi',
      email: 'IfeomaA@gmail.com',
      avatarColor: Colors.brown.shade200,
      slot: 2,
    ),
  ];

  final List<_Participant> _pendingParticipants = [
    _Participant(
      name: 'Adeola Adebayo',
      email: 'Adeola@gmail.com',
      avatarColor: Colors.brown.shade300,
    ),
    _Participant(
      name: 'Fatima Abubakar',
      email: 'Fatima@gmail.com',
      avatarColor: Colors.brown.shade400,
    ),
    _Participant(
      name: 'Chinedu Okafor',
      email: 'Chinedu@gmail.com',
      avatarColor: Colors.brown.shade500,
    ),
    _Participant(
      name: 'Emeka Nwosu',
      email: 'Emeka@gmail.com',
      avatarColor: Colors.brown.shade300,
    ),
    _Participant(
      name: 'Chinwe Okafor',
      email: 'Chinwe.Okafor@example.com',
      avatarColor: Colors.brown.shade200,
    ),
  ];

  final List<_Participant> _declinedParticipants = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  // Icon placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.esusuName,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Show menu
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.black,
                    ),
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
                    // Info Card
                    _buildInfoCard(),
                    const SizedBox(height: 16),

                    // Countdown Card
                    _buildCountdownCard(),
                    const SizedBox(height: 20),

                    // Tabs
                    Row(
                      children: [
                        _buildTab('Accepted', 0),
                        const SizedBox(width: 12),
                        _buildTab('Pending', 1),
                        const SizedBox(width: 12),
                        _buildTab('Declined', 2),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Participants list
                    _buildParticipantsList(),
                  ],
                ),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: () {
                  // TODO: Remind participants
                },
                title: 'Remind participants',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _esusuLightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Contribution Amount', '\u20A65000'),
              ),
              Expanded(
                child: _buildInfoItem('Frequency', 'Monthly'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Target Members', '12'),
              ),
              Expanded(
                child: _buildInfoItem('Start date', '30th may 2025'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF606060),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _esusuPrimaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Esusu Starts in',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountdownItem('1', 'Days'),
              const SizedBox(width: 12),
              _buildCountdownItem('10', 'Hours'),
              const SizedBox(width: 12),
              _buildCountdownItem('20', 'Minutes'),
              const SizedBox(width: 12),
              _buildCountdownItem('27', 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Color(0xFF6B1CB5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
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
          color: isSelected ? _esusuLightColor : Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: _esusuPrimaryColor, width: 1) : null,
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

  Widget _buildParticipantsList() {
    List<_Participant> currentList;
    switch (_selectedTabIndex) {
      case 0:
        currentList = _acceptedParticipants;
        break;
      case 1:
        currentList = _pendingParticipants;
        break;
      case 2:
        currentList = _declinedParticipants;
        break;
      default:
        currentList = [];
    }

    if (currentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No participants',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentList.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final participant = currentList[index];
        return _buildParticipantTile(participant);
      },
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
              participant.name[0],
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
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
          // Show slot for accepted, loading icon for pending
          if (_selectedTabIndex == 0 && participant.slot != null)
            Text(
              'Slot ${participant.slot}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            )
          else if (_selectedTabIndex == 1)
            Icon(
              Icons.hourglass_empty,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _Participant {
  final String name;
  final String email;
  final Color avatarColor;
  final int? slot;

  _Participant({
    required this.name,
    required this.email,
    required this.avatarColor,
    this.slot,
  });
}
