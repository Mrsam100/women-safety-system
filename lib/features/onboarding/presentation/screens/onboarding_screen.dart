import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/features/onboarding/presentation/widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.shield,
      title: 'Real-Time Safety',
      description:
          'SafeRide monitors your cab rides in real-time '
          'using GPS tracking and on-device AI to keep '
          'you safe every step of the way.',
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.primaryLight,
    ),
    _OnboardingData(
      icon: Icons.emergency,
      title: 'Instant Emergency Alerts',
      description:
          'Trigger a panic alert with a long press or '
          'phone shake. Your emergency contacts receive '
          'your live location and audio evidence '
          'instantly.',
      primaryColor: AppColors.danger,
      secondaryColor: Color(0xFFFF8A80),
    ),
    _OnboardingData(
      icon: Icons.route,
      title: 'Smart Route Monitoring',
      description:
          'SafeRide detects route deviations, unusual '
          'stops, and speed anomalies. Get automatic '
          'safety prompts and threat scoring throughout '
          'your ride.',
      primaryColor: AppColors.safe,
      secondaryColor: Color(0xFF81C784),
    ),
    _OnboardingData(
      icon: Icons.lock,
      title: 'Privacy First',
      description:
          'All audio processing happens on your device. '
          'No data leaves your phone unless you trigger '
          'an emergency. Your safety, your privacy.',
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF64B5F6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(onboardingCompleteProvider.notifier).state =
        true;
    context.go(RouteNames.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final data = _pages[index];
              return OnboardingPage(
                icon: data.icon,
                title: data.title,
                description: data.description,
                primaryColor: data.primaryColor,
                secondaryColor: data.secondaryColor,
              );
            },
          ),

          // Skip button (top-right)
          Positioned(
            top: MediaQuery.paddingOf(context).top +
                AppDimensions.paddingSM,
            right: AppDimensions.paddingMD,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom +
                AppDimensions.paddingLG,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLG,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicator
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _DotIndicator(
                        isActive: index == _currentPage,
                        color:
                            _pages[_currentPage]
                                .primaryColor,
                      ),
                    ),
                  ),

                  // Next / Get Started button
                  FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _pages[_currentPage].primaryColor,
                      foregroundColor:
                          AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isLastPage
                            ? AppDimensions.paddingLG
                            : AppDimensions.paddingMD,
                        vertical:
                            AppDimensions.paddingMD - 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppDimensions.radiusXL,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastPage
                              ? 'Get Started'
                              : 'Next',
                        ),
                        if (!isLastPage) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _DotIndicator({
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? color
            : color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusRound,
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
