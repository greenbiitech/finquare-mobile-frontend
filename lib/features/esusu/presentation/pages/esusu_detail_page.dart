import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:intl/intl.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);

class EsusuDetailPage extends ConsumerStatefulWidget {
  final String esusuId;
  final String esusuName;

  const EsusuDetailPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
  });

  @override
  ConsumerState<EsusuDetailPage> createState() => _EsusuDetailPageState();
}

class _EsusuDetailPageState extends ConsumerState<EsusuDetailPage> {
  int _selectedTabIndex = 0; // 0 = Accepted, 1 = Pending, 2 = Declined
  bool _isLoading = true;
  bool _isReminding = false;
  String? _error;
  EsusuWaitingRoomDetails? _details;

  // Countdown timer
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final details = await repository.getWaitingRoomDetails(widget.esusuId);

      // Debug logging
      debugPrint('=== Waiting Room Details Debug ===');
      debugPrint('Esusu: ${details.name}');
      debugPrint('Total Participants: ${details.participants.length}');
      for (final p in details.participants) {
        debugPrint('  - ${p.fullName}: ${p.inviteStatus} (isCreator: ${p.isCreator})');
      }
      debugPrint('Accepted: ${details.participants.where((p) => p.inviteStatus == 'ACCEPTED').length}');
      debugPrint('Pending: ${details.participants.where((p) => p.inviteStatus == 'INVITED').length}');
      debugPrint('==================================');

      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
        _startCountdown(details.startDate);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startCountdown(DateTime startDate) {
    _countdownTimer?.cancel();

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
      _countdownTimer?.cancel();
      setState(() {
        _timeRemaining = Duration.zero;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '₦${formatter.format(amount)}';
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

  Future<void> _remindParticipants() async {
    if (_isReminding) return;

    setState(() {
      _isReminding = true;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final response = await repository.remindPendingParticipants(widget.esusuId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReminding = false;
        });
      }
    }
  }

  List<WaitingRoomParticipant> _getFilteredParticipants() {
    if (_details == null) return [];

    switch (_selectedTabIndex) {
      case 0: // Accepted
        return _details!.participants
            .where((p) => p.inviteStatus == 'ACCEPTED')
            .toList();
      case 1: // Pending
        return _details!.participants
            .where((p) => p.inviteStatus == 'INVITED')
            .toList();
      case 2: // Declined
        return _details!.participants
            .where((p) => p.inviteStatus == 'DECLINED')
            .toList();
      default:
        return [];
    }
  }

  int _getTabCount(int tabIndex) {
    if (_details == null) return 0;

    switch (tabIndex) {
      case 0:
        return _details!.participants
            .where((p) => p.inviteStatus == 'ACCEPTED')
            .length;
      case 1:
        return _details!.participants
            .where((p) => p.inviteStatus == 'INVITED')
            .length;
      case 2:
        return _details!.participants
            .where((p) => p.inviteStatus == 'DECLINED')
            .length;
      default:
        return 0;
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

  Widget _buildContent() {
    final details = _details!;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 12),
              // Esusu icon
              _buildEsusuImage(details.iconUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.name,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      details.description ?? 'Description',
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
                  // TODO: Show menu (cancel esusu, edit, etc.)
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
                // Info Card
                _buildInfoCard(details),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Remind button (only show if there are pending participants)
        if (_getTabCount(1) > 0)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: DefaultButton(
              isButtonEnabled: !_isReminding,
              loading: _isReminding,
              onPressed: _remindParticipants,
              title: 'Remind participants',
              buttonColor: _esusuPrimaryColor,
              loadingIndicatorColor: _esusuPrimaryColor,
              height: 54,
            ),
          ),
      ],
    );
  }

  Widget _buildEsusuImage(String? iconUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
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
                  child: const Icon(
                    Icons.groups_outlined,
                    color: Color(0xFF9E9E9E),
                    size: 24,
                  ),
                ),
              )
            : Container(
                color: const Color(0xFFE0E0E0),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 24,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(EsusuWaitingRoomDetails details) {
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
                child: _buildInfoItem(
                  'Contribution Amount',
                  _formatCurrency(details.contributionAmount),
                ),
              ),
              Expanded(
                child: _buildInfoItem('Frequency', details.frequency),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Target Members',
                  details.targetMembers.toString(),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Start date',
                  _formatDate(details.startDate),
                ),
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
            color: const Color(0xFF606060),
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
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours.remainder(24);
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

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
              const Icon(
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
              _buildCountdownItem(days.toString(), 'Days'),
              const SizedBox(width: 12),
              _buildCountdownItem(hours.toString().padLeft(2, '0'), 'Hours'),
              const SizedBox(width: 12),
              _buildCountdownItem(minutes.toString().padLeft(2, '0'), 'Minutes'),
              const SizedBox(width: 12),
              _buildCountdownItem(seconds.toString().padLeft(2, '0'), 'Seconds'),
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
            color: const Color(0xFF6B1CB5),
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
    final count = _getTabCount(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _esusuLightColor : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _esusuPrimaryColor, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(isSelected ? 0xFF333333 : 0xFF8E8E8E),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? _esusuPrimaryColor : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF8E8E8E),
                ),
              ),
            ),
          ],
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
            'No participants',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantTile(participant);
      },
    );
  }

  Widget _buildParticipantTile(WaitingRoomParticipant participant) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Profile image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: participant.profileImage != null &&
                      participant.profileImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: participant.profileImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildAvatarPlaceholder(
                        participant.fullName,
                      ),
                      errorWidget: (context, url, error) =>
                          _buildAvatarPlaceholder(participant.fullName),
                    )
                  : _buildAvatarPlaceholder(participant.fullName),
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
                      participant.fullName,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (participant.isCreator) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _esusuPrimaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
          // Show slot for accepted (if FCFS), hourglass for pending
          if (_selectedTabIndex == 0 && participant.slotNumber != null)
            Text(
              'Slot ${participant.slotNumber}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            )
          else if (_selectedTabIndex == 1)
            const Icon(
              Icons.hourglass_empty,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: _esusuPrimaryColor.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _esusuPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header shimmer
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 18, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 100, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info card shimmer
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            // Countdown card shimmer
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            // Tabs shimmer
            Row(
              children: [
                Container(width: 80, height: 36, color: Colors.white),
                const SizedBox(width: 12),
                Container(width: 80, height: 36, color: Colors.white),
                const SizedBox(width: 12),
                Container(width: 80, height: 36, color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            // List shimmer
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 150, height: 14, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(width: 200, height: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load details',
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
              onPressed: _fetchDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: _esusuPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
