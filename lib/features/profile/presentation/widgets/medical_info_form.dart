import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/widgets/app_text_field.dart';

class MedicalInfoForm extends StatelessWidget {
  final String? selectedBloodGroup;
  final TextEditingController medicalNotesController;
  final ValueChanged<String?> onBloodGroupChanged;

  const MedicalInfoForm({
    super.key,
    this.selectedBloodGroup,
    required this.medicalNotesController,
    required this.onBloodGroupChanged,
  });

  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedBloodGroup,
          decoration: const InputDecoration(
            labelText: AppStrings.bloodGroup,
            prefixIcon: Icon(Icons.bloodtype),
          ),
          items: _bloodGroups
              .map(
                (group) => DropdownMenuItem(
                  value: group,
                  child: Text(group),
                ),
              )
              .toList(),
          onChanged: onBloodGroupChanged,
        ),
        const SizedBox(height: AppDimensions.paddingMD),
        AppTextField(
          controller: medicalNotesController,
          label: AppStrings.medicalNotes,
          hint: 'e.g. Allergies, medications, conditions',
          prefixIcon: const Icon(Icons.medical_services),
          maxLines: 3,
          textInputAction: TextInputAction.done,
          maxLength: 500,
        ),
      ],
    );
  }
}
