import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/extensions/context_extensions.dart';
import 'package:saferide/core/widgets/app_button.dart';
import 'package:saferide/features/auth/presentation/providers/auth_provider.dart';
import 'package:saferide/features/auth/presentation/widgets/otp_input_field.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  String _otp = '';
  int _resendTimer = AppDimensions.otpResendSeconds;
  Timer? _timer;
  final _otpFieldKey = GlobalKey<OtpInputFieldState>();
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = AppDimensions.otpResendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            timer.cancel();
          }
        });
      },
    );
  }

  void _onOtpCompleted(String otp) {
    _otp = otp;
    _verifyOtp();
  }

  void _verifyOtp() {
    if (_otp.length == AppDimensions.otpLength) {
      ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(_otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isVerifying =
        authState.status == AuthStatus.verifying;
    final phone = authState.phoneNumber ?? '';

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.error) {
        _otpFieldKey.currentState?.clear();
        _otp = '';
        context.showErrorSnackBar(
          next.errorMessage ?? AppStrings.authError,
        );
        ref.read(authNotifierProvider.notifier).clearError();
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
              // Top bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSM,
                  vertical: AppDimensions.paddingXS,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Header section
              Expanded(
                flex: 3,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingMD,
                      ),
                      Text(
                        'Verification',
                        style: context
                            .textTheme.headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom card
              Expanded(
                flex: 6,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal:
                              AppDimensions.paddingLG,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height:
                                  AppDimensions.paddingXL,
                            ),
                            Text(
                              AppStrings.enterOtp,
                              style: context
                                  .textTheme.headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingSM,
                            ),
                            Text(
                              phone.isNotEmpty
                                  ? 'Code sent to $phone'
                                  : AppStrings.otpSent,
                              style: context
                                  .textTheme.bodyMedium
                                  ?.copyWith(
                                color:
                                    AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingXL,
                            ),
                            OtpInputField(
                              key: _otpFieldKey,
                              onCompleted: _onOtpCompleted,
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingLG,
                            ),
                            _resendTimer > 0
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      Text(
                                        'Resend code in ',
                                        style: context
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color: AppColors
                                              .textSecondary,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: AppColors
                                              .primary
                                              .withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            AppDimensions
                                                .radiusSM,
                                          ),
                                        ),
                                        child: Text(
                                          '${_resendTimer}s',
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                            color: AppColors
                                                .primary,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton.icon(
                                    onPressed: () {
                                      _startResendTimer();
                                      ref
                                          .read(
                                            authNotifierProvider
                                                .notifier,
                                          )
                                          .resendOtp();
                                    },
                                    icon: const Icon(
                                      Icons
                                          .refresh_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      AppStrings.resendOtp,
                                    ),
                                  ),
                            const Spacer(),
                            AppButton(
                              text: AppStrings.verifyOtp,
                              isLoading: isVerifying,
                              onPressed: _verifyOtp,
                            ),
                            const SizedBox(
                              height:
                                  AppDimensions.paddingLG,
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