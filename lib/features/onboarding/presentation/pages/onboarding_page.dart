import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:finsquare_mobile_app/config/routes/app_router.dart';
import 'package:finsquare_mobile_app/config/theme/app_theme.dart';
import 'package:finsquare_mobile_app/core/services/app_startup_service.dart';
import 'package:finsquare_mobile_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:finsquare_mobile_app/features/onboarding/presentation/widgets/dot_indicator.dart';
import 'package:finsquare_mobile_app/features/onboarding/presentation/widgets/onboarding_content.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final currentIndex = ref.read(onboardingNotifierProvider);
      if (currentIndex < onboardingPages.length - 1) {
        ref.read(onboardingNotifierProvider.notifier).nextPage();
        _pageController.animateToPage(
          currentIndex + 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onCreateAccount() {
    ref.read(appStartupServiceProvider).completeOnboarding();
    context.push(AppRoutes.signup);
  }

  void _onLogin() {
    ref.read(appStartupServiceProvider).completeOnboarding();
    context.push(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              // Dot indicators at top
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingPages.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: DotIndicator(isActive: index == pageIndex),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    ref
                        .read(onboardingNotifierProvider.notifier)
                        .setPage(index);
                  },
                  itemCount: onboardingPages.length,
                  itemBuilder: (context, index) {
                    final page = onboardingPages[index];
                    return OnboardingContent(
                      title: page.title,
                      description: page.description,
                      image: page.image,
                    );
                  },
                ),
              ),

              // Create account button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(43),
                      ),
                    ),
                    child: const Text(
                      'Create account for free',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Login button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonSecondary,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(43),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
