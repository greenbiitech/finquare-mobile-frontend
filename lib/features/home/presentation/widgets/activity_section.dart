import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';

// Colors matching old codebase
const Color _mainTextColor = Color(0xFF333333);
const Color _greyTextColor = Color(0xFF606060);

class ActivitySection extends StatelessWidget {
  const ActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildNoActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivity() {
    return Column(
      children: [
        SvgPicture.asset('assets/svgs/no_activity.svg'),
        const SizedBox(height: 5),
        Text(
          'No Activities yet',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _mainTextColor,
          ),
        ),
        Text(
          'Your transactions will show here '
          'once\n you\'ve made your first purchase',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _greyTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
