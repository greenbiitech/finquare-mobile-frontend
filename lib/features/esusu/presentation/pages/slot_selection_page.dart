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

class SlotSelectionPage extends ConsumerStatefulWidget {
  final String esusuId;
  final String esusuName;
  final bool isAdmin;

  const SlotSelectionPage({
    super.key,
    required this.esusuId,
    required this.esusuName,
    this.isAdmin = false,
  });

  @override
  ConsumerState<SlotSelectionPage> createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends ConsumerState<SlotSelectionPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  EsusuSlotDetails? _slotDetails;
  int? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSlotDetails();
    });
  }

  Future<void> _fetchSlotDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(esusuRepositoryProvider);
      final details = await repository.getSlotDetails(widget.esusuId);
      setState(() {
        _slotDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedSlot == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(esusuRepositoryProvider);
      await repository.selectSlot(widget.esusuId, slotNumber: _selectedSlot!);

      if (mounted) {
        // Trigger list refresh for when user returns to list
        ref.read(esusuListRefreshTriggerProvider.notifier).state++;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Slot $_selectedSlot selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to appropriate waiting room based on user role
        if (widget.isAdmin) {
          // Admin goes to Admin Waiting Room (esusu_detail_page)
          context.pushReplacement(
            '${AppRoutes.esusuDetail}/${widget.esusuId}?name=${Uri.encodeComponent(widget.esusuName)}',
          );
        } else {
          // Member goes to Member Waiting Room
          context.pushReplacement(
            '${AppRoutes.esusuWaitingRoom}/${widget.esusuId}?name=${Uri.encodeComponent(widget.esusuName)}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _selectedSlot = null; // Clear selection
        });

        // Check if it's a "slot taken" error
        final errorMessage = e.toString();
        final isSlotTaken = errorMessage.contains('already been taken') ||
            errorMessage.contains('Slot') && errorMessage.contains('taken');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSlotTaken
                  ? 'That slot was just taken! Refreshing available slots...'
                  : 'Failed to select slot: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );

        // If slot was taken, refresh to show updated availability
        if (isSlotTaken) {
          _fetchSlotDetails();
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 16),
                  Text(
                    'Esusu',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
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

            // Confirm Button
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedSlot != null && !_isSubmitting
                        ? _handleConfirm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _esusuPrimaryColor,
                      disabledBackgroundColor: const Color(0xFFF3F3F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
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
                            'Confirm',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedSlot != null
                                  ? Colors.white
                                  : const Color(0xFFBDBDBD),
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Esusu details card shimmer
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            // Pick your slot header shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  color: Colors.white,
                ),
                Container(
                  width: 50,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Slots grid shimmer
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
              'Failed to load slot details',
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
              onPressed: _fetchSlotDetails,
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

  Widget _buildContent() {
    final details = _slotDetails!;
    final availableSlots = details.availableSlots;
    final slotsLeft = availableSlots.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Esusu Details Card
          _buildEsusuDetailsCard(details),
          const SizedBox(height: 24),

          // Pick your slot header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pick your slot',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              Text(
                '$slotsLeft Left',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8E8E8E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Slots Grid
          _buildSlotsGrid(details),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEsusuDetailsCard(EsusuSlotDetails details) {
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
                    const SizedBox(height: 4),
                    Text(
                      details.description ?? 'Description',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8E8E8E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              const SizedBox(width: 16),
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
              const SizedBox(width: 16),
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

  Widget _buildEsusuImage(String? iconUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        height: 60,
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
                    size: 30,
                  ),
                ),
              )
            : Container(
                color: const Color(0xFFE0E0E0),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFF9E9E9E),
                  size: 30,
                ),
              ),
      ),
    );
  }

  Widget _buildSlotsGrid(EsusuSlotDetails details) {
    final totalSlots = details.targetMembers;
    final availableSlots = details.availableSlots;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        final slotNumber = index + 1;
        final isAvailable = availableSlots.contains(slotNumber);
        final isSelected = _selectedSlot == slotNumber;

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedSlot = slotNumber;
                  });
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _esusuPrimaryColor.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? _esusuPrimaryColor
                    : isAvailable
                        ? const Color(0xFF333333)
                        : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                slotNumber.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? _esusuPrimaryColor
                      : isAvailable
                          ? const Color(0xFF333333)
                          : const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
