// vad_iterator.dart
import 'package:vad/src/vad_iterator_base.dart';
import 'vad_iterator_web.dart' if (dart.library.io) 'vad_iterator_non_web.dart'
    as implementation;

/// VadIterator class
class VadIterator {
  /// Create a new instance of VadIterator
  static VadIteratorBase create({
    required bool isDebug,
    required double positiveSpeechThreshold,
    required double negativeSpeechThreshold,
    required int redemptionFrames,
    required int preSpeechPadFrames,
    required int minSpeechFrames,
    required bool submitUserSpeechOnPause,
  }) {
    return implementation.createVadIterator(
        isDebug: isDebug,
        positiveSpeechThreshold: positiveSpeechThreshold,
        negativeSpeechThreshold: negativeSpeechThreshold,
        redemptionFrames: redemptionFrames,
        preSpeechPadFrames: preSpeechPadFrames,
        minSpeechFrames: minSpeechFrames,
        submitUserSpeechOnPause: submitUserSpeechOnPause);
  }
}
