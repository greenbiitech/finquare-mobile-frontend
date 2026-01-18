import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

// Colors matching old Greencard codebase
const Color _mainTextColor = Color(0xFF333333);

class DuesWelcomePage extends StatelessWidget {
  const DuesWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 20),
                    Text(
                      'Dues',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 50),
                SvgPicture.asset("assets/svgs/dues/Illustration.svg"),
                const SizedBox(height: 80),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dues',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF020014),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _duesHomeWidget(
                  icon: 'assets/svgs/dues/Frame 2609038.svg',
                  title: 'Group Contributions',
                  description: 'Track your group\'s contributions easily.',
                ),
                const SizedBox(height: 20),
                _duesHomeWidget(
                  icon: 'assets/svgs/dues/Frame 2609038 (1).svg',
                  title: 'Fast Contributions',
                  description: 'Contribute easily at the Group Fund.',
                ),
                const SizedBox(height: 20),
                _duesHomeWidget(
                  icon: 'assets/svgs/dues/Frame 2609038 (2).svg',
                  title: 'Simple and Secure',
                  description: 'Your contributions are safe and easy to manage.',
                ),
                const Spacer(),
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: () => context.push(AppRoutes.duesWarning),
                  title: 'Get Started',
                  buttonColor: Color(0xFF21A8FB),
                  height: 54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _duesHomeWidget({
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        SvgPicture.asset(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _mainTextColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF606060),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
