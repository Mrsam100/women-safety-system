import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';

/// Triggers a fake incoming call with a configurable delay.
///
/// The use case returns a [Timer] that the caller can
/// cancel if the user changes their mind before the delay
/// elapses.
class TriggerFakeCall {
  static const _tag = 'TriggerFakeCall';

  /// Default delay before the fake call appears.
  static const defaultDelay = Duration(seconds: 15);

  const TriggerFakeCall();

  /// Schedule a fake call after [delay].
  ///
  /// [onTrigger] is invoked when the delay elapses; the
  /// presentation layer should navigate to the fake-call
  /// screen at that point.
  Either<Failure, Timer> call({
    Duration delay = const Duration(seconds: 15),
    required void Function() onTrigger,
  }) {
    try {
      AppLogger.info(
        'Fake call scheduled in ${delay.inSeconds}s',
        tag: _tag,
      );

      final timer = Timer(delay, () {
        AppLogger.info(
          'Fake call triggered',
          tag: _tag,
        );
        onTrigger();
      });

      return Right(timer);
    } catch (e) {
      AppLogger.error(
        'Failed to schedule fake call',
        tag: _tag,
        error: e,
      );
      return Left(
        ServerFailure(
          message: 'Could not schedule fake call: $e',
          code: 'FAKE_CALL_FAILED',
        ),
      );
    }
  }
}
