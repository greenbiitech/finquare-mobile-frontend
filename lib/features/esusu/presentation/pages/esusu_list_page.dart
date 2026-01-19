import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

enum EsusuStatus {
  active,
  pendingMembers,
  archived,
}

class EsusuListPage extends StatefulWidget {
  const EsusuListPage({super.key});

  @override
  State<EsusuListPage> createState() => _EsusuListPageState();
}

class _EsusuListPageState extends State<EsusuListPage> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Archived

  // Dummy data
  final List<_EsusuItem> _activeEsusus = [
    _EsusuItem(
      id: '1',
      name: 'Savings Circle',
      status: EsusuStatus.active,
      amountPerCycle: 5000,
      participants: 20,
      frequency: 'Monthly payments',
      daysTillPayout: 20,
      progress: 0.4,
    ),
    _EsusuItem(
      id: '2',
      name: 'Esusu Group A',
      status: EsusuStatus.pendingMembers,
      amountPerCycle: 4500,
      participants: 20,
      frequency: 'Monthly payments',
      daysTillPayout: null,
      progress: null,
    ),
    _EsusuItem(
      id: '3',
      name: 'Esusu for may',
      status: EsusuStatus.active,
      amountPerCycle: 2000,
      participants: 20,
      frequency: 'Weekly Payments',
      daysTillPayout: 20,
      progress: 0.4,
    ),
  ];

  final List<_EsusuItem> _archivedEsusus = [];

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTabIndex == 0 ? _activeEsusus : _archivedEsusus;

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
                  const SizedBox(width: 20),
                  Text(
                    'Esusu',
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

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTab('Active', 0),
                  const SizedBox(width: 12),
                  _buildTab('Archived', 1),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List
            Expanded(
              child: currentList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: currentList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildEsusuCard(currentList[index]);
                      },
                    ),
            ),
          ],
        ),
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
          color: isSelected ? Color(0xFFEBDAFB) : Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Color(0xFF8B20E9), width: 1) : null,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedTabIndex == 0 ? 'active' : 'archived'} Esusu',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF606060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEsusuCard(_EsusuItem item) {
    return GestureDetector(
      onTap: () {
        if (item.status == EsusuStatus.pendingMembers) {
          // Navigate to pending members detail page
          context.push('${AppRoutes.esusuDetail}/${item.id}?name=${Uri.encodeComponent(item.name)}');
        } else if (item.status == EsusuStatus.active) {
          // Navigate to active esusu detail page
          context.push('${AppRoutes.activeEsusuDetail}/${item.id}?name=${Uri.encodeComponent(item.name)}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              color: _esusuLightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svgs/hub/esusu.svg',
                width: 40,
                height: 40,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),

                // Status and Amount row
                Row(
                  children: [
                    _buildStatusChip(item.status),
                    const SizedBox(width: 8),
                    _buildChip('\u20A6${_formatAmount(item.amountPerCycle)}/cycle', _esusuLightColor, _esusuPrimaryColor),
                  ],
                ),
                const SizedBox(height: 8),

                // Participants and Frequency row
                Row(
                  children: [
                    _buildChip('${item.participants} Participants', _esusuLightColor, _esusuPrimaryColor),
                    const SizedBox(width: 8),
                    _buildChip(item.frequency, _esusuLightColor, _esusuPrimaryColor),
                  ],
                ),

                // Progress bar (only for active status)
                if (item.status == EsusuStatus.active && item.progress != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: item.progress!,
                            backgroundColor: Color(0xFFFFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(_esusuPrimaryColor),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.daysTillPayout} days till payout',
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
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatusChip(EsusuStatus status) {
    Color bgColor;
    Color textColor;
    String text;

    switch (status) {
      case EsusuStatus.active:
        bgColor = Color(0xFFD0F5CE);
        textColor = Color(0xFF333333);
        text = 'Active';
        break;
      case EsusuStatus.pendingMembers:
        bgColor = Color(0xFFFAEFBF);
        textColor = Color(0xFF333333);
        text = 'Pending Members';
        break;
      case EsusuStatus.archived:
        bgColor = Color(0xFFE0E0E0);
        textColor = Color(0xFF606060);
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)},000';
    }
    return amount.toStringAsFixed(0);
  }
}

class _EsusuItem {
  final String id;
  final String name;
  final EsusuStatus status;
  final double amountPerCycle;
  final int participants;
  final String frequency;
  final int? daysTillPayout;
  final double? progress;

  _EsusuItem({
    required this.id,
    required this.name,
    required this.status,
    required this.amountPerCycle,
    required this.participants,
    required this.frequency,
    this.daysTillPayout,
    this.progress,
  });
}
