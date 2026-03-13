import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/features/evidence/domain/repositories/evidence_repository.dart';

class AutoDeleteOldData {
  final EvidenceRepository _repository;

  const AutoDeleteOldData(this._repository);

  /// Checks for evidence older than the retention period
  /// (30 days) that has not been explicitly saved by the
  /// user, and marks it for deletion.
  ///
  /// Returns the count of deleted evidence records.
  Future<Either<Failure, int>> call() async {
    return await _repository.deleteExpiredEvidence();
  }
}
