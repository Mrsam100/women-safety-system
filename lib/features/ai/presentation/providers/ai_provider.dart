import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/data/datasources/tflite_datasource.dart';
import 'package:saferide/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:saferide/features/ai/domain/entities/threat_assessment.dart';
import 'package:saferide/features/ai/domain/repositories/ai_repository.dart';
import 'package:saferide/features/ai/domain/usecases/auto_escalate.dart';
import 'package:saferide/features/ai/domain/usecases/calculate_threat_score.dart';
import 'package:saferide/features/ai/domain/usecases/detect_keywords.dart';

// ─── Datasource & Repository providers ───

final tfliteDatasourceProvider =
    Provider<TfliteDatasource>((ref) {
  return TfliteDatasource();
});

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) {
    return AiRepositoryImpl(
      tfliteDatasource: ref.watch(
        tfliteDatasourceProvider,
      ),
    );
  },
);

// ─── Use case providers ───

final detectKeywordsUseCaseProvider =
    Provider<DetectKeywords>((ref) {
  return DetectKeywords(
    ref.watch(aiRepositoryProvider),
  );
});

final calculateThreatScoreUseCaseProvider =
    Provider<CalculateThreatScore>((ref) {
  return CalculateThreatScore();
});

final autoEscalateUseCaseProvider =
    Provider<AutoEscalate>((ref) {
  return AutoEscalate();
});

// ─── AI State ───

/// Represents the full AI monitoring state during
/// an active ride.
class AiMonitoringState {
  final ThreatAssessment assessment;
  final bool isMonitoring;
  final bool isModelLoaded;
  final EscalationAction? lastEscalationAction;
  final String? lastDetectedKeyword;
  final double? lastKeywordConfidence;
  final String? errorMessage;

  const AiMonitoringState({
    required this.assessment,
    this.isMonitoring = false,
    this.isModelLoaded = false,
    this.lastEscalationAction,
    this.lastDetectedKeyword,
    this.lastKeywordConfidence,
    this.errorMessage,
  });

  factory AiMonitoringState.initial() =>
      AiMonitoringState(
        assessment: ThreatAssessment.initial(),
      );

  AiMonitoringState copyWith({
    ThreatAssessment? assessment,
    bool? isMonitoring,
    bool? isModelLoaded,
    EscalationAction? lastEscalationAction,
    String? lastDetectedKeyword,
    double? lastKeywordConfidence,
    String? errorMessage,
  }) {
    return AiMonitoringState(
      assessment: assessment ?? this.assessment,
      isMonitoring:
          isMonitoring ?? this.isMonitoring,
      isModelLoaded:
          isModelLoaded ?? this.isModelLoaded,
      lastEscalationAction: lastEscalationAction ??
          this.lastEscalationAction,
      lastDetectedKeyword: lastDetectedKeyword ??
          this.lastDetectedKeyword,
      lastKeywordConfidence: lastKeywordConfidence ??
          this.lastKeywordConfidence,
      errorMessage: errorMessage,
    );
  }
}

// ─── AI StateNotifier ───

