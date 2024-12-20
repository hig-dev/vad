// vad_handler_base.dart

import 'dart:async';

/// Abstract class for VAD handler
abstract class VadHandlerBase {
  /// Stream of speech end events
  Stream<List<double>> get onSpeechEnd;

  /// Stream of speech start events
  Stream<void> get onSpeechStart;

  /// Stream of VAD misfire events
  Stream<void> get onVADMisfire;

  /// Stream of error events
  Stream<String> get onError;

  /// Start listening for speech events
  void startListening(
      {double positiveSpeechThreshold = 0.5,
      double negativeSpeechThreshold = 0.35,
      int preSpeechPadFrames = 3,
      int redemptionFrames = 24,
      int frameSamples = 512,
      int minSpeechFrames = 9,
      bool submitUserSpeechOnPause = false});

  /// Stop listening for speech events
  void stopListening();

  /// Dispose the VAD handler
  void dispose();
}
