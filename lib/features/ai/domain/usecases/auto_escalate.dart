import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';

/// Actions that the escalation engine can request from
/// the presentation layer.
enum EscalationAction {
  /// No action required — ride is in the safe range.
  none,

  /// Prompt the user with "Are you safe?" and wait
  /// for a response within the timeout window.
  promptSafetyCheck,

  /// Automatically notify all emergency contacts with
  /// current location and ride details.
  notifyEmergencyContacts,

  /// Trigger full emergency protocol: GPS capture,
  /// audio evidence save, SMS dispatch, Firestore
  /// alert, push notifications, live tracking.
  fullEmergencyProtocol,
}

/// Result of an escalation evaluation, including the
/// action to take and any relevant metadata.
class EscalationResult {
  final EscalationAction action;
  final ThreatLevel level;
  final int score;
  final Duration? promptTimeout;
  final String? message;

  const EscalationResult({
    required this.action,
    required this.level,
    required this.score,
    this.promptTimeout,
    this.message,
  });

  @override
  String toString() =>
      'EscalationResult(${action.name}, '
      '${level.name}, score: $score)';
}

/// Automatic escalation engine that maps threat levels
/// to concrete safety actions.
///
/// Escalation tiers:
///   Green  (0–30)  : No action.
///   Yellow (31–60) : Prompt "Are you safe?" with
///                    60-second timeout. If no response,
///                    escalate to Orange.
///   Orange (61–80) : Auto-notify all emergency
///                    contacts with current location.
///   Red    (81–100): Full emergency protocol — GPS
///                    capture, audio evidence, SMS
///                    dispatch, Firestore alert, push
///                    notifications, live tracking.
class AutoEscalate {
  static const _tag = 'AutoEscalate';

  /// Whether a safety prompt is currently pending
  /// a user response.
  bool _isPromptPending = false;

  /// Timestamp when the safety prompt was shown.
  DateTime? _promptShownAt;

  /// Timer for the safety prompt timeout.
  Timer? _promptTimer;

  /// Callback invoked when the prompt times out
  /// without a user response — triggers escalation
  /// to the next tier.
  void Function()? onPromptTimeout;

  bool get isPromptPending => _isPromptPending;

  /// Reset all internal state. Call when a ride starts
  /// or ends.
  void reset() {
    _isPromptPending = false;
    _promptShownAt = null;
    _promptTimer?.cancel();
    _promptTimer = null;
    onPromptTimeout = null;
  }

  /// Evaluate the current threat assessment and
  /// determine what escalation action to take.
  ///
  /// Returns [Right] with [EscalationResult] on
  /// success, or [Left] with [Failure] on error.
  Future<Either<Failure, EscalationResult>> call(
    ThreatAssessment assessment,
  ) async {
    try {
      final level = assessment.level;
      final score = assessment.score;

      switch (level) {
        case ThreatLevel.green:
          // Safe — cancel any pending prompts
          _cancelPendingPrompt();

          AppLogger.debug(
            'Escalation: green ($score) — no action',
            tag: _tag,
          );

          return Right(
            EscalationResult(
              action: EscalationAction.none,
              level: level,
              score: score,
              message: 'Ride is safe',
            ),
          );

        case ThreatLevel.yellow:
          // Caution — prompt user if not already
          // prompted
          if (!_isPromptPending) {
            _startSafetyPrompt();

            AppLogger.info(
              'Escalation: yellow ($score) — '
              'prompting safety check',
              tag: _tag,
            );
          }

          return Right(
            EscalationResult(
              action:
                  EscalationAction.promptSafetyCheck,
              level: level,
              score: score,
              promptTimeout: const Duration(
                seconds:
                    AppDimensions.safetyPromptTimeout,
              ),
              message: 'Are you safe? Tap to confirm.',
            ),
          );

        case ThreatLevel.orange:
          // Warning — auto-notify emergency contacts
          _cancelPendingPrompt();

          AppLogger.warning(
            'Escalation: orange ($score) — '
            'notifying emergency contacts',
            tag: _tag,
          );

          return Right(
            EscalationResult(
              action: EscalationAction
                  .notifyEmergencyContacts,
              level: level,
              score: score,
              message: 'Notifying emergency contacts '
                  'with your location.',
            ),
          );

        case ThreatLevel.red:
          // Danger — full emergency protocol
          _cancelPendingPrompt();

          AppLogger.critical(
            'Escalation: red ($score) — '
            'FULL EMERGENCY PROTOCOL',
            tag: _tag,
          );

          return Right(
            EscalationResult(
              action: EscalationAction
                  .fullEmergencyProtocol,
              level: level,
              score: score,
              message: 'Emergency protocol activated. '
                  'Help is on the way.',
            ),
          );
      }
    } catch (e, st) {
      AppLogger.error(
        'Auto-escalation failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        ServerFailure(
          message: 'Auto-escalation failed: $e',
        ),
      );
    }
  }

  /// Mark the safety prompt as answered by the user.
  /// Resets the prompt state and cancels the timeout.
  void confirmSafe() {
    AppLogger.info(
      'User confirmed safe — '
      'cancelling escalation',
      tag: _tag,
    );
    _cancelPendingPrompt();
  }

  /// Check if the pending prompt has timed out.
  /// Returns true if the timeout has elapsed without
  /// a user response.
  bool get hasPromptTimedOut {
    if (!_isPromptPending || _promptShownAt == null) {
      return false;
    }
    final elapsed = DateTime.now()
        .difference(_promptShownAt!)
        .inSeconds;
    return elapsed >=
        AppDimensions.safetyPromptTimeout;
  }

  void _startSafetyPrompt() {
    _isPromptPending = true;
    _promptShownAt = DateTime.now();

    _promptTimer?.cancel();
    _promptTimer = Timer(
      const Duration(
        seconds: AppDimensions.safetyPromptTimeout,
      ),
      () {
        AppLogger.warning(
          'Safety prompt timed out — '
          'escalating to next tier',
          tag: _tag,
        );
        _isPromptPending = false;
        onPromptTimeout?.call();
      },
    );
  }

  void _cancelPendingPrompt() {
    _isPromptPending = false;
    _promptShownAt = null;
    _promptTimer?.cancel();
    _promptTimer = null;
  }
}
