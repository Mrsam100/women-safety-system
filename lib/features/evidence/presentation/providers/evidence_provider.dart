import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/providers/firebase_providers.dart';
import 'package:saferide/features/evidence/data/datasources/evidence_local_datasource.dart';
import 'package:saferide/features/evidence/data/datasources/evidence_remote_datasource.dart';
import 'package:saferide/features/evidence/data/repositories/evidence_repository_impl.dart';
import 'package:saferide/features/evidence/domain/entities/audio_evidence.dart';
import 'package:saferide/features/evidence/domain/repositories/evidence_repository.dart';
import 'package:saferide/features/evidence/domain/usecases/auto_delete_old_data.dart';
import 'package:saferide/features/evidence/domain/usecases/get_location_trail.dart';
import 'package:saferide/features/evidence/domain/usecases/save_audio_evidence.dart';

// Datasources
final evidenceLocalDatasourceProvider =
    Provider<EvidenceLocalDatasource>(
  (ref) => EvidenceLocalDatasource(),
);

final evidenceRemoteDatasourceProvider =
    Provider<EvidenceRemoteDatasource>((ref) {
  return EvidenceRemoteDatasource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

// Repository
final evidenceRepositoryProvider =
    Provider<EvidenceRepository>((ref) {
  return EvidenceRepositoryImpl(
    remoteDatasource:
        ref.watch(evidenceRemoteDatasourceProvider),
    localDatasource:
        ref.watch(evidenceLocalDatasourceProvider),
  );
});

// Use cases
final saveAudioEvidenceProvider =
    Provider<SaveAudioEvidence>((ref) {
  return SaveAudioEvidence(
    ref.watch(evidenceRepositoryProvider),
  );
});

final getLocationTrailProvider =
    Provider<GetLocationTrail>((ref) {
  return GetLocationTrail(
    ref.watch(evidenceRepositoryProvider),
  );
});

final autoDeleteOldDataProvider =
    Provider<AutoDeleteOldData>((ref) {
  return AutoDeleteOldData(
    ref.watch(evidenceRepositoryProvider),
  );
});

// Evidence state
enum EvidenceStatus {
  initial,
  loading,
  loaded,
  saving,
  deleting,
  downloading,
  error,
}

class EvidenceState {
  final EvidenceStatus status;
  final List<AudioEvidence> evidenceList;
  final String? errorMessage;
  final String? downloadedFilePath;

  const EvidenceState({
    this.status = EvidenceStatus.initial,
    this.evidenceList = const [],
    this.errorMessage,
    this.downloadedFilePath,
  });

  EvidenceState copyWith({
    EvidenceStatus? status,
    List<AudioEvidence>? evidenceList,
    String? errorMessage,
    String? downloadedFilePath,
  }) {
    return EvidenceState(
      status: status ?? this.status,
      evidenceList:
          evidenceList ?? this.evidenceList,
      errorMessage: errorMessage,
      downloadedFilePath: downloadedFilePath,
    );
  }
}

class EvidenceNotifier extends Notifier<EvidenceState> {
  @override
  EvidenceState build() {
    return const EvidenceState();
  }

  EvidenceRepository get _repository =>
      ref.read(evidenceRepositoryProvider);

  SaveAudioEvidence get _saveAudioEvidence =>
      ref.read(saveAudioEvidenceProvider);

  AutoDeleteOldData get _autoDeleteOldData =>
      ref.read(autoDeleteOldDataProvider);

  /// Loads all audio evidence for a given ride.
  Future<void> loadEvidence(String rideId) async {
    state = state.copyWith(
      status: EvidenceStatus.loading,
    );

    final result =
        await _repository.getAudioEvidence(rideId);

    result.fold(
      (failure) => state = state.copyWith(
        status: EvidenceStatus.error,
        errorMessage: failure.message,
      ),
      (evidenceList) => state = state.copyWith(
        status: EvidenceStatus.loaded,
        evidenceList: evidenceList,
      ),
    );
  }

  /// Saves audio evidence with AES-256 encryption.
  Future<void> saveEvidence({
    required String rideId,
    String? alertId,
    required List<String> audioFilePaths,
    required int durationSeconds,
  }) async {
    state = state.copyWith(
      status: EvidenceStatus.saving,
    );

    final result = await _saveAudioEvidence(
      rideId: rideId,
      alertId: alertId,
      audioFilePaths: audioFilePaths,
      durationSeconds: durationSeconds,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: EvidenceStatus.error,
        errorMessage: failure.message,
      ),
      (evidence) {
        final updated = [
          evidence,
          ...state.evidenceList,
        ];
        state = state.copyWith(
          status: EvidenceStatus.loaded,
          evidenceList: updated,
        );
      },
    );
  }

  /// Deletes a specific evidence record.
  Future<void> deleteEvidence(String evidenceId) async {
    state = state.copyWith(
      status: EvidenceStatus.deleting,
    );

    final result =
        await _repository.deleteEvidence(evidenceId);

    result.fold(
      (failure) => state = state.copyWith(
        status: EvidenceStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        final updated = state.evidenceList
            .where((e) => e.id != evidenceId)
            .toList();
        state = state.copyWith(
          status: EvidenceStatus.loaded,
          evidenceList: updated,
        );
      },
    );
  }

  /// Marks evidence as permanently saved (won't be
  /// auto-deleted).
  Future<void> markAsSaved(String evidenceId) async {
    final result =
        await _repository.markAsSaved(evidenceId);

    result.fold(
      (failure) => state = state.copyWith(
        status: EvidenceStatus.error,
        errorMessage: failure.message,
      ),
      (savedEvidence) {
        final updated = state.evidenceList
            .map(
              (e) =>
                  e.id == evidenceId ? savedEvidence : e,
            )
            .toList();
        state = state.copyWith(
          status: EvidenceStatus.loaded,
          evidenceList: updated,
        );
      },
    );
  }

  /// Downloads and decrypts evidence to a local file.
  Future<void> downloadEvidence(
    String evidenceId,
  ) async {
    state = state.copyWith(
      status: EvidenceStatus.downloading,
    );

    final result =
        await _repository.downloadEvidence(evidenceId);

    result.fold(
      (failure) => state = state.copyWith(
        status: EvidenceStatus.error,
        errorMessage: failure.message,
      ),
      (filePath) => state = state.copyWith(
        status: EvidenceStatus.loaded,
        downloadedFilePath: filePath,
      ),
    );
  }

  /// Triggers auto-deletion of expired evidence.
  Future<void> cleanupExpiredEvidence() async {
    await _autoDeleteOldData();
  }

  void clearError() {
    state = state.copyWith(
      status: EvidenceStatus.loaded,
    );
  }
}

final evidenceNotifierProvider =
    NotifierProvider<EvidenceNotifier, EvidenceState>(
  EvidenceNotifier.new,
);
