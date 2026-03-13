import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/extensions/context_extensions.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/providers/shared_providers.dart';
import 'package:saferide/core/widgets/app_text_field.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/presentation/providers/profile_provider.dart';
import 'package:saferide/features/profile/presentation/widgets/avatar_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  String? _selectedBloodGroup;
  String? _localImagePath;

  static const _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    if (user.displayName != null &&
        user.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(profileNotifierProvider.notifier)
          .loadProfile(user.uid);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  void _populateFields(ProfileEntity profile) {
    if (_nameController.text.isEmpty) {
      _nameController.text = profile.displayName;
    }
    if (_medicalNotesController.text.isEmpty &&
        profile.medicalNotes != null) {
      _medicalNotesController.text =
          profile.medicalNotes!;
    }
    if (_selectedBloodGroup == null) {
      _selectedBloodGroup = profile.bloodGroup;
    }
  }

  Future<void> _onSaveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final existing =
        ref.read(profileNotifierProvider).profile;

    final entity = ProfileEntity(
      uid: user.uid,
      displayName: _nameController.text.trim(),
      photoUrl: existing?.photoUrl,
      bloodGroup: _selectedBloodGroup,
      medicalNotes:
          _medicalNotesController.text.trim().isNotEmpty
              ? _medicalNotesController.text.trim()
              : null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await ref
        .read(profileNotifierProvider.notifier)
        .saveProfile(entity);
  }

  void _onImagePicked(String path) {
    setState(() => _localImagePath = path);

    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    ref
        .read(profileNotifierProvider.notifier)
        .uploadPhoto(uid: user.uid, filePath: path);
  }

  @override
  Widget build(BuildContext context) {
    final profileState =
        ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);

    if (profileState.status == ProfileStatus.loaded &&
        profileState.profile != null) {
      _populateFields(profileState.profile!);
    }

    ref.listen<ProfileState>(
      profileNotifierProvider,
      (prev, next) {
        if (next.status == ProfileStatus.error &&
            next.errorMessage != null) {
          context.showErrorSnackBar(next.errorMessage!);
          ref
              .read(profileNotifierProvider.notifier)
              .clearError();
        }
        if (next.status == ProfileStatus.loaded &&
            prev?.status == ProfileStatus.saving) {
          ref
              .read(profileCompleteProvider.notifier)
              .set(true);
          context.go(RouteNames.manageContacts);
        }
      },
    );

    final isSaving =
        profileState.status == ProfileStatus.saving;
    final isLoading =
        profileState.status == ProfileStatus.loading;
    final isUploading =
        profileState.status == ProfileStatus.uploading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(theme),
                      const SizedBox(height: 32),

                      // Avatar
                      Center(
                        child: AvatarPicker(
                          imageUrl:
                              profileState.photoUrl,
                          localImagePath:
                              _localImagePath,
                          isUploading: isUploading,
                          onImagePicked: _onImagePicked,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to add photo',
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Name field
                      const _SectionLabel(
                        label: 'Your Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: _nameController,
                        hint: 'Enter your full name',
                        textInputAction:
                            TextInputAction.next,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your '
                                'name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at '
                                'least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Medical info
                      const _SectionLabel(
                        label: 'Medical Info',
                        icon:
                            Icons.medical_services_outlined,
                        subtitle: 'Optional but helpful '
                            'in emergencies',
                      ),
                      const SizedBox(height: 12),
                      _buildBloodGroupSelector(theme),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller:
                            _medicalNotesController,
                        hint: 'Allergies, medications, '
                            'conditions...',
                        maxLines: 3,
                        textInputAction:
                            TextInputAction.done,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: isSaving ||
                                  isUploading
                              ? null
                              : _onSaveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      16),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Step 2 of 3',
                          style: theme
                              .textTheme.bodySmall
                              ?.copyWith(
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar (step 2 of 3)
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Tell us about you',
          style:
              theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This helps us personalize your safety '
          'experience',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bloodGroups.map((group) {
        final isSelected =
            _selectedBloodGroup == group;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBloodGroup =
                  isSelected ? null : group;
            });
          },
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary
                      .withValues(alpha: 0.05),
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary
                        .withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              group,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? subtitle;

  const _SectionLabel({
    required this.label,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
