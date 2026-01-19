import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

const Color _esusuPrimaryColor = Color(0xFF8B20E9);

class ConfigureEsusuPage extends StatefulWidget {
  const ConfigureEsusuPage({super.key});

  @override
  State<ConfigureEsusuPage> createState() => _ConfigureEsusuPageState();
}

class _ConfigureEsusuPageState extends State<ConfigureEsusuPage> {
  int _numberOfParticipants = 12;
  String _paymentFrequency = 'Monthly';
  bool _takeCommission = true;
  bool _isPayoutScheduleExpanded = true;

  final TextEditingController _contributionController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();

  DateTime? _collectionDate;
  DateTime? _participationDeadline;

  final List<int> _participantOptions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  final List<String> _frequencyOptions = ['Weekly', 'Monthly', 'Quarterly'];

  @override
  void dispose() {
    _contributionController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isCollectionDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isCollectionDate) {
          _collectionDate = picked;
        } else {
          _participationDeadline = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
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
                    'Configure',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number of participants
                    Text(
                      'Number of participants',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown<int>(
                      value: _numberOfParticipants,
                      items: _participantOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _numberOfParticipants = value);
                        }
                      },
                      itemLabel: (item) => item.toString(),
                    ),
                    const SizedBox(height: 20),

                    // Contribution amount per member
                    _buildOutlinedTextField(
                      controller: _contributionController,
                      label: 'Contribution amount per member',
                      hint: 'e.g. ₦5,000',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),

                    // Payment frequency
                    Text(
                      'Payment frequency',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _paymentFrequency,
                      items: _frequencyOptions,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentFrequency = value);
                        }
                      },
                      itemLabel: (item) => item,
                    ),
                    const SizedBox(height: 20),

                    // Collection Date
                    _buildDateField(
                      label: 'Collection Date',
                      value: _collectionDate,
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This date starts the first collection.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Participation Deadline
                    _buildDateField(
                      label: 'Participation Deadline',
                      value: _participationDeadline,
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This is the deadline date for participants to accept invite',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF606060),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Take Commission checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _takeCommission,
                            onChanged: (value) {
                              setState(() => _takeCommission = value ?? false);
                            },
                            activeColor: _esusuPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Take Commision',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF606060),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Commission per payout (visible when checkbox is checked)
                    if (_takeCommission)
                      _buildOutlinedTextField(
                        controller: _commissionController,
                        label: 'Commision per payout',
                        hint: 'e.g. ₦100',
                        keyboardType: TextInputType.number,
                      ),
                    if (_takeCommission) const SizedBox(height: 20),

                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DefaultButton(
                isButtonEnabled: true,
                onPressed: () {
                  context.push(AppRoutes.addParticipants);
                },
                title: 'Invite Members',
                buttonColor: _esusuPrimaryColor,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOutlinedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF606060),
        ),
        hintStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9E9E9E),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _esusuPrimaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? _formatDate(value) : label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: value != null ? Colors.black : Color(0xFF606060),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: Color(0xFF606060),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _esusuPrimaryColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          // Total Amount per cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount per cycle:',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                '₦100,000',
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

          // Commission
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Commission',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF606060),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFF606060),
                  ),
                ],
              ),
              Text(
                '₦100',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Platform fees
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform fees 1.5%',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606060),
                ),
              ),
              Text(
                '₦150',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payout',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                '₦99,750',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _esusuPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payout Schedule header
          GestureDetector(
            onTap: () {
              setState(() {
                _isPayoutScheduleExpanded = !_isPayoutScheduleExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payout Schedule (Monthly)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Icon(
                  _isPayoutScheduleExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),

          // Payout Schedule list
          if (_isPayoutScheduleExpanded) ...[
            const SizedBox(height: 12),
            _buildCycleRow('Cycle 1', 'Jan'),
            const SizedBox(height: 8),
            _buildCycleRow('Cycle 2', 'Feb'),
            const SizedBox(height: 8),
            _buildCycleRow('Cycle 3', 'Mar'),
          ],
        ],
      ),
    );
  }

  Widget _buildCycleRow(String cycle, String month) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          cycle,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF606060),
          ),
        ),
        Text(
          month,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
