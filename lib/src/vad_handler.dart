// vad_handler.dart

import 'package:vad/src/vad_handler_base.dart';
import 'vad_handler_web.dart' if (dart.library.io) 'vad_handler_non_web.dart'
    as implementation;

/// VadHandler class
class VadHandler {
  /// Create a new instance of VadHandler
  /// [isDebug] flag
  /// [modelPath] path to the model file (optional and only used for non-web)
  /// Default model path is 'packages/vad/assets/models/silero_vad.ort'
  /// Returns a new instance of VadHandlerBase
  static VadHandlerBase create(
      {required bool isDebug,
      String modelPath = 'packages/vad/assets/models/silero_vad.ort'}) {
    return implementation.createVadHandler(
        isDebug: isDebug, modelPath: modelPath);
  }
}
