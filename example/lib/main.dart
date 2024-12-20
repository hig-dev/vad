// main.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:vad/vad.dart';
import 'audio_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VAD Example',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.blue[400],
          inactiveTrackColor: Colors.grey[800],
          thumbColor: Colors.blue[300],
          overlayColor: Colors.blue.withAlpha(32),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[300],
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum RecordingType {
  speech,
  misfire,
}

class Recording {
  final List<double>? samples;
  final RecordingType type;
  final DateTime timestamp;

  Recording({
    this.samples,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Recording> recordings = [];
  final audioplayers.AudioPlayer _audioPlayer = audioplayers.AudioPlayer();
  final _vadHandler = VadHandler.create(isDebug: true);
  bool isListening = false;
  int frameSamples = 512; // 1 frame = 1536 samples = 96ms
  int minSpeechFrames = 9;
  int preSpeechPadFrames = 10;
  int redemptionFrames = 8;
  bool submitUserSpeechOnPause = false;

  // Audio player state
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _setupAudioPlayerListeners();
    _setupVadHandler();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _currentlyPlayingIndex = null;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == audioplayers.PlayerState.playing;
      });
    });
  }

  void _setupVadHandler() {
    _vadHandler.onSpeechStart.listen((_) {
      debugPrint('Speech detected.');
    });

    _vadHandler.onSpeechEnd.listen((List<double> samples) {
      setState(() {
        recordings.add(Recording(
          samples: samples,
          type: RecordingType.speech,
        ));
      });
      debugPrint('Speech ended, recording added.');
    });

    _vadHandler.onVADMisfire.listen((_) {
      setState(() {
        recordings.add(Recording(type: RecordingType.misfire));
      });
      debugPrint('VAD misfire detected.');
    });

    _vadHandler.onError.listen((String message) {
      debugPrint('Error: $message');
    });
  }

  Future<void> _initializeAudioPlayer() async {
    await _audioPlayer.setAudioContext(
      audioplayers.AudioContext(
        iOS: audioplayers.AudioContextIOS(
          options: const {audioplayers.AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  Future<void> _playRecording(Recording recording, int index) async {
    if (recording.type == RecordingType.misfire) return;

    try {
      if (_currentlyPlayingIndex == index && _isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_currentlyPlayingIndex != index) {
          String uri = AudioUtils.createWavUrl(recording.samples!);
          await _audioPlayer.play(audioplayers.UrlSource(uri));
          setState(() {
            _currentlyPlayingIndex = index;
            _isPlaying = true;
          });
        } else {
          await _audioPlayer.resume();
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    setState(() {
      _position = position;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _vadHandler.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordingItem(Recording recording, int index) {
    final bool isCurrentlyPlaying = _currentlyPlayingIndex == index;
    final bool isMisfire = recording.type == RecordingType.misfire;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          ListTile(
            leading: isMisfire
                ? const CircleAvatar(
                    backgroundColor: Colors.red,
                    child:
                        Icon(Icons.warning_amber_rounded, color: Colors.white),
                  )
                : CircleAvatar(
                    backgroundColor: Colors.blue[900],
                    child: Icon(
                      isCurrentlyPlaying && _isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.blue[100],
                    ),
                  ),
            title: Text(
              isMisfire ? 'Misfire Event' : 'Recording ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMisfire ? Colors.red[300] : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatTimestamp(recording.timestamp)),
                if (!isMisfire)
                  Text(
                    '${(recording.samples!.length / 16000).toStringAsFixed(1)} seconds',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
              ],
            ),
            onTap: isMisfire ? null : () => _playRecording(recording, index),
          ),
          if (isCurrentlyPlaying && !isMisfire) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      min: 0,
                      max: _duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        _seekTo(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VAD Example"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                return _buildRecordingItem(recordings[index], index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      if (isListening) {
                        _vadHandler.stopListening();
                      } else {
                        _vadHandler.startListening(
                          submitUserSpeechOnPause: submitUserSpeechOnPause,
                          preSpeechPadFrames: preSpeechPadFrames,
                          redemptionFrames: redemptionFrames,
                        );
                      }
                      isListening = !isListening;
                    });
                  },
                  icon: Icon(isListening ? Icons.stop : Icons.mic),
                  label:
                      Text(isListening ? "Stop Listening" : "Start Listening"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final status = await Permission.microphone.request();
                    debugPrint("Microphone permission status: $status");
                  },
                  icon: const Icon(Icons.settings_voice),
                  label: const Text("Request Microphone Permission"),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
