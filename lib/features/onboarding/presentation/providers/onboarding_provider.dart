import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

class OnboardingData {
  final String image;
  final String title;
  final String description;

  const OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}

const List<OnboardingData> onboardingPages = [
  OnboardingData(
    image: 'assets/images/onboarding_1.png',
    title: 'Turning Communities to Economies',
    description:
        'Made for Cooperatives and Groups. Or you could just join the one Big FinSquare Community.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_2.png',
    title: 'Community Dues and Savings',
    description:
        'Manage monthly/yearly dues. Organize Esusu, Ajo, Contributions and other Group financial activities',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_3.png',
    title: 'Value Added Services',
    description:
        'Access Discounts, Credit Facilities, Bills and Utilities payments from your account.',
  ),
];

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  int build() => 0;

  void setPage(int index) {
    state = index;
  }

  void nextPage() {
    if (state < onboardingPages.length - 1) {
      state++;
    }
  }
}
