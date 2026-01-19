import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/widgets/back_button.dart';
import 'package:finsquare_mobile_app/core/widgets/default_button.dart';

// Esusu primary colors
const Color _esusuPrimaryColor = Color(0xFF8B20E9);
const Color _esusuLightColor = Color(0xFFEBDAFB);
const Color _mainTextColor = Color(0xFF333333);

class EsusuWelcomePage extends StatelessWidget {
  const EsusuWelcomePage({super.key});

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
                      'Esusu (Rotating Savings)',
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
                SvgPicture.asset("assets/svgs/esusu/start_esusu.svg"),
                const SizedBox(height: 80),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create & manage your Esusu better',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF020014),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _esusuHomeWidget(
                  icon: 'assets/svgs/esusu/Frame 2609038.svg',
                  title: 'Transparent and Fair',
                  description: 'See all participants, monitor turns, debit and credit',
                ),
                const SizedBox(height: 20),
                _esusuHomeWidget(
                  icon: 'assets/svgs/esusu/Frame 2609038 (1).svg',
                  title: 'Instant Payments',
                  description: 'Instant payment on the agreed date for all participants.',
                ),
                const SizedBox(height: 20),
                _esusuHomeWidget(
                  icon: 'assets/svgs/esusu/Frame 2609038 (2).svg',
                  title: 'Secure and Convenient',
                  description: 'Your funds are safe, and payments are hassle-free',
                ),
                const Spacer(),
                DefaultButton(
                  isButtonEnabled: true,
                  onPressed: () {
                    context.push(AppRoutes.configureEsusu);
                  },
                  title: 'Create Esusu',
                  buttonColor: _esusuPrimaryColor,
                  height: 54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _esusuHomeWidget({
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