/// Manages the AI monitoring lifecycle during an active
/// ride. Runs keyword detection on audio chunks and
/// recalculates the threat score every 10 seconds.
/// Connects to the auto-escalation engine to trigger
/// safety actions based on the threat level.
class AiMonitoringNotifier
    extends StateNotifier<AiMonitoringState> {
  static const _tag = 'AiMonitoringNotifier';

  final DetectKeywords _detectKeywords;
  final CalculateThreatScore _calculateThreatScore;
  final AutoEscalate _autoEscalate;
  final AiRepositoryImpl _repository;

  Timer? _scoringTimer;

  /// Current signal inputs — updated by external
  /// providers (ride, location, shake, etc.).
  ThreatSignalInput _currentSignals =
      const ThreatSignalInput();

  AiMonitoringNotifier({
    required DetectKeywords detectKeywords,
    required CalculateThreatScore calculateThreatScore,
    required AutoEscalate autoEscalate,
    required AiRepositoryImpl repository,
  })  : _detectKeywords = detectKeywords,
        _calculateThreatScore = calculateThreatScore,
        _autoEscalate = autoEscalate,
        _repository = repository,
        super(AiMonitoringState.initial());

  /// Start AI monitoring for an active ride.
  ///
  /// Loads the TFLite model and begins periodic
  /// threat score recalculation.
  Future<void> startMonitoring() async {
    if (state.isMonitoring) return;

    AppLogger.info(
      'Starting AI monitoring',
      tag: _tag,
    );

    // Initialize TFLite model
    final modelLoaded = await _repository.initializeModel();

    state = state.copyWith(
      isMonitoring: true,
      isModelLoaded: modelLoaded,
    );

    // Set up the prompt timeout callback
    _autoEscalate.onPromptTimeout = () {
      _onPromptTimeout();
    };

    // Start periodic scoring timer
    _scoringTimer = Timer.periodic(
      const Duration(
        seconds: kRecalcIntervalSeconds,
      ),
      (_) => _recalculateScore(),
    );

    // Run initial calculation
    await _recalculateScore();
  }

  /// Stop AI monitoring when the ride ends.
  void stopMonitoring() {
    AppLogger.info(
      'Stopping AI monitoring',
      tag: _tag,
    );

    _scoringTimer?.cancel();
    _scoringTimer = null;

    _calculateThreatScore.reset();
    _autoEscalate.reset();
    _repository.clearCache();
    _repository.disposeModel();

    _currentSignals = const ThreatSignalInput();

    state = AiMonitoringState.initial();
  }

  /// Process a 3-second audio chunk for keyword
  /// detection.
  Future<void> processAudioChunk(
    Uint8List audioChunk,
  ) async {
    if (!state.isMonitoring) return;

    final result = await _detectKeywords(audioChunk);

    result.fold(
      (failure) {
        AppLogger.error(
          'Audio processing failed: '
          '${failure.message}',
          tag: _tag,
        );
      },
      (detection) {
        if (detection.isDetected) {
          state = state.copyWith(
            lastDetectedKeyword: detection.keyword,
            lastKeywordConfidence: detection.confidence,
          );

          // Update signal inputs with keyword
          _currentSignals = ThreatSignalInput(
            isRouteDeviated:
                _currentSignals.isRouteDeviated,
            isSpeedAnomalous:
                _currentSignals.isSpeedAnomalous,
            distressKeyword: detection.keyword,
            keywordConfidence: detection.confidence,
            isIsolatedArea:
                _currentSignals.isIsolatedArea,
            isNighttime: _currentSignals.isNighttime,
            isExtendedStop:
                _currentSignals.isExtendedStop,
            isShakeAlert:
                _currentSignals.isShakeAlert,
            isPanicButton:
                _currentSignals.isPanicButton,
            areaRiskScore:
                _currentSignals.areaRiskScore,
          );

          // Immediately recalculate on keyword
          _recalculateScore();
        }
      },
    );
  }

  /// Update signal inputs from external sources.
  ///
  /// Called by ride, location, and shake providers
  /// when their state changes.
  void updateSignals(ThreatSignalInput signals) {
    _currentSignals = signals;
  }

  /// Convenience method to update a single signal
  /// flag without replacing the entire input.
  void updateRouteDeviation(bool isDeviated) {
    _currentSignals = ThreatSignalInput(
      isRouteDeviated: isDeviated,
      isSpeedAnomalous:
          _currentSignals.isSpeedAnomalous,
      distressKeyword:
          _currentSignals.distressKeyword,
      keywordConfidence:
          _currentSignals.keywordConfidence,
      isIsolatedArea:
          _currentSignals.isIsolatedArea,
      isNighttime: _currentSignals.isNighttime,
      isExtendedStop:
          _currentSignals.isExtendedStop,
      isShakeAlert: _currentSignals.isShakeAlert,
      isPanicButton: _currentSignals.isPanicButton,
      areaRiskScore: _currentSignals.areaRiskScore,
    );
  }

  void updateSpeedAnomaly(bool isAnomalous) {
    _currentSignals = ThreatSignalInput(
      isRouteDeviated:
          _currentSignals.isRouteDeviated,
      isSpeedAnomalous: isAnomalous,
      distressKeyword:
          _currentSignals.distressKeyword,
      keywordConfidence:
          _currentSignals.keywordConfidence,
      isIsolatedArea:
          _currentSignals.isIsolatedArea,
      isNighttime: _currentSignals.isNighttime,
      isExtendedStop:
          _currentSignals.isExtendedStop,
      isShakeAlert: _currentSignals.isShakeAlert,
      isPanicButton: _currentSignals.isPanicButton,
      areaRiskScore: _currentSignals.areaRiskScore,
    );
  }

  void updateShakeAlert(bool isShake) {
    _currentSignals = ThreatSignalInput(
      isRouteDeviated:
          _currentSignals.isRouteDeviated,
      isSpeedAnomalous:
          _currentSignals.isSpeedAnomalous,
      distressKeyword:
          _currentSignals.distressKeyword,
      keywordConfidence:
          _currentSignals.keywordConfidence,
      isIsolatedArea:
          _currentSignals.isIsolatedArea,
      isNighttime: _currentSignals.isNighttime,
      isExtendedStop:
          _currentSignals.isExtendedStop,
      isShakeAlert: isShake,
      isPanicButton: _currentSignals.isPanicButton,
      areaRiskScore: _currentSignals.areaRiskScore,
    );
    // Immediately recalculate on shake
    if (isShake) _recalculateScore();
  }

  void updatePanicButton(bool isPressed) {
    _currentSignals = ThreatSignalInput(
      isRouteDeviated:
          _currentSignals.isRouteDeviated,
      isSpeedAnomalous:
          _currentSignals.isSpeedAnomalous,
      distressKeyword:
          _currentSignals.distressKeyword,
      keywordConfidence:
          _currentSignals.keywordConfidence,
      isIsolatedArea:
          _currentSignals.isIsolatedArea,
      isNighttime: _currentSignals.isNighttime,
      isExtendedStop:
          _currentSignals.isExtendedStop,
      isShakeAlert: _currentSignals.isShakeAlert,
      isPanicButton: isPressed,
      areaRiskScore: _currentSignals.areaRiskScore,
    );
    // Immediately recalculate on panic
    if (isPressed) _recalculateScore();
  }

  /// User confirmed they are safe — cancel the
  /// yellow-level prompt.
  void confirmSafe() {
    _autoEscalate.confirmSafe();

    // Clear keyword detection state
    _currentSignals = ThreatSignalInput(
      isRouteDeviated:
          _currentSignals.isRouteDeviated,
      isSpeedAnomalous:
          _currentSignals.isSpeedAnomalous,
      distressKeyword: null,
      keywordConfidence: 0.0,
      isIsolatedArea:
          _currentSignals.isIsolatedArea,
      isNighttime: _currentSignals.isNighttime,
      isExtendedStop:
          _currentSignals.isExtendedStop,
      isShakeAlert: false,
      isPanicButton: false,
      areaRiskScore: _currentSignals.areaRiskScore,
    );

    state = state.copyWith(
      lastDetectedKeyword: null,
      lastKeywordConfidence: null,
      lastEscalationAction: EscalationAction.none,
    );
  }

  /// Recalculate the threat score from current signals
  /// and run auto-escalation.
  Future<void> _recalculateScore() async {
    if (!state.isMonitoring) return;

    final scoreResult =
        await _calculateThreatScore(_currentSignals);

    await scoreResult.fold(
      (failure) async {
        state = state.copyWith(
          errorMessage: failure.message,
        );
      },
      (assessment) async {
        state = state.copyWith(
          assessment: assessment,
          errorMessage: null,
        );

        // Run auto-escalation
        final escalationResult =
            await _autoEscalate(assessment);

        escalationResult.fold(
          (failure) {
            AppLogger.error(
              'Escalation failed: ${failure.message}',
              tag: _tag,
            );
          },
          (result) {
            state = state.copyWith(
              lastEscalationAction: result.action,
            );
          },
        );
      },
    );
  }

  /// Called when the safety prompt times out without
  /// user response — escalate to the next tier.
  void _onPromptTimeout() {
    AppLogger.warning(
      'Safety prompt timed out — '
      'escalating threat level',
      tag: _tag,
    );

    // Bump the score to orange range to trigger
    // contact notification
    final currentScore = state.assessment.score;
    if (currentScore <= AppDimensions.yellowMax) {
      final boostedScore =
          AppDimensions.yellowMax + 1;
      state = state.copyWith(
        assessment: state.assessment.copyWith(
          score: boostedScore,
          lastUpdated: DateTime.now(),
        ),
      );
      _recalculateScore();
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

// ─── Provider ───

final aiMonitoringNotifierProvider =
    StateNotifierProvider<AiMonitoringNotifier,
        AiMonitoringState>(
  (ref) {
    final repository = ref.watch(aiRepositoryProvider)
        as AiRepositoryImpl;
    return AiMonitoringNotifier(
      detectKeywords: ref.watch(
        detectKeywordsUseCaseProvider,
      ),
      calculateThreatScore: ref.watch(
        calculateThreatScoreUseCaseProvider,
      ),
      autoEscalate: ref.watch(
        autoEscalateUseCaseProvider,
      ),
      repository: repository,
    );
  },
);

/// Convenience provider that exposes just the current
/// threat assessment for widgets that only need the
/// score and level.
final currentThreatAssessmentProvider =
    Provider<ThreatAssessment>((ref) {
  return ref
      .watch(aiMonitoringNotifierProvider)
      .assessment;
});

/// Convenience provider for the current threat level.
final currentThreatLevelProvider =
    Provider<ThreatLevel>((ref) {
  return ref
      .watch(currentThreatAssessmentProvider)
      .level;
});
