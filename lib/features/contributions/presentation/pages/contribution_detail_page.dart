import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_payment_page.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);

class ContributionDetailPage extends StatefulWidget {
  final String contributionId;
  final String contributionName;
  final PaymentContributionType contributionType;
  final String recipientName;
  final double? fixedAmount;
  final double? targetAmount;
  final double? contributedSoFar;

  const ContributionDetailPage({
    super.key,
    required this.contributionId,
    required this.contributionName,
    required this.contributionType,
    required this.recipientName,
    this.fixedAmount,
    this.targetAmount,
    this.contributedSoFar,
  });

  @override
  State<ContributionDetailPage> createState() => _ContributionDetailPageState();
}

class _ContributionDetailPageState extends State<ContributionDetailPage> {
  int _selectedTabIndex = 0; // 0 = Contributions, 1 = Participants
  bool _isAmountVisible = true;

  // Mock data for contributions list
  final List<_ContributionEntry> _contributions = [
    _ContributionEntry(
      name: 'Chinelo Okafor',
      avatarColor: Colors.brown.shade300,
      date: '32 Apr 2025',
      amount: 56000,
    ),
    _ContributionEntry(
      name: 'Adaobi Nwankwo',
      avatarColor: Colors.brown.shade400,
      date: '32 Apr 2025',
      amount: 50000,
    ),
    _ContributionEntry(
      name: 'Emeka Uche',
      avatarColor: Colors.orange.shade300,
      date: '32 Apr 2025',
      amount: 20000,
    ),
    _ContributionEntry(
      name: 'Ifeoma Ajayi',
      avatarColor: Colors.brown.shade200,
      date: '32 Apr 2025',
      amount: 85000,
    ),
    _ContributionEntry(
      name: 'Chukwuma Ihedioha',
      avatarColor: Colors.brown.shade300,
      date: '01 May 2025',
      amount: 72500,
    ),
    _ContributionEntry(
      name: 'Nneka Eze',
      avatarColor: Colors.brown.shade400,
      date: '01 May 2025',
      amount: 80000,
    ),
  ];

  // Mock data for participants
  final List<_Participant> _participants = [
    _Participant(name: 'Chinelo Okafor', email: 'ChineloO@gmail.com', avatarColor: Colors.brown.shade300),
    _Participant(name: 'Adaobi Nwankwo', email: 'AdaobiN@gmail.com', avatarColor: Colors.brown.shade400),
    _Participant(name: 'Emeka Uche', email: 'EmekaU@gmail.com', avatarColor: Colors.orange.shade300),
    _Participant(name: 'Ifeoma Ajayi', email: 'IfeomaA@gmail.com', avatarColor: Colors.brown.shade200),
    _Participant(name: 'Chukwuma Ihedioha', email: 'ChukwumaI@gmail.com', avatarColor: Colors.brown.shade300),
    _Participant(name: 'Nneka Eze', email: 'NnekaE@gmail.com', avatarColor: Colors.brown.shade400),
  ];

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
                  // Contribution image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF59D), // Yellow background
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            widget.contributionName.isNotEmpty
                                ? widget.contributionName[0].toUpperCase()
                                : 'C',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _contributionPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contributionName,
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
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Show menu
                    },
                    icon: const Icon(
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
                    // Summary Card
                    _buildSummaryCard(),
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
                    _buildTabContent(),
                  ],
                ),
              ),
            ),

            // Make Contribution Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _navigateToPayment,
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
        ),
      ),
    );
  }

  void _navigateToPayment() {
    // Determine the amount based on contribution type
    double amount;
    switch (widget.contributionType) {
      case PaymentContributionType.fixed:
        amount = widget.fixedAmount ?? 5000.0;
        break;
      case PaymentContributionType.target:
        amount = widget.targetAmount ?? 0.0;
        break;
      case PaymentContributionType.flexible:
        amount = 0.0; // User will enter amount
        break;
    }

    context.push(
      AppRoutes.contributionPayment,
      extra: {
        'contributionId': widget.contributionId,
        'contributionName': widget.contributionName,
        'recipientName': widget.recipientName,
        'amount': amount,
        'contributionType': widget.contributionType,
        'contributedSoFar': widget.contributedSoFar,
      },
    );
  }

  Widget _buildSummaryCard() {
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
                _isAmountVisible ? '₦363,000' : '₦*****',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                _isAmountVisible ? '.00' : '',
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCCDD),
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
          Container(
            height: 1,
            color: const Color(0xFFFFCCDD),
          ),
          const SizedBox(height: 12),

          // Recipient and Deadline row
          Row(
            children: [
              // Recipient
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.brown.shade300,
                child: Text(
                  'K',
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
                      'Reciepient',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    Text(
                      'Kemi John',
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
                    '30th may 2026',
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
          const SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.73, // 363,000 / 500,000 = 72.6%
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(_contributionPrimary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₦137,000 till target',
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
          border: isSelected ? Border.all(color: _contributionPrimary, width: 1) : null,
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

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildContributionsList();
      case 1:
        return _buildParticipantsList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildContributionsList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _contributions.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE0E0E0),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final contribution = _contributions[index];
          return _buildContributionTile(contribution);
        },
      ),
    );
  }

  Widget _buildContributionTile(_ContributionEntry contribution) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: contribution.avatarColor,
            child: Text(
              contribution.name[0],
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
                  contribution.name,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _contributionLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Contribution',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _contributionPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      contribution.date,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+₦${_formatAmount(contribution.amount)}',
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

  Widget _buildParticipantsList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _participants.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE0E0E0),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return _buildParticipantTile(participant);
        },
      ),
    );
  }

  Widget _buildParticipantTile(_Participant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    color: const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

// Data classes
class _ContributionEntry {
  final String name;
  final Color avatarColor;
  final String date;
  final double amount;

  _ContributionEntry({
    required this.name,
    required this.avatarColor,
    required this.date,
    required this.amount,
  });
}

class _Participant {
  final String name;
  final String email;
  final Color avatarColor;

  _Participant({
    required this.name,
    required this.email,
    required this.avatarColor,
  });
}
