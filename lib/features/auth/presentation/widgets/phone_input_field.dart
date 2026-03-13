import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/widgets/app_text_field.dart';

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
    return AppTextField(
      controller: controller,
      label: AppStrings.enterPhone,
      hint: AppStrings.phoneHint,
      errorText: errorText,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.phone),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[\d\s\+\-()]'),
        ),
        LengthLimitingTextInputFormatter(15),
      ],
      validator: validator,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}
