import 'package:flutter/material.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

enum ContributionStatus {
  paid,
  notPaid,
  late,
}

enum PayoutStatus {
  successful,
  nextReceiver,
  pending,
}

class ActiveEsusuDetailPage extends StatefulWidget {
  final String esusuId;
  final String esusuName;

  const ActiveEsusuDetailPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
  });

  @override
  State<ActiveEsusuDetailPage> createState() => _ActiveEsusuDetailPageState();
}

class _ActiveEsusuDetailPageState extends State<ActiveEsusuDetailPage> {
  int _selectedTabIndex = 0; // 0 = Contribution status, 1 = Payout Order, 2 = Transaction history
  bool _isAmountVisible = true;

  // Dummy data for Contribution Status
  final List<_ContributionParticipant> _contributionParticipants = [
    _ContributionParticipant(
      name: 'Chinelo Okafor',
      email: 'ChineloO@gmail.com',
      avatarColor: Colors.brown.shade300,
      status: ContributionStatus.paid,
      isMe: true,
    ),
    _ContributionParticipant(
      name: 'Adaobi Nwankwo',
      email: 'AdaobiN@gmail.com',
      avatarColor: Colors.brown.shade400,
      status: ContributionStatus.notPaid,
    ),
    _ContributionParticipant(
      name: 'Emeka Uche',
      email: 'EmekaU@gmail.com',
      avatarColor: Colors.orange.shade300,
      status: ContributionStatus.paid,
    ),
    _ContributionParticipant(
      name: 'Ifeoma Ajayi',
      email: 'IfeomaA@gmail.com',
      avatarColor: Colors.brown.shade200,
      status: ContributionStatus.late,
    ),
  ];

  // Dummy data for Payout Order
  final List<_PayoutParticipant> _payoutParticipants = [
    _PayoutParticipant(
      name: 'Chinelo Okafor',
      avatarColor: Colors.brown.shade300,
      slot: 1,
      status: PayoutStatus.successful,
      isMe: true,
    ),
    _PayoutParticipant(
      name: 'Adaobi Nwankwo',
      avatarColor: Colors.brown.shade400,
      slot: 2,
      status: PayoutStatus.successful,
    ),
    _PayoutParticipant(
      name: 'Kemi Falana',
      avatarColor: Colors.brown.shade300,
      slot: 3,
      status: PayoutStatus.nextReceiver,
    ),
    _PayoutParticipant(
      name: 'Emeka Uche',
      avatarColor: Colors.orange.shade300,
      slot: 4,
      status: PayoutStatus.pending,
    ),
    _PayoutParticipant(
      name: 'Ifeoma Ajayi',
      avatarColor: Colors.brown.shade200,
      slot: 5,
      status: PayoutStatus.pending,
    ),
  ];

