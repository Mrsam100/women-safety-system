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
    extends ConsumerState<OtpVerificationScreen> {
  String _otp = '';
  int _resendTimer = AppDimensions.otpResendSeconds;
  Timer? _timer;
  final _otpFieldKey = GlobalKey<OtpInputFieldState>();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.error) {
        _otpFieldKey.currentState?.clear();
        _otp = '';
        context.showErrorSnackBar(
          next.errorMessage ?? AppStrings.authError,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingLG,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.enterOtp,
                style: context.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                AppStrings.otpSent,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              OtpInputField(
                key: _otpFieldKey,
                onCompleted: _onOtpCompleted,
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend in $_resendTimer s',
                        style: context.textTheme.bodyMedium
                            ?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          _startResendTimer();
                          ref
                              .read(authNotifierProvider
                                  .notifier)
                              .resendOtp();
                        },
                        child: const Text(
                          AppStrings.resendOtp,
                        ),
                      ),
              ),
              const Spacer(),
              AppButton(
                text: AppStrings.verifyOtp,
                isLoading:
                    authState.status == AuthStatus.verifying,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: AppDimensions.paddingMD),
            ],
          ),
        ),
      ),
    );
  }
}
