import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/extensions/context_extensions.dart';
import 'package:saferide/core/utils/validators.dart';
import 'package:saferide/core/widgets/app_button.dart';
import 'package:saferide/features/auth/presentation/providers/auth_provider.dart';
import 'package:saferide/features/auth/presentation/widgets/phone_input_field.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() =>
      _PhoneInputScreenState();
}

class _PhoneInputScreenState
    extends ConsumerState<PhoneInputScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = Validators.normalizePhoneNumber(
        _phoneController.text.trim(),
      );
      ref.read(authNotifierProvider.notifier).sendOtp(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isSending =
        authState.status == AuthStatus.sendingOtp;

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.otpSent) {
        context.go(
          RouteNames.otpVerification,
          extra: next.verificationId,
        );
      }
      if (next.status == AuthStatus.error) {
        context.showErrorSnackBar(
          next.errorMessage ?? AppStrings.authError,
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              Color(0xFF8B5CF6),
            ],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with branding
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingMD,
                      ),
                      Text(
                        AppStrings.appName,
                        style: context
                            .textTheme.headlineLarge
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingXS,
                      ),
                      Text(
                        AppStrings.appTagline,
                        style: context.textTheme.bodyLarge
                            ?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom card with phone input
              Expanded(
                flex: 5,
                child: SlideTransition(
                  position: _slideUp,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              AppDimensions.paddingLG,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: AppDimensions
                                    .paddingXL,
                              ),
                              Text(
                                'Welcome',
                                style: context.textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: AppColors
                                      .textPrimary,
                                ),
                              ),
                              const SizedBox(
                                height: AppDimensions
                                    .paddingXS,
                              ),
                              Text(
                                'Enter your phone number '
                                'to get started',
                                style: context
                                    .textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),
                              const SizedBox(
                                height: AppDimensions
                                    .paddingXL,
                              ),
                              PhoneInputField(
                                controller:
                                    _phoneController,
                                onSubmitted: _onSendOtp,
                                validator: Validators
                                    .validatePhone,
                              ),
                              const Spacer(),
                              AppButton(
                                text: AppStrings.sendOtp,
                                isLoading: isSending,
                                onPressed: _onSendOtp,
                              ),
                              const SizedBox(
                                height: AppDimensions
                                    .paddingSM,
                              ),
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    bottom: AppDimensions
                                        .paddingMD,
                                  ),
                                  child: Text(
                                    'We\'ll send you a '
                                    'verification code',
                                    style: context
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
