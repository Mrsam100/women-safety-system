import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/constants/app_strings.dart';
import 'package:saferide/core/constants/route_names.dart';
import 'package:saferide/core/extensions/context_extensions.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/core/widgets/app_button.dart';
import 'package:saferide/core/widgets/app_text_field.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/presentation/providers/profile_provider.dart';
import 'package:saferide/features/profile/presentation/widgets/avatar_picker.dart';
import 'package:saferide/features/profile/presentation/widgets/medical_info_form.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    final user =
        ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

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
    final existingProfile =
        ref.read(profileNotifierProvider).profile;

    final entity = ProfileEntity(
      uid: user.uid,
      displayName: _nameController.text.trim(),
      photoUrl: existingProfile?.photoUrl,
      bloodGroup: _selectedBloodGroup,
      medicalNotes:
          _medicalNotesController.text.trim().isNotEmpty
              ? _medicalNotesController.text.trim()
              : null,
      createdAt: existingProfile?.createdAt ?? now,
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

    // Populate fields when profile is loaded
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
          context.showSuccessSnackBar(
            'Profile saved successfully',
          );
          context.go(RouteNames.emergencyContacts);
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
      appBar: AppBar(
        title: Text(AppStrings.setupProfile),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  AppDimensions.paddingLG,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: AppDimensions.paddingMD,
                      ),
                      AvatarPicker(
                        imageUrl: profileState.photoUrl,
                        localImagePath: _localImagePath,
                        isUploading: isUploading,
                        onImagePicked: _onImagePicked,
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingXL,
                      ),
                      AppTextField(
                        controller: _nameController,
                        label: AppStrings.fullName,
                        hint: 'Enter your full name',
                        prefixIcon:
                            const Icon(Icons.person),
                        textInputAction:
                            TextInputAction.next,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your '
                                'name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least'
                                ' 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingMD,
                      ),
                      MedicalInfoForm(
                        selectedBloodGroup:
                            _selectedBloodGroup,
                        medicalNotesController:
                            _medicalNotesController,
                        onBloodGroupChanged: (value) {
                          setState(() {
                            _selectedBloodGroup = value;
                          });
                        },
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingXXL,
                      ),
                      AppButton(
                        text: AppStrings.saveProfile,
                        isLoading: isSaving,
                        onPressed:
                            isSaving || isUploading
                                ? null
                                : _onSaveProfile,
                      ),
                      const SizedBox(
                        height: AppDimensions.paddingMD,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
