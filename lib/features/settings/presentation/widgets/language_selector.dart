import 'package:flutter/material.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';

/// Language selection widget displayed as a ListTile with
/// a dropdown for choosing between supported languages.
class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(
        Icons.language,
        color: AppColors.primary,
      ),
      title: Text(
        'Language',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        AppSettings.supportedLanguages[currentLanguage] ??
            'English',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          isDense: true,
          borderRadius: BorderRadius.circular(8),
          items: AppSettings.supportedLanguages.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
              .toList(),
          onChanged: (lang) {
            if (lang != null) onChanged(lang);
          },
        ),
      ),
    );
  }
}
