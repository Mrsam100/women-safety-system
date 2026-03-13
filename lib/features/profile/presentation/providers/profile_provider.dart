import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:saferide/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:saferide/features/profile/domain/entities/profile_entity.dart';
import 'package:saferide/features/profile/domain/repositories/profile_repository.dart';
import 'package:saferide/features/profile/domain/usecases/get_profile.dart';
import 'package:saferide/features/profile/domain/usecases/update_profile.dart';
import 'package:saferide/features/profile/domain/usecases/upload_photo.dart';

// Datasource
final profileRemoteDatasourceProvider =
    Provider<ProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

// Repository
final profileRepositoryProvider =
    Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(profileRemoteDatasourceProvider),
  ),
);

// Use cases
final getProfileProvider = Provider<GetProfile>(
  (ref) => GetProfile(
    ref.watch(profileRepositoryProvider),
  ),
);

final updateProfileProvider = Provider<UpdateProfile>(
  (ref) => UpdateProfile(
    ref.watch(profileRepositoryProvider),
  ),
);

final uploadPhotoProvider = Provider<UploadPhoto>(
  (ref) => UploadPhoto(
    ref.watch(profileRepositoryProvider),
  ),
);

// Profile state
enum ProfileStatus {
  initial,
  loading,
  loaded,
  saving,
  uploading,
  error,
}

class ProfileState {
  final ProfileStatus status;
  final ProfileEntity? profile;
  final String? errorMessage;
  final String? photoUrl;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.photoUrl,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileEntity? profile,
    String? errorMessage,
    String? photoUrl,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  GetProfile get _getProfile =>
      ref.read(getProfileProvider);
  UpdateProfile get _updateProfile =>
      ref.read(updateProfileProvider);
  UploadPhoto get _uploadPhoto =>
      ref.read(uploadPhotoProvider);

  Future<void> loadProfile(String uid) async {
    state = state.copyWith(
      status: ProfileStatus.loading,
    );

    final result = await _getProfile(uid);
    result.fold(
      (failure) => state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      ),
      (profile) => state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        photoUrl: profile.photoUrl,
      ),
    );
  }

  Future<void> saveProfile(ProfileEntity entity) async {
    state = state.copyWith(status: ProfileStatus.saving);

    final result = await _updateProfile(entity);
    result.fold(
      (failure) => state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      ),
      (profile) => state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
      ),
    );
  }

  Future<void> uploadPhoto({
    required String uid,
    required String filePath,
  }) async {
    state = state.copyWith(
      status: ProfileStatus.uploading,
    );

    final result = await _uploadPhoto(
      uid: uid,
      filePath: filePath,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: ProfileStatus.loaded,
        errorMessage: failure.message,
      ),
      (url) => state = state.copyWith(
        status: ProfileStatus.loaded,
        photoUrl: url,
        profile:
            state.profile?.copyWith(photoUrl: url),
      ),
    );
  }

  void clearError() {
    state = state.copyWith(
      status: state.profile != null
          ? ProfileStatus.loaded
          : ProfileStatus.initial,
      errorMessage: null,
    );
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
