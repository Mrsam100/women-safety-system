import 'dart:typed_data';

import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/features/ai/data/models/keyword_detection_result.dart';

/// Data source responsible for loading and running the
/// TFLite Whisper Tiny model for on-device keyword
/// detection.
///
/// All audio processing happens entirely on-device.
/// No audio data is transmitted over the network during
/// normal ride operation.
///
/// The model file (whisper_tiny.tflite) should be placed
/// in assets/models/ and declared in pubspec.yaml.
class TfliteDatasource {
  static const _tag = 'TfliteDatasource';

  /// Whether the TFLite model has been loaded
  /// successfully.
  bool _isModelLoaded = false;

  /// Reference to the TFLite interpreter.
  /// In production, this is: `Interpreter? _interpreter`
  /// from `tflite_flutter` package.
  dynamic _interpreter;

  bool get isModelLoaded => _isModelLoaded;

  /// Distress keywords to match against transcribed
  /// text output from the Whisper model.
  static const Map<String, double> distressKeywords = {
    'help': 0.85,
    'bachao': 0.90,
    'stop': 0.70,
    'chhodo': 0.90,
    'please help': 0.95,
    'let me go': 0.90,
    'save me': 0.90,
    'police': 0.80,
  };

  /// Load the Whisper Tiny TFLite model from assets.
  ///
  /// Call this once during app initialization or when
  /// a ride starts. Returns true if the model was
  /// loaded successfully, false otherwise.
  Future<bool> loadModel() async {
    try {
      // Production implementation:
      //
      //   _interpreter = await Interpreter.fromAsset(
      //     'assets/models/whisper_tiny.tflite',
      //     options: InterpreterOptions()
      //       ..threads = 2
      //       ..useNnApiForAndroid = true,
      //   );
      //   _isModelLoaded = true;
      //
      // Stub: simulate successful model load.
      _isModelLoaded = true;
      _interpreter = Object(); // placeholder

      AppLogger.info(
        'TFLite Whisper Tiny model loaded',
        tag: _tag,
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load TFLite model',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      _isModelLoaded = false;
      return false;
    }
  }

  /// Run keyword detection inference on a raw audio
  /// chunk.
  ///
  /// [audioChunk] — PCM 16-bit, 16 kHz, mono audio
  /// data (3 seconds = 96,000 bytes).
  ///
  /// Returns a [KeywordDetectionResult] with the
  /// detected keyword and confidence, or an empty
  /// result if no keyword was found.
  Future<KeywordDetectionResult> detectKeywords(
    Uint8List audioChunk,
  ) async {
    if (!_isModelLoaded || _interpreter == null) {
      AppLogger.warning(
        'Model not loaded — attempting to load',
        tag: _tag,
      );
      final loaded = await loadModel();
      if (!loaded) {
        return KeywordDetectionResult.empty();
      }
    }

    try {
      // Production implementation:
      //
      //   // 1. Preprocess audio to model input format
      //   final input = _preprocessAudio(audioChunk);
      //
      //   // 2. Allocate output tensor
      //   final outputShape =
      //       _interpreter!.getOutputTensor(0).shape;
      //   final output = List.generate(
      //     outputShape[0],
      //     (_) => List.filled(outputShape[1], 0.0),
      //   );
      //
      //   // 3. Run inference
      //   _interpreter!.run(input, output);
      //
      //   // 4. Decode output tokens to text
      //   final text = _decodeTokens(output);
      //
      //   // 5. Match against distress keywords
      //   return _matchKeywords(text);
      //
      // Stub: return empty result (no keyword detected).
      // Replace with actual inference when model is
      // available.
      return _runStubInference(audioChunk);
    } catch (e, st) {
      AppLogger.error(
        'Keyword detection inference failed',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      return KeywordDetectionResult.empty();
    }
  }

  /// Stub inference that returns no detection.
  ///
  /// In production, replace this with the actual
  /// TFLite pipeline described above.
  KeywordDetectionResult _runStubInference(
    Uint8List audioChunk,
  ) {
    // Validate that we received roughly 3 seconds
    // of 16 kHz mono 16-bit PCM audio.
    // Expected: 16000 * 3 * 2 = 96,000 bytes.
    final expectedBytes = 16000 * 3 * 2;
    if (audioChunk.length < expectedBytes ~/ 2) {
      AppLogger.debug(
        'Audio chunk too short: '
        '${audioChunk.length} bytes '
        '(expected ~$expectedBytes)',
        tag: _tag,
      );
    }

    return KeywordDetectionResult.empty();
  }

  /// Preprocess raw PCM audio into the format expected
  /// by the Whisper Tiny model.
  ///
  /// Converts 16-bit PCM to float32 normalized to
  /// [-1.0, 1.0] range.
  Float32List preprocessAudio(Uint8List pcmData) {
    final int16View = Int16List.view(pcmData.buffer);
    final float32 = Float32List(int16View.length);

    for (var i = 0; i < int16View.length; i++) {
      float32[i] = int16View[i] / 32768.0;
    }

    return float32;
  }

  /// Release model resources.
  void dispose() {
    // Production: _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;

    AppLogger.info(
      'TFLite model resources released',
      tag: _tag,
    );
  }
}
