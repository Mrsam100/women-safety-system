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
    extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = Validators.cleanPhoneNumber(
        _phoneController.text.trim(),
      );
      ref.read(authNotifierProvider.notifier).sendOtp(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppDimensions.paddingLG,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.paddingXXL),
                Text(
                  AppStrings.appName,
                  style: context.textTheme.displayMedium
                      ?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingSM),
                Text(
                  AppStrings.enterPhone,
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                PhoneInputField(
                  controller: _phoneController,
                  onSubmitted: _onSendOtp,
                ),
                const Spacer(),
                AppButton(
                  text: AppStrings.sendOtp,
                  isLoading:
                      authState.status ==
                      AuthStatus.sendingOtp,
                  onPressed: _onSendOtp,
                ),
                const SizedBox(height: AppDimensions.paddingMD),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
