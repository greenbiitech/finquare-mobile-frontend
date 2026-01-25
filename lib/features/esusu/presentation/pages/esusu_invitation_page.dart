import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/features/esusu/data/esusu_repository.dart';
import 'package:intl/intl.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class EsusuInvitationPage extends ConsumerStatefulWidget {
  final String esusuId;
  final String esusuName;

  const EsusuInvitationPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
  });

  @override
  ConsumerState<EsusuInvitationPage> createState() => _EsusuInvitationPageState();
}

class _EsusuInvitationPageState extends ConsumerState<EsusuInvitationPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  EsusuInvitationDetails? _invitationDetails;
  bool _isPayoutScheduleExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInvitationDetails();
    });
  }

  Future<void> _fetchInvitationDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final details = await repository.getInvitationDetails(widget.esusuId);

      if (mounted) {
        setState(() {
          _invitationDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load invitation details';
        });
      }
    }
  }

  Future<void> _handleAcceptInvite() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Accept Invitation',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to join this Esusu? You will be committed to making contributions once it starts.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Accept',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: _esusuPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final response = await repository.respondToInvitation(widget.esusuId, accept: true);

      if (mounted) {
        // Trigger list refresh for when user returns to list
        ref.read(esusuListRefreshTriggerProvider.notifier).state++;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if user needs to select a slot (FCFS payout order)
        if (response.needsSlotSelection) {
          // Navigate to slot selection, replacing current route
          context.pushReplacement(
            '${AppRoutes.esusuSlotSelection}/${response.esusuId}?name=${Uri.encodeComponent(response.esusuName ?? widget.esusuName)}',
          );
        } else {
          // Random payout order - go to waiting room
          context.pushReplacement(
            '${AppRoutes.esusuWaitingRoom}/${response.esusuId}?name=${Uri.encodeComponent(response.esusuName ?? widget.esusuName)}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineInvite() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Decline Invitation',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to decline this Esusu invitation?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Decline',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(esusuRepositoryProvider);
      await repository.respondToInvitation(widget.esusuId, accept: false);

      if (mounted) {
        // Trigger list refresh for when user returns to list
        ref.read(esusuListRefreshTriggerProvider.notifier).state++;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.grey,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                  const SizedBox(width: 20),
                  Text(
                    'Esusu',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),

            // Bottom buttons
            if (!_isLoading && _error == null && _invitationDetails != null)
              _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final details = _invitationDetails!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            'Esusu Invite',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'You have been invited by the admin to participate in this contribution',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF606060),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Esusu Details Card
          _buildEsusuDetailsCard(details),
          const SizedBox(height: 16),

          // Financial Summary Card
          _buildFinancialSummaryCard(details),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEsusuDetailsCard(EsusuInvitationDetails details) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBDAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and name
          Row(
            children: [
              // Esusu icon/image
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    if (details.description != null &&
                        details.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details.description!,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E8E8E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E8E8E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Purple divider
          const SizedBox(height: 16),
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: _esusuPrimaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),

          // Details grid (2x2)
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Contribution Amount',
                  _formatCurrency(details.contributionAmount),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Frequency',
                  details.frequency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Target Members',
                  details.targetMembers.toString(),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
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

  Widget _buildEsusuImage(String? iconUrl) {
    final hasImage = iconUrl != null && iconUrl.isNotEmpty;

    if (!hasImage) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: iconUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
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
            color: const Color(0xFF606060),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCard(EsusuInvitationDetails details) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFD2D2D2))
      ),
      child: Column(
        children: [
          // Total Amount per cycle
          _buildFinancialRow(
            'Total Amount per cycle:',
            _formatCurrency(details.totalAmountPerCycle),
            valueColor: _esusuPrimaryColor,
            isBold: true,
          ),
          const SizedBox(height: 12),

          // Commission
          _buildFinancialRow(
            'Commission',
            _formatCurrency(details.commission),
            hasInfoIcon: true,
          ),
          const SizedBox(height: 8),

          // Platform fees
          _buildFinancialRow(
            'Platform fees ${details.platformFeePercent}%',
            _formatCurrency(details.platformFee),
          ),
          const SizedBox(height: 12),

          // Payout
          _buildFinancialRow(
            'Payout',
            _formatCurrency(details.payout),
            valueColor: _esusuPrimaryColor,
            isBold: true,
            valueFontSize: 18,
          ),

          // Payout Schedule Section
          const SizedBox(height: 16),
          _buildPayoutScheduleSection(details),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    bool hasInfoIcon = false,
    double valueFontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF606060),
              ),
            ),
            if (hasInfoIcon) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF8E8E8E),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: valueFontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutScheduleSection(EsusuInvitationDetails details) {
    return Column(
      children: [
        // Header with toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _isPayoutScheduleExpanded = !_isPayoutScheduleExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payout Schedule (${details.frequency})',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
                AnimatedRotation(
                  turns: _isPayoutScheduleExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable cycle list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: details.payoutSchedule.asMap().entries.map((entry) {
              final index = entry.key;
              final schedule = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cycle ${index + 1}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF606060),
                      ),
                    ),
                    Text(
                      _formatScheduleDate(schedule.payoutDate),
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          crossFadeState: _isPayoutScheduleExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Accept button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleAcceptInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: _esusuPrimaryColor,
                disabledBackgroundColor: _esusuPrimaryColor.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Accept Invite',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Decline button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleDeclineInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F3F3),
                disabledBackgroundColor: const Color(0xFFF3F3F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: Text(
                'Decline Invite',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isSubmitting
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Title shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 28,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Details card shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial card shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: const Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF606060),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _fetchInvitationDetails,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: _esusuPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '\u20A6${formatter.format(amount)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    String suffix = 'th';
    if (day == 1 || day == 21 || day == 31) {
      suffix = 'st';
    } else if (day == 2 || day == 22) {
      suffix = 'nd';
    } else if (day == 3 || day == 23) {
      suffix = 'rd';
    }
    return '$day$suffix ${DateFormat('MMM yyyy').format(date)}';
  }

  String _formatScheduleDate(DateTime date) {
    return DateFormat('MMM dd yyyy').format(date);
  }
}
