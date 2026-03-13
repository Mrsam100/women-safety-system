import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

/// Single onboarding page with an icon/illustration area,
/// title, description, and gradient background.
class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.08),
            secondaryColor.withOpacity(0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingXL,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Icon / Illustration area
              Container(
                width: size.width * 0.45,
                height: size.width * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.15),
                      secondaryColor.withOpacity(0.08),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: size.width * 0.2,
                  color: primaryColor,
                ),
              ),

              const Spacer(),

              // Title
              Text(
                title,
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: AppDimensions.paddingMD,
              ),

              // Description
              Text(
                description,
                style:
                    theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
