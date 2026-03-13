import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:saferide/core/errors/failures.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/domain/entities/keyword_detection.dart';
import 'package:saferide/features/ai/domain/repositories/ai_repository.dart';

/// Distress keywords to detect — includes English and
/// Hindi phrases. Each entry maps to a base confidence
/// boost when detected.
const Map<String, double> _distressKeywords = {
  'help': 0.85,
  'bachao': 0.90,
  'stop': 0.70,
  'chhodo': 0.90,
  'please help': 0.95,
  'let me go': 0.90,
  'save me': 0.90,
  'police': 0.80,
};

/// Payload sent to the background isolate for keyword
/// detection processing.
class _DetectionPayload {
  final Uint8List audioChunk;
  final SendPort responsePort;

  const _DetectionPayload({
    required this.audioChunk,
    required this.responsePort,
  });
}

/// Result returned from the background isolate.
class _DetectionResponse {
  final String? keyword;
  final double confidence;
  final bool hasError;
  final String? errorMessage;

  const _DetectionResponse({
    this.keyword,
    this.confidence = 0.0,
    this.hasError = false,
    this.errorMessage,
  });
}

/// Process 3-second audio chunks through TFLite
/// Whisper Tiny model on a background [Isolate].
///
/// Detects distress keywords in English and Hindi:
/// "help", "bachao", "stop", "chhodo", "please help",
/// "let me go", "save me", "police".
///
/// Returns a [KeywordDetectionResult] with the detected
/// keyword and confidence score (0.0–1.0).
class DetectKeywords {
  static const _tag = 'DetectKeywords';

  final AiRepository _repository;

  const DetectKeywords(this._repository);

  /// Run keyword detection on a 3-second audio chunk.
  ///
  /// The audio is processed in a background isolate to
  /// avoid blocking the UI thread.
  Future<Either<Failure, KeywordDetection>> call(
    Uint8List audioChunk,
  ) async {
    try {
      // Validate chunk is not empty
      if (audioChunk.isEmpty) {
        return const Left(
          AudioFailure(
            message: 'Audio chunk is empty',
          ),
        );
      }

      // Run detection on background isolate
      final response = await _runOnIsolate(audioChunk);

      if (response.hasError) {
        AppLogger.error(
          'Isolate detection error: '
          '${response.errorMessage}',
          tag: _tag,
        );
        return Left(
          AudioFailure(
            message: response.errorMessage ??
                'Keyword detection failed',
          ),
        );
      }

      if (response.keyword != null &&
          response.confidence > 0.0) {
        AppLogger.warning(
          'Distress keyword detected: '
          '"${response.keyword}" '
          '(confidence: '
          '${response.confidence.toStringAsFixed(2)})',
          tag: _tag,
        );
      }

      // Delegate to repository for persistence and
      // model inference
      return _repository.detectKeywords(audioChunk);
    } catch (e, st) {
      AppLogger.error(
        'Keyword detection failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return Left(
        AudioFailure(
          message: 'Keyword detection failed: $e',
        ),
      );
    }
  }

  /// Spawn a background isolate for audio processing.
  Future<_DetectionResponse> _runOnIsolate(
    Uint8List audioChunk,
  ) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _isolateEntryPoint,
        _DetectionPayload(
          audioChunk: audioChunk,
          responsePort: receivePort.sendPort,
        ),
      );

      final response =
          await receivePort.first as _DetectionResponse;
      return response;
    } catch (e) {
      return _DetectionResponse(
        hasError: true,
        errorMessage: 'Isolate spawn failed: $e',
      );
    } finally {
      receivePort.close();
    }
  }

  /// Entry point for the background isolate.
  ///
  /// Runs lightweight keyword matching on transcribed
  /// text from the TFLite Whisper Tiny model output.
  static void _isolateEntryPoint(
    _DetectionPayload payload,
  ) {
    try {
      // In production, this loads the TFLite Whisper
      // Tiny model and runs inference on the audio
      // chunk. The model converts speech to text, then
      // we match against known distress keywords.
      //
      // The TFLite interpreter runs entirely on-device
      // — no network calls are made. Audio never leaves
      // the phone during normal operation.
      //
      // Stub: simulate transcription + keyword matching.
      // The actual implementation initializes the TFLite
      // interpreter in the isolate, feeds the audio
      // through Whisper Tiny, and scans the output text.
      final transcribedText =
          _simulateTranscription(payload.audioChunk);

      String? detectedKeyword;
      double bestConfidence = 0.0;

      final lowerText = transcribedText.toLowerCase();

      for (final entry in _distressKeywords.entries) {
        if (lowerText.contains(entry.key)) {
          if (entry.value > bestConfidence) {
            detectedKeyword = entry.key;
            bestConfidence = entry.value;
          }
        }
      }

      payload.responsePort.send(
        _DetectionResponse(
          keyword: detectedKeyword,
          confidence: bestConfidence,
        ),
      );
    } catch (e) {
      payload.responsePort.send(
        _DetectionResponse(
          hasError: true,
          errorMessage: 'Detection error: $e',
        ),
      );
    }
  }

  /// Stub transcription — in production this runs the
  /// TFLite Whisper Tiny model on the raw audio bytes.
  ///
  /// Input: PCM 16-bit, 16 kHz, mono audio chunk.
  /// Output: transcribed text string.
  static String _simulateTranscription(
    Uint8List audioChunk,
  ) {
    // TODO: Replace with actual TFLite inference:
    //
    //   final interpreter = Interpreter.fromBuffer(
    //     modelBytes,
    //   );
    //   final input = _preprocessAudio(audioChunk);
    //   final output = List.filled(outputSize, 0.0)
    //       .reshape([1, outputSize]);
    //   interpreter.run(input, output);
    //   return _decodeTokens(output);
    //
    // For now, return empty string (no keyword found).
    return '';
  }
}

/// Expose the distress keyword map for use by other
/// components (e.g., threat score calculation).
Map<String, double> get distressKeywords =>
    Map.unmodifiable(_distressKeywords);
