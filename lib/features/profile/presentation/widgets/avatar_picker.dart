import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';

class AvatarPicker extends StatelessWidget {
  final String? imageUrl;
  final String? localImagePath;
  final bool isUploading;
  final ValueChanged<String> onImagePicked;

  const AvatarPicker({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.isUploading = false,
    required this.onImagePicked,
  });

  Future<void> _showPickerOptions(
    BuildContext context,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLG),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (picked != null) {
      onImagePicked(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading
          ? null
          : () => _showPickerOptions(context),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: AppDimensions.iconXL,
            backgroundColor: AppColors.primary.withValues(
              alpha: 0.1,
            ),
            backgroundImage: _resolveImage(),
            child: _buildPlaceholder(),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          if (!isUploading)
            Container(
              padding: const EdgeInsets.all(
                AppDimensions.paddingXS,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: AppDimensions.iconSM,
                color: AppColors.textOnPrimary,
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    if (localImagePath != null) {
      return FileImage(File(localImagePath!));
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return null;
  }

  Widget? _buildPlaceholder() {
    if (localImagePath != null ||
        (imageUrl != null && imageUrl!.isNotEmpty)) {
      return null;
    }
    return const Icon(
      Icons.person,
      size: AppDimensions.iconXL,
      color: AppColors.primary,
    );
  }
}
