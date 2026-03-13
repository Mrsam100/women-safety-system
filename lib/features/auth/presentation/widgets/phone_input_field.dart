import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final void Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final String? Function(String?)? validator;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[\d\s\+\-()]'),
        ),
        LengthLimitingTextInputFormatter(15),
      ],
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: AppStrings.phoneHint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(
            alpha: 0.5,
          ),
          fontWeight: FontWeight.normal,
          letterSpacing: 1.0,
        ),
        errorText: errorText,
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                color: AppColors.divider,
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingMD,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          borderSide: const BorderSide(
            color: AppColors.divider,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusLG,
          ),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 2,
          ),
        ),
      ),
    );
  }
}