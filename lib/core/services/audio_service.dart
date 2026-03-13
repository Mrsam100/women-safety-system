import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/utils/logger.dart';

class AudioService {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  /// Circular buffer of recent audio file paths.
  final _audioBuffer = Queue<String>();
  Timer? _bufferTimer;
  bool _isRecording = false;
  int _chunkIndex = 0;
  String? _currentChunkPath;

  bool get isRecording => _isRecording;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start the circular audio buffer that keeps
  /// the last [AppDimensions.audioBufferSeconds] seconds.
  Future<void> startCircularBuffer(String tempDir) async {
    if (_isRecording) return;

    final hasPerms = await hasPermission();
    if (!hasPerms) {
      throw Exception('Microphone permission not granted');
    }

    _isRecording = true;
    _chunkIndex = 0;
    _audioBuffer.clear();

    await _recordNextChunk(tempDir);

    _bufferTimer = Timer.periodic(
      const Duration(
        seconds: AppDimensions.audioChunkSeconds,
      ),
      (_) => _recordNextChunk(tempDir),
    );

    AppLogger.info(
      'Circular audio buffer started',
      tag: 'AudioService',
    );
  }

  Future<void> _recordNextChunk(String tempDir) async {
    // Stop previous chunk
    if (_currentChunkPath != null) {
      await _recorder.stop();
    }

    // Remove oldest chunk if buffer exceeds limit
    final maxChunks = AppDimensions.audioBufferSeconds ~/
        AppDimensions.audioChunkSeconds;
    while (_audioBuffer.length >= maxChunks) {
      final oldest = _audioBuffer.removeFirst();
      try {
        await File(oldest).delete();
      } catch (_) {}
    }

    // Start new chunk
    _chunkIndex++;
    _currentChunkPath = '$tempDir/chunk_$_chunkIndex.m4a';
    _audioBuffer.add(_currentChunkPath!);

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _currentChunkPath!,
    );
  }

  /// Stop recording and return all buffered audio paths.
  Future<List<String>> stopAndGetBuffer() async {
    _bufferTimer?.cancel();
    _bufferTimer = null;

    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }

    final paths = _audioBuffer.toList();
    AppLogger.info(
      'Audio buffer stopped, ${paths.length} chunks saved',
      tag: 'AudioService',
    );
    return paths;
  }

  /// Play audio from file path.
  Future<void> playAudio(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  /// Play audio from asset.
  Future<void> playAsset(String assetPath) async {
    await _player.setAsset(assetPath);
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    _bufferTimer?.cancel();
    if (_isRecording) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    await _player.dispose();
  }
}
