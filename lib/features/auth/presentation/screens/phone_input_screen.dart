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
  bool _showPhoneInput = false;

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

  void _onGoogleSignIn() {
    ref
        .read(authNotifierProvider.notifier)
        .signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isSending =
        authState.status == AuthStatus.sendingOtp;
    final isGoogleLoading =
        authState.status == AuthStatus.signingInWithGoogle;
    final isLoading = isSending || isGoogleLoading;

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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              Color(0xFF8B5CF6),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top branding section
              Expanded(
                flex: _showPhoneInput ? 3 : 4,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 46,
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
                          color: Colors.white
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom card with auth options
              Expanded(
                flex: _showPhoneInput ? 6 : 5,
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
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              AppDimensions.paddingLG,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height:
                                  AppDimensions.paddingXL,
                            ),
                            Text(
                              'Get Started',
                              style: context.textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingXS,
                            ),
                            Text(
                              'Sign in to keep yourself '
                              'safe on every ride',
                              style: context
                                  .textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingXL,
                            ),

                            // Google Sign-In Button
                            _GoogleSignInButton(
                              isLoading: isGoogleLoading,
                              onPressed: isLoading
                                  ? null
                                  : _onGoogleSignIn,
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingMD,
                            ),

                            // Divider with "or"
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color:
                                        AppColors.divider,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                        AppDimensions
                                            .paddingMD,
                                  ),
                                  child: Text(
                                    'or',
                                    style: context
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      color: AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color:
                                        AppColors.divider,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingMD,
                            ),

                            // Phone sign-in toggle
                            if (!_showPhoneInput)
                              AppButton(
                                text:
                                    'Continue with Phone',
                                isOutlined: true,
                                icon:
                                    Icons.phone_outlined,
                                onPressed: isLoading
                                    ? null
                                    : () => setState(
                                        () =>
                                            _showPhoneInput =
                                                true,
                                      ),
                              ),

                            // Phone input section
                            if (_showPhoneInput) ...[
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    PhoneInputField(
                                      controller:
                                          _phoneController,
                                      onSubmitted:
                                          _onSendOtp,
                                      validator:
                                          Validators
                                              .validatePhone,
                                    ),
                                    const SizedBox(
                                      height:
                                          AppDimensions
                                              .paddingMD,
                                    ),
                                    AppButton(
                                      text: AppStrings
                                          .sendOtp,
                                      isLoading:
                                          isSending,
                                      onPressed:
                                          isLoading
                                              ? null
                                              : _onSendOtp,
                                    ),
                                    const SizedBox(
                                      height:
                                          AppDimensions
                                              .paddingSM,
                                    ),
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            setState(
                                          () =>
                                              _showPhoneInput =
                                                  false,
                                        ),
                                        child: Text(
                                          'Back to '
                                          'sign-in '
                                          'options',
                                          style: context
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                            color:
                                                AppColors
                                                    .primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(
                              height:
                                  AppDimensions.paddingXL,
                            ),

                            // Terms text
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: AppDimensions
                                      .paddingMD,
                                ),
                                child: Text(
                                  'By continuing, you '
                                  'agree to our Terms of '
                                  'Service and '
                                  'Privacy Policy',
                                  textAlign:
                                      TextAlign.center,
                                  style: context.textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: AppColors
                                        .textSecondary,
                                    fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.divider,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusLG,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: AppDimensions.paddingSM,
                  ),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