  // Dummy data for Transaction History
  final List<_TransactionCycle> _transactionCycles = [
    _TransactionCycle(
      cycleName: '3rd cycle',
      dateRange: 'Apr 01 - Apr 30',
      transactions: [
        _Transaction(name: 'Chinelo Okafor', avatarColor: Colors.brown.shade300, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
        _Transaction(name: 'Adaobi Nwankwo', avatarColor: Colors.brown.shade400, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
        _Transaction(name: 'Emeka Uche', avatarColor: Colors.orange.shade300, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
        _Transaction(name: 'Ifeoma Ajayi', avatarColor: Colors.brown.shade200, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
      ],
    ),
    _TransactionCycle(
      cycleName: '2nd cycle',
      dateRange: 'Mar 01 - Mar 30',
      transactions: [
        _Transaction(name: 'Adaobi Nwankwo', avatarColor: Colors.brown.shade400, type: 'Payout', date: '29 March 2025', amount: '-₦60,000', isPayout: true),
        _Transaction(name: 'Chinelo Okafor', avatarColor: Colors.brown.shade300, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
        _Transaction(name: 'Adaobi Nwankwo', avatarColor: Colors.brown.shade400, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
        _Transaction(name: 'Emeka Uche', avatarColor: Colors.orange.shade300, type: 'Payment', date: '32 Apr 2025', amount: '+₦5,000'),
      ],
    ),
    _TransactionCycle(
      cycleName: '1st cycle',
      dateRange: 'Feb 01 - Feb 30',
      transactions: [
        _Transaction(name: 'Adaobi Nwankwo', avatarColor: Colors.brown.shade400, type: 'Payout', date: '29 March 2025', amount: '₦60,000', isPayout: true),
      ],
    ),
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
                          'Our group savings',
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
                    // Pool Card
                    _buildPoolCard(),
                    const SizedBox(height: 20),

                    // Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTab('Contribution status', 0),
                          const SizedBox(width: 12),
                          _buildTab('Payout Order', 1),
                          const SizedBox(width: 12),
                          _buildTab('Transaction history', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tab content
                    _buildTabContent(),
                  ],
                ),
              ),
            ),

            // Make Payment Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: () {
                  // TODO: Make payment
                },
                title: 'Make Payment',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _esusuLightColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Current pool and cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current pool',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606060),
                ),
              ),
              Text(
                '3rd cycle',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _esusuPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Amount with visibility toggle
          Row(
            children: [
              Text(
                _isAmountVisible ? '₦35,000' : '₦*****',
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
                    color: Color(0xFFD8C4ED),
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
            color: Color(0xFFD8C4ED),
          ),
          const SizedBox(height: 12),

          // Next receiver and payout date
          Row(
            children: [
              // Avatar
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
                      'Next Reciever',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF606060),
                      ),
                    ),
                    Text(
                      'Kemi Falana',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Payout date',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606060),
                    ),
                  ),
                  Text(
                    '30th may 2025',
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
                    value: 0.4,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(_esusuPrimaryColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '20 days till payout',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606060),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildContributionStatusList();
      case 1:
        return _buildPayoutOrderList();
      case 2:
        return _buildTransactionHistoryList();
      default:
        return const SizedBox();
    }
  }

  // Tab 1: Contribution Status
  Widget _buildContributionStatusList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contributionParticipants.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final participant = _contributionParticipants[index];
        return _buildContributionTile(participant);
      },
    );
  }

  Widget _buildContributionTile(_ContributionParticipant participant) {
    Color statusColor;
    String statusText;

    switch (participant.status) {
      case ContributionStatus.paid:
        statusColor = Color(0xFF4CAF50);
        statusText = 'Paid';
        break;
      case ContributionStatus.notPaid:
        statusColor = Color(0xFFE53935);
        statusText = 'Not paid';
        break;
      case ContributionStatus.late:
        statusColor = Color(0xFFFFA726);
        statusText = 'Late';
        break;
    }

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
                Row(
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
                    if (participant.isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Me',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF606060),
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
                    color: Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: Payout Order
  Widget _buildPayoutOrderList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payoutParticipants.length,
      separatorBuilder: (context, index) {
        // No divider before/after the highlighted item
        if (_payoutParticipants[index].status == PayoutStatus.nextReceiver ||
            (index + 1 < _payoutParticipants.length && _payoutParticipants[index + 1].status == PayoutStatus.nextReceiver)) {
          return const SizedBox(height: 0);
        }
        return const Divider(height: 1, color: Color(0xFFE0E0E0));
      },
      itemBuilder: (context, index) {
        final participant = _payoutParticipants[index];
        return _buildPayoutTile(participant);
      },
    );
  }

  Widget _buildPayoutTile(_PayoutParticipant participant) {
    final isNextReceiver = participant.status == PayoutStatus.nextReceiver;

    String statusText;
    Color? statusColor;

    switch (participant.status) {
      case PayoutStatus.successful:
        statusText = 'Payout\nsuccessful';
        statusColor = Colors.black;
        break;
      case PayoutStatus.nextReceiver:
        statusText = 'Next\nReceiver';
        statusColor = _esusuPrimaryColor;
        break;
      case PayoutStatus.pending:
        statusText = '-';
        statusColor = Colors.black;
        break;
    }

    return Container(
      color: isNextReceiver ? Color(0xFFF5F5F5) : Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: isNextReceiver ? 8 : 0),
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
                  'Slot ${participant.slot}',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF606060),
                  ),
                ),
                Row(
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
                    if (participant.isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Me',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF606060),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            statusText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Tab 3: Transaction History
  Widget _buildTransactionHistoryList() {
    return Column(
      children: _transactionCycles.map((cycle) => _buildCycleSection(cycle)).toList(),
    );
  }

  Widget _buildCycleSection(_TransactionCycle cycle) {
    return Column(
      children: [
        // Cycle header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cycle.cycleName,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                cycle.dateRange,
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
        // Transactions
        ...cycle.transactions.map((transaction) => _buildTransactionTile(transaction)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTransactionTile(_Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: transaction.avatarColor,
            child: Text(
              transaction.name[0],
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
                  transaction.name,
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
                        color: transaction.isPayout ? Color(0xFFFFE0E0) : Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.type,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: transaction.isPayout ? Color(0xFFE53935) : Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      transaction.date,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF606060),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            transaction.amount,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes
class _ContributionParticipant {
  final String name;
  final String email;
  final Color avatarColor;
  final ContributionStatus status;
  final bool isMe;

  _ContributionParticipant({
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.status,
    this.isMe = false,
  });
}

class _PayoutParticipant {
  final String name;
  final Color avatarColor;
  final int slot;
  final PayoutStatus status;
  final bool isMe;

  _PayoutParticipant({
    required this.name,
    required this.avatarColor,
    required this.slot,
    required this.status,
    this.isMe = false,
  });
}

class _TransactionCycle {
  final String cycleName;
  final String dateRange;
  final List<_Transaction> transactions;

  _TransactionCycle({
    required this.cycleName,
    required this.dateRange,
    required this.transactions,
  });
}

class _Transaction {
  final String name;
  final Color avatarColor;
  final String type;
  final String date;
  final String amount;
  final bool isPayout;

  _Transaction({
    required this.name,
    required this.avatarColor,
    required this.type,
    required this.date,
    required this.amount,
    this.isPayout = false,
  });
}
