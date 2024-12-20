// vad_handler_web.dart

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'vad_handler_base.dart';

/// Start listening for voice activity detection (JS-binding)
@JS('startListeningImpl')
external void startListeningImpl(
    double positiveSpeechThreshold,
    double negativeSpeechThreshold,
    int preSpeechPadFrames,
    int redemptionFrames,
    int minSpeechFrames,
    bool submitUserSpeechOnPause);

/// Stop listening for voice activity detection (JS-binding)
@JS('stopListeningImpl')
external void stopListeningImpl();

/// Check if the VAD is currently listening (JS-binding)
@JS('isListeningNow')
external bool isListeningNow();

/// Log a message to the console (JS-binding)
@JS('logMessage')
external void logMessage(String message);

/// Execute a Dart handler (JS-binding)
@JS('callDartFunction')
external void executeDartHandler();

/// VadHandlerWeb class
class VadHandlerWeb implements VadHandlerBase {
  final StreamController<List<double>> _onSpeechEndController =
      StreamController<List<double>>.broadcast();
  final StreamController<void> _onSpeechStartController =
      StreamController<void>.broadcast();
  final StreamController<void> _onVADMisfireController =
      StreamController<void>.broadcast();
  final StreamController<String> _onErrorController =
      StreamController<String>.broadcast();

  /// Whether to print debug messages
  bool isDebug = false;

  /// Constructor
  VadHandlerWeb({required bool isDebug}) {
    globalContext['executeDartHandler'] = handleEvent.toJS;
    isDebug = isDebug;
  }

  @override
  Stream<List<double>> get onSpeechEnd => _onSpeechEndController.stream;

  @override
  Stream<void> get onSpeechStart => _onSpeechStartController.stream;

  @override
  Stream<void> get onVADMisfire => _onVADMisfireController.stream;

  @override
  Stream<String> get onError => _onErrorController.stream;

  @override
  void startListening(
      {double positiveSpeechThreshold = 0.5,
      double negativeSpeechThreshold = 0.35,
      int preSpeechPadFrames = 1,
      int redemptionFrames = 8,
      int minSpeechFrames = 3,
      bool submitUserSpeechOnPause = false}) {
    if (isDebug) {
      debugPrint(
          'VadHandlerWeb: startListening: Calling startListeningImpl with parameters: '
          'positiveSpeechThreshold: $positiveSpeechThreshold, '
          'negativeSpeechThreshold: $negativeSpeechThreshold, '
          'preSpeechPadFrames: $preSpeechPadFrames, '
          'redemptionFrames: $redemptionFrames, '
          'minSpeechFrames: $minSpeechFrames, '
          'submitUserSpeechOnPause: $submitUserSpeechOnPause');
    }
    startListeningImpl(
        positiveSpeechThreshold,
        negativeSpeechThreshold,
        preSpeechPadFrames,
        redemptionFrames,
        minSpeechFrames,
        submitUserSpeechOnPause);
  }

  /// Handle an event from the JS side
  void handleEvent(String eventType, String payload) {
    try {
      Map<String, dynamic> eventData =
          payload.isNotEmpty ? json.decode(payload) : {};

      switch (eventType) {
        case 'onError':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onError: ${eventData['error']}');
          }
          _onErrorController.add(payload);
          break;
        case 'onSpeechEnd':
          if (eventData.containsKey('audioData')) {
            final List<double> audioData = (eventData['audioData'] as List)
                .map((e) => (e as num).toDouble())
                .toList();
            if (isDebug) {
              debugPrint(
                  'VadHandlerWeb: onSpeechEnd: first 5 samples: ${audioData.sublist(0, 5)}');
            }
            _onSpeechEndController.add(audioData);
          } else {
            if (isDebug) {
              debugPrint('Invalid VAD Data received: $eventData');
            }
          }
          break;
        case 'onSpeechStart':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onSpeechStart');
          }
          _onSpeechStartController.add(null);
          break;
        case 'onVADMisfire':
          if (isDebug) {
            debugPrint('VadHandlerWeb: onVADMisfire');
          }
          _onVADMisfireController.add(null);
          break;
        default:
          debugPrint("Unknown event: $eventType");
      }
    } catch (e, st) {
      debugPrint('Error handling event: $e');
      debugPrint('Stack Trace: $st');
    }
  }

  @override
  void dispose() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: dispose');
    }
    _onSpeechEndController.close();
    _onSpeechStartController.close();
    _onVADMisfireController.close();
    _onErrorController.close();
  }

  @override
  void stopListening() {
    if (isDebug) {
      debugPrint('VadHandlerWeb: stopListening');
    }
    stopListeningImpl();
  }
}

/// Create a VAD handler for the web
/// isDebug is used to print debug messages
/// modelPath is not used in the web implementation, adding it will not have any effect
VadHandlerBase createVadHandler({required isDebug, modelPath}) =>
    VadHandlerWeb(isDebug: isDebug);
