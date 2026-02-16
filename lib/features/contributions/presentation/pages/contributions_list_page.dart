import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/contributions/presentation/pages/contribution_payment_page.dart';

const Color _contributionPrimary = Color(0xFFF83181);
const Color _contributionLight = Color(0xFFFFE0ED);

/// Mock contribution model for list display
class _MockContribution {
  final String id;
  final String name;
  final String? imageUrl;
  final String recipientName;
  final String? recipientPhotoUrl;
  final String status; // 'active', 'completed', 'cancelled'
  final String secondaryTag; // e.g., "Flexible payments", "₦5,000 person"
  final double progress; // 0.0 to 1.0
  final int daysLeft;
  final bool isArchived;
  final PaymentContributionType contributionType;
  final double? fixedAmount; // For fixed type
  final double? targetAmount; // For target type
  final double? contributedSoFar; // For target type

  const _MockContribution({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.recipientName,
    this.recipientPhotoUrl,
    required this.status,
    required this.secondaryTag,
    required this.progress,
    required this.daysLeft,
    this.isArchived = false,
    required this.contributionType,
    this.fixedAmount,
    this.targetAmount,
    this.contributedSoFar,
  });
}

/// Mock data for contributions
final List<_MockContribution> _mockContributions = [
  const _MockContribution(
    id: '1',
    name: "Kemi's Wedding",
    imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    recipientName: 'Kemi Falana',
    status: 'active',
    secondaryTag: 'Flexible payments',
    progress: 0.4,
    daysLeft: 20,
    contributionType: PaymentContributionType.flexible,
  ),
  const _MockContribution(
    id: '2',
    name: 'Cooperative Hangout',
    recipientName: 'Cooperative wallet',
    status: 'active',
    secondaryTag: '₦5,000 person',
    progress: 0.5,
    daysLeft: 20,
    contributionType: PaymentContributionType.fixed,
    fixedAmount: 5000,
  ),
  const _MockContribution(
    id: '3',
    name: "John's Surgery",
    recipientName: 'John Ifunanya',
    status: 'active',
    secondaryTag: '₦200,000 target',
    progress: 0.6,
    daysLeft: 20,
    contributionType: PaymentContributionType.target,
    targetAmount: 200000,
    contributedSoFar: 120000,
  ),
  // Archived contributions
  const _MockContribution(
    id: '4',
    name: "Sarah's Birthday",
    recipientName: 'Sarah Adams',
    status: 'completed',
    secondaryTag: '₦50,000 target',
    progress: 1.0,
    daysLeft: 0,
    isArchived: true,
    contributionType: PaymentContributionType.target,
    targetAmount: 50000,
    contributedSoFar: 50000,
  ),
];

class ContributionsListPage extends ConsumerStatefulWidget {
  const ContributionsListPage({super.key});

  @override
  ConsumerState<ContributionsListPage> createState() =>
      _ContributionsListPageState();
}

class _ContributionsListPageState extends ConsumerState<ContributionsListPage> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Archived

  List<_MockContribution> get _activeContributions =>
      _mockContributions.where((c) => !c.isArchived).toList();

  List<_MockContribution> get _archivedContributions =>
      _mockContributions.where((c) => c.isArchived).toList();

  @override
  Widget build(BuildContext context) {
    final currentList =
        _selectedTabIndex == 0 ? _activeContributions : _archivedContributions;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.contributionsWelcome);
        },
        backgroundColor: _contributionPrimary,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
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
                    'Contributions',
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

            // Content
            Expanded(
              child: currentList.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: currentList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildContributionCard(currentList[index]);
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
          color: isSelected ? _contributionLight : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _contributionPrimary, width: 1)
              : null,
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
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Color(0xFF9E9E9E),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_selectedTabIndex == 0 ? 'active' : 'archived'} contributions',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF606060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(_MockContribution item) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${AppRoutes.contributionDetail}/${item.id}?name=${Uri.encodeComponent(item.name)}',
          extra: {
            'contributionType': item.contributionType,
            'recipientName': item.recipientName,
            'fixedAmount': item.fixedAmount,
            'targetAmount': item.targetAmount,
            'contributedSoFar': item.contributedSoFar,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            _buildContributionImage(item.imageUrl),
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
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Recipient row
                  Row(
                    children: [
                      _buildRecipientAvatar(item.recipientName, item.recipientPhotoUrl),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reciepient',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF606060),
                              ),
                            ),
                            Text(
                              item.recipientName,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status and Secondary tag row
                  Row(
                    children: [
                      _buildStatusChip(item.status),
                      const SizedBox(width: 8),
                      _buildChip(
                        item.secondaryTag,
                        _contributionLight,
                      ),
                    ],
                  ),

                  // Progress bar (only for active)
                  if (item.status == 'active') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  _contributionPrimary),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.daysLeft} days till Deadline',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionImage(String? imageUrl) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (!hasImage) {
      // Default icon when no image
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _contributionLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/svgs/hub/contributions.svg',
            width: 48,
            height: 48,
            colorFilter: const ColorFilter.mode(
              _contributionPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    // Network image
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _contributionLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/svgs/hub/contributions.svg',
              width: 48,
              height: 48,
              colorFilter: const ColorFilter.mode(
                _contributionPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientAvatar(String name, String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    String text;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFD0F5CE);
        text = 'Active';
        break;
      case 'completed':
        bgColor = const Color(0xFFE0E0E0);
        text = 'Completed';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFFE0E0);
        text = 'Cancelled';
        break;
      default:
        bgColor = const Color(0xFFFAEFBF);
        text = 'Pending';
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
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bgColor) {
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
          color: const Color(0xFF333333),
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
