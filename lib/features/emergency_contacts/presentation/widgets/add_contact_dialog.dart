import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/widgets/app_button.dart';
import 'package:saferide/core/widgets/app_text_field.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRelationship = _relationships.first;

  static const _relationships = [
    'Parent',
    'Spouse',
    'Sibling',
    'Friend',
    'Relative',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusLG,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingXL,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.addContact,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              AppTextField(
                controller: _nameController,
                label: AppStrings.contactName,
                hint: 'Enter contact name',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: _validateName,
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              AppTextField(
                controller: _phoneController,
                label: AppStrings.contactPhone,
                hint: AppStrings.phoneHint,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.phone_outlined),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+\- ]'),
                  ),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: _validatePhone,
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              _buildRelationshipDropdown(),
              const SizedBox(height: AppDimensions.paddingSM),
              _buildPickFromPhoneButton(),
              const SizedBox(height: AppDimensions.paddingLG),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      isOutlined: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                  Expanded(
                    child: AppButton(
                      text: AppStrings.addContact,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRelationship,
      decoration: const InputDecoration(
        labelText: AppStrings.relationship,
        prefixIcon: Icon(Icons.group_outlined),
      ),
      items: _relationships
          .map(
            (r) => DropdownMenuItem(value: r, child: Text(r)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRelationship = value);
        }
      },
    );
  }

  Widget _buildPickFromPhoneButton() {
    return TextButton.icon(
      onPressed: _pickFromPhoneContacts,
      icon: const Icon(
        Icons.contacts_outlined,
        size: AppDimensions.iconMD,
      ),
      label: const Text('Pick from phone contacts'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _pickFromPhoneContacts() async {
    // TODO: Integrate with contacts_service or
    // flutter_contacts package to pick from device contacts.
    // For now, show a message indicating the feature.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Phone contacts picker will be available soon.',
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final contact = EmergencyContact(
      id: '', // Will be assigned by Firestore
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      relationship: _selectedRelationship,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(contact);
  }
}
