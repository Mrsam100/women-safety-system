import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/features/emergency_contacts/domain/entities/emergency_contact.dart';

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusMD,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppDimensions.paddingMD),
            Expanded(child: _buildInfo(context)),
            _buildDeleteButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryLight.withOpacity(0.2),
      child: Text(
        contact.name.isNotEmpty
            ? contact.name[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contact.hasApp) ...[
              const SizedBox(width: AppDimensions.paddingXS),
              const Icon(
                Icons.verified,
                size: AppDimensions.iconSM,
                color: AppColors.safe,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          contact.phoneNumber,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          contact.relationship,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return IconButton(
      onPressed: () => _confirmDelete(context),
      icon: const Icon(
        Icons.delete_outline,
        color: AppColors.danger,
      ),
      tooltip: AppStrings.removeContact,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
          'Are you sure you want to remove '
          '${contact.name} from your emergency contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text(AppStrings.removeContact),
          ),
        ],
      ),
    );
  }
}
