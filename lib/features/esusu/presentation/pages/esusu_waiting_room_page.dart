import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:intl/intl.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

class EsusuWaitingRoomPage extends ConsumerStatefulWidget {
  final String esusuId;
  final String esusuName;

  const EsusuWaitingRoomPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
  });

  @override
  ConsumerState<EsusuWaitingRoomPage> createState() => _EsusuWaitingRoomPageState();
}

class _EsusuWaitingRoomPageState extends ConsumerState<EsusuWaitingRoomPage> {
  bool _isLoading = true;
  String? _error;
  EsusuWaitingRoomDetails? _waitingRoomDetails;

  // Tab selection
  int _selectedTabIndex = 0; // 0: Accepted, 1: Pending, 2: Declined

  // Countdown timer
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWaitingRoomDetails();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWaitingRoomDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final details = await repository.getWaitingRoomDetails(widget.esusuId);
      setState(() {
        _waitingRoomDetails = details;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    if (_waitingRoomDetails == null) return;

    final startDate = _waitingRoomDetails!.startDate;
    _updateTimeRemaining(startDate);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining(startDate);
    });
  }

  void _updateTimeRemaining(DateTime startDate) {
    final now = DateTime.now();
    if (startDate.isAfter(now)) {
      setState(() {
        _timeRemaining = startDate.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _countdownTimer?.cancel();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMMM').format(date);
    final year = date.year;
    return '$day$suffix $month $year';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '₦${formatter.format(amount)}';
  }

  List<WaitingRoomParticipant> _getFilteredParticipants() {
    if (_waitingRoomDetails == null) return [];

    switch (_selectedTabIndex) {
      case 0: // Accepted
        return _waitingRoomDetails!.participants
            .where((p) => p.inviteStatus == 'ACCEPTED')
            .toList();
      case 1: // Pending
        return _waitingRoomDetails!.participants
            .where((p) => p.inviteStatus == 'INVITED')
            .toList();
      case 2: // Declined
        return _waitingRoomDetails!.participants
            .where((p) => p.inviteStatus == 'DECLINED')
            .toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerLoading()
            : _error != null
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header shimmer
            Row(
              children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 20, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 14, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Details card shimmer
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            // Countdown shimmer
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            // Tabs shimmer
            Row(
              children: [
                Container(width: 80, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                const SizedBox(width: 12),
                Container(width: 80, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                const SizedBox(width: 12),
                Container(width: 80, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              ],
            ),
            const SizedBox(height: 24),
            // Participants shimmer
            for (int i = 0; i < 4; i++) ...[
              Row(
                children: [
                  Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 160, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(width: 50, height: 16, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load waiting room',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchWaitingRoomDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: _esusuPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: AppTextStyles.fontFamily, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final details = _waitingRoomDetails!;

    return Column(
      children: [
        // Header
        _buildHeader(details),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Esusu Details Card
                _buildDetailsCard(details),
                const SizedBox(height: 16),
                // Countdown Card
                _buildCountdownCard(),
                const SizedBox(height: 24),
                // Tabs
                _buildTabs(details),
                const SizedBox(height: 16),
                // Participants List
                _buildParticipantsList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(EsusuWaitingRoomDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          // Esusu icon
          _buildEsusuImage(details.iconUrl),
          const SizedBox(width: 12),
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.name,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  details.description ?? 'Description',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: const Color(0xFF8E8E8E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // More options menu
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF333333)),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEsusuImage(String? iconUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 50,
        height: 50,
        child: iconUrl != null && iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFE0E0E0),
                  child: const Icon(Icons.groups_outlined, color: Color(0xFF9E9E9E), size: 24),
                ),
              )
            : Container(
                color: const Color(0xFFE0E0E0),
                child: const Icon(Icons.groups_outlined, color: Color(0xFF9E9E9E), size: 24),
              ),
      ),
    );
  }

  Widget _buildDetailsCard(EsusuWaitingRoomDetails details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _esusuLightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Contribution Amount', _formatCurrency(details.contributionAmount)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem('Frequency', details.frequency),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Target Members', details.targetMembers.toString()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem('Start date', _formatDate(details.startDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E8E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard() {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B30FF), Color(0xFF8B20E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 20),
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
          // Countdown boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountdownBox(days.toString(), 'Days'),
              const SizedBox(width: 12),
              _buildCountdownBox(hours.toString().padLeft(2, '0'), 'Hours'),
              const SizedBox(width: 12),
              _buildCountdownBox(minutes.toString().padLeft(2, '0'), 'Minutes'),
              const SizedBox(width: 12),
              _buildCountdownBox(seconds.toString().padLeft(2, '0'), 'Seconds'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
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
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(EsusuWaitingRoomDetails details) {
    final acceptedCount = details.participants.where((p) => p.inviteStatus == 'ACCEPTED').length;
    final pendingCount = details.participants.where((p) => p.inviteStatus == 'INVITED').length;
    final declinedCount = details.participants.where((p) => p.inviteStatus == 'DECLINED').length;

    return Row(
      children: [
        _buildTab('Accepted', acceptedCount, 0),
        const SizedBox(width: 12),
        _buildTab('Pending', pendingCount, 1),
        const SizedBox(width: 12),
        _buildTab('Declined', declinedCount, 2),
      ],
    );
  }

  Widget _buildTab(String label, int count, int index) {
    final isSelected = _selectedTabIndex == index;
    final displayLabel = count > 0 ? '$label ($count)' : label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF333333) : const Color(0xFF8E8E8E),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsList() {
    final participants = _getFilteredParticipants();

    if (participants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _selectedTabIndex == 0
                ? 'No accepted members yet'
                : _selectedTabIndex == 1
                    ? 'No pending invitations'
                    : 'No declined invitations',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: const Color(0xFF8E8E8E),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantRow(participant);
      },
    );
  }

  Widget _buildParticipantRow(WaitingRoomParticipant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Profile image
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: participant.profileImage != null && participant.profileImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: participant.profileImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(Icons.person, color: Color(0xFF9E9E9E)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(Icons.person, color: Color(0xFF9E9E9E)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Icon(Icons.person, color: Color(0xFF9E9E9E)),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.fullName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  participant.email,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    color: const Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
          // Slot number (only for accepted with slot)
          if (participant.slotNumber != null)
            Text(
              'Slot ${participant.slotNumber}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
        ],
      ),
    );
  }
}
