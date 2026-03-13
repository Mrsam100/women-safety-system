import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/features/auth/presentation/providers/auth_provider.dart';
import 'package:saferide/features/settings/domain/entities/app_settings.dart';
import 'package:saferide/features/settings/presentation/providers/settings_provider.dart';
import 'package:saferide/features/settings/presentation/widgets/language_selector.dart';
import 'package:saferide/features/settings/presentation/widgets/sensitivity_slider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends ConsumerState<SettingsScreen> {
  late TextEditingController _callerNameController;

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsNotifierProvider).settings;
    _callerNameController = TextEditingController(
      text: settings.fakeCallCallerName,
    );
  }

  @override
  void dispose() {
    _callerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState =
        ref.watch(settingsNotifierProvider);
    final settings = settingsState.settings;
    final notifier =
        ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMD,
              ),
              children: [
                // --- Safety Section ---
                _SectionHeader(title: 'Safety'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      AppDimensions.paddingMD,
                    ),
                    child: SensitivitySlider(
                      value: settings.alertSensitivity,
                      onChanged: (sensitivity) {
                        notifier.updateAlertSensitivity(
                          sensitivity,
                        );
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.vibration,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Shake Detection',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      'Shake phone to trigger emergency',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: settings.shakeDetectionEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (_) {
                      notifier.toggleShakeDetection();
                    },
                  ),
                ),

                const SizedBox(
                  height: AppDimensions.paddingLG,
                ),

                // --- Fake Call Section ---
                _SectionHeader(title: 'Fake Call'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      AppDimensions.paddingMD,
                    ),
                    child: TextField(
                      controller: _callerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Caller Name',
                        hintText: 'e.g. Mom, Boss',
                        prefixIcon: Icon(Icons.person),
                      ),
                      onSubmitted: (value) {
                        notifier
                            .updateFakeCallCallerName(value);
                      },
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                        notifier.updateFakeCallCallerName(
                          _callerNameController.text,
                        );
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.timer,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Call Delay',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      'Time before fake call rings',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing:
                        DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: settings.fakeCallDelay,
                        isDense: true,
                        borderRadius:
                            BorderRadius.circular(8),
                        items: AppSettings
                            .fakeCallDelayOptions
                            .map(
                              (d) =>
                                  DropdownMenuItem<int>(
                                value: d,
                                child: Text('${d}s'),
                              ),
                            )
                            .toList(),
                        onChanged: (delay) {
                          if (delay != null) {
                            notifier
                                .updateFakeCallDelay(delay);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: AppDimensions.paddingLG,
                ),

                // --- Appearance Section ---
                _SectionHeader(title: 'Appearance'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.dark_mode,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: theme.textTheme.titleSmall,
                    ),
                    value: settings.darkMode,
                    activeColor: AppColors.primary,
                    onChanged: (_) {
                      notifier.toggleDarkMode();
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                  ),
                  child: LanguageSelector(
                    currentLanguage: settings.language,
                    onChanged: (lang) {
                      notifier.updateLanguage(lang);
                    },
                  ),
                ),

                const SizedBox(
                  height: AppDimensions.paddingLG,
                ),

                // --- Data Section ---
                _SectionHeader(title: 'Data'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(
                      Icons.auto_delete,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Auto-Delete Rides',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      'Delete ride data after 30 days',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: settings.autoDeleteEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (_) {
                      notifier.toggleAutoDelete();
                    },
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.download,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Export My Data',
                      style: theme.textTheme.titleSmall,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () => _handleExportData(notifier),
                  ),
                ),
                const SizedBox(
                  height: AppDimensions.paddingSM,
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      'Delete All Data',
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.danger,
                    ),
                    onTap: () =>
                        _handleDeleteAllData(notifier),
                  ),
                ),

                const SizedBox(
                  height: AppDimensions.paddingLG,
                ),

                // --- Account Section ---
                _SectionHeader(title: 'Account'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMD,
                    vertical: AppDimensions.paddingSM,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      'Sign Out',
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    onTap: _handleSignOut,
                  ),
                ),
                const SizedBox(
                  height: AppDimensions.paddingXL,
                ),
              ],
            ),
    );
  }

  Future<void> _handleExportData(
    SettingsNotifier notifier,
  ) async {
    final data = await notifier.exportData();
    if (!mounted) return;
    if (data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data exported successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export data'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleDeleteAllData(
    SettingsNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your '
          'local data including settings, cached '
          'locations, and offline queue. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await notifier.deleteAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'All data deleted'
                : 'Failed to delete data',
          ),
          backgroundColor:
              success ? AppColors.safe : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(authNotifierProvider.notifier)
          .signOut();
      if (!mounted) return;
      context.go(RouteNames.auth);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingSM,
      ),
      child: Text(
        title.toUpperCase(),
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
