import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
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
    extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _btnController;
  late final Animation<double> _btnScale;

  static const _pages = [
    _PageData(
      icon: Icons.shield_rounded,
      title: 'Real-Time Safety\nMonitoring',
      description:
          'AI-powered protection that watches over '
          'your cab rides with GPS tracking and '
          'intelligent threat detection.',
      badge: 'ALWAYS PROTECTED',
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.primaryLight,
      features: [
        'Live GPS tracking',
        'On-device AI',
        'Threat scoring',
      ],
    ),
    _PageData(
      icon: Icons.notification_important_rounded,
      title: 'One-Touch\nEmergency Alerts',
      description:
          'Trigger instant alerts with a long press or '
          'phone shake. Your contacts get your live '
          'location and audio evidence immediately.',
      badge: 'INSTANT RESPONSE',
      primaryColor: AppColors.danger,
      secondaryColor: Color(0xFFFF8A80),
      features: [
        'Shake to alert',
        'Live location share',
        'Audio evidence',
      ],
    ),
    _PageData(
      icon: Icons.alt_route_rounded,
      title: 'Smart Route\nDeviation Alerts',
      description:
          'Get notified the moment your ride goes '
          'off-route. Automatic detection of unusual '
          'stops, speed changes, and path deviations.',
      badge: 'ROUTE INTELLIGENCE',
      primaryColor: AppColors.safe,
      secondaryColor: Color(0xFF81C784),
      features: [
        'Route deviation',
        'Speed monitoring',
        'Area safety scores',
      ],
    ),
    _PageData(
      icon: Icons.lock_rounded,
      title: 'Your Privacy\nIs Sacred',
      description:
          'All processing happens on your device. '
          'No data leaves your phone unless you '
          'trigger an emergency. Zero compromises.',
      badge: 'PRIVACY FIRST',
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF64B5F6),
      features: [
        'On-device only',
        'AES-256 encrypted',
        'Auto-delete 30 days',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _btnController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _btnController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _nextPage() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(onboardingCompleteProvider.notifier).set(true);
    context.go(RouteNames.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final data = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Subtle background gradient that changes per page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  data.primaryColor.withValues(alpha: 0.04),
                  AppColors.surface,
                  AppColors.surface,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Pages
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final p = _pages[index];
              return OnboardingPage(
                icon: p.icon,
                title: p.title,
                description: p.description,
                primaryColor: p.primaryColor,
                secondaryColor: p.secondaryColor,
                badge: p.badge,
                features: p.features,
              );
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: AnimatedOpacity(
              opacity: _isLastPage ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: TextButton(
                onPressed: _isLastPage
                    ? null
                    : _completeOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
          ),

          // Step indicator + page count (top-left)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            left: 24,
            child: Text(
              '${_currentPage + 1}/${_pages.length}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad + 32,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => _ProgressDot(
                        isActive: i == _currentPage,
                        isPast: i < _currentPage,
                        color: data.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Main CTA button
                  GestureDetector(
                    onTapDown: (_) => _btnController.forward(),
                    onTapUp: (_) {
                      _btnController.reverse();
                      _nextPage();
                    },
                    onTapCancel: () =>
                        _btnController.reverse(),
                    child: ScaleTransition(
                      scale: _btnScale,
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: data.primaryColor,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: data.primaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            child: Text(
                              _isLastPage
                                  ? 'Get Started'
                                  : 'Continue',
                              key: ValueKey(_isLastPage),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _ProgressDot extends StatelessWidget {
  final bool isActive;
  final bool isPast;
  final Color color;

  const _ProgressDot({
    required this.isActive,
    required this.isPast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? color
            : isPast
                ? color.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> features;

  const _PageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.primaryColor,
    required this.secondaryColor,
    required this.features,
  });
}
