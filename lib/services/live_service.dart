import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../features/modes/modes.dart';
import 'assistant_service.dart';
import 'memory_service.dart';
import 'phone_control.dart';
import 'phone_tools.dart';
import 'settings_service.dart';

enum LiveState { idle, connecting, listening, speaking }

/// Gemini Live (gemini-3.8-live) se awaaz me baat karne ka kaam.
/// Mic (16kHz) -> Gemini, Gemini (24kHz awaaz) -> speaker.
class LiveService {
  // Model aur awaaz yahan se badlo.
  static const model = 'models/gemini-3.8-live';
  static const voiceName = 'Leda';

  final _settings = SettingsService();
  final _recorder = AudioRecorder();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  StreamSubscription? _micSub;
  Timer? _listenTimer;

  bool _active = false;
  bool _setupDone = false;
  bool _playerStarted = false;
  bool _flushing = false;
  bool _dropAudio = false;

  /// true: Sara bol rahi ho tab bhi tum beech me tok sakte ho. Sirf earphones
  /// me ON rakho, speaker me Sara khud ki awaaz sun leti hai.
  bool bargeIn = false;

  /// Sirf wake word wale session me 'sleep_now' tool do. Normal Voice me
  /// nahi, warna Hindi ke aam shabd (jaise 'bas') se session band ho jata hai.
  bool enableSleepTool = false;
  bool _sleepPending = false;
  final _mem = MemoryService();
  final _pc = PhoneControl();
  String _uBuf = '';
  String _zBuf = '';

  /// Sara ne 'sleep_now' bola: baat khatam, ab so jao.
  void Function()? onSleep;

  static const _sleepDecl = <String, dynamic>{
    'name': 'sleep_now',
    'description':
        'Baat khatam hone par call karo, jab user bye, so ja ya bas kahe.',
  };
  DateTime _speakUntil = DateTime.fromMillisecondsSinceEpoch(0);

  void Function(LiveState state)? onState;
  void Function(String text, bool isUser)? onTranscript;
  void Function()? onTurnComplete;
  void Function(String message)? onError;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _setupDone = false;
    _playerStarted = false;
    onState?.call(LiveState.connecting);

    final key = await _settings.getApiKey();
    if (key == null || key.isEmpty) {
      return _fail('Pehle Settings me Gemini API key daalo.');
    }
    if (!await _recorder.hasPermission()) {
      return _fail('Mic ki permission chahiye. Phone Settings se allow karo.');
    }

    // App se bahar jaane par bhi bolna aur sunna chalta rahe.
    await _pc.keepAliveStart();

    final mode = Modes.byId(await _settings.getMode());
    final memBlock = await _mem.promptBlock(recentLines: 10);
    const languageRule =
        'BHASHA NIYAM (sabse zaroori): User Hindi, Hinglish ya English me '
        'bolega. Hamesha Hindi/Hinglish ya English me hi jawab do, jis bhasha '
        'me user bole usi me. Kabhi koi aur bhasha (jaise Spanish, French, '
        'Arabic) mat bolo. Awaaz saaf na ho to Hindi me kaho "dobara bolo".';
    final sleepRule = enableSleepTool
        ? ' Jab user saaf shabdon me alvida kahe ("bye", "alvida", '
            '"good night", "so ja", "ab band ho ja") tabhi sleep_now tool '
            'call karo aur chhota alvida bolo. "bas", "theek hai" jaise aam '
            'shabdon par kabhi sleep_now call mat karo.'
        : '';
    final prompt = '$languageRule\n\n${AssistantService.basePrompt}\n\n'
        'Abhi ka mode: ${mode.name}. ${mode.prompt}\n\n'
        'Tum awaaz me baat kar rahi ho, isliye chhote, natural, bolchaal '
        'wale jawab do. Agar tum bol rahi ho aur user beech me "ruk jao" '
        'ya "stop" bole to turant ruk jao.$sleepRule\n\n'
        '${PhoneTools.prompt}'
        '${memBlock.isEmpty ? '' : '\n\n$memBlock'}';

    try {
      await FlutterPcmSound.setup(sampleRate: 24000, channelCount: 1);

      final uri = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/'
        'google.ai.generativelanguage.v1alpha.GenerativeService.'
        'BidiGenerateContent?key=$key',
      );
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      await ch.ready;

      _wsSub = ch.stream.listen(
        _onMessage,
        onError: (e) => _fail('Connection me dikkat: $e'),
        onDone: _onClosed,
      );

      ch.sink.add(jsonEncode({
        'setup': {
          'model': model,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': voiceName}
              }
            },
          },
          'systemInstruction': {
            'parts': [
              {'text': prompt}
            ]
          },
          'tools': [
            {
              'functionDeclarations': [
                ...PhoneTools.declarations,
                if (enableSleepTool) _sleepDecl,
              ]
            }
          ],
          'realtimeInputConfig': {
            'automaticActivityDetection': {
              'startOfSpeechSensitivity': 'START_SENSITIVITY_HIGH',
              'endOfSpeechSensitivity': 'END_SENSITIVITY_HIGH',
              'prefixPaddingMs': 100,
              'silenceDurationMs': 700,
            },
          },
          'inputAudioTranscription': {},
          'outputAudioTranscription': {},
        }
      }));
    } catch (e) {
      _fail('Connect nahi ho paya: $e');
    }
  }

  Future<void> _onMessage(dynamic raw) async {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final data = jsonDecode(text) as Map<String, dynamic>;

      if (data.containsKey('setupComplete')) {
        _setupDone = true;
        await _startMic();
        return;
      }

      // AI ne koi phone-action maanga hai
      final tc = data['toolCall'];
      if (tc is Map && tc['functionCalls'] is List) {
        final responses = <Map<String, dynamic>>[];
        for (final c in tc['functionCalls']) {
          final args = Map<String, dynamic>.from((c['args'] as Map?) ?? {});
          String result;
          if (c['name'] == 'sleep_now') {
            _sleepPending = true;
            result = 'ok';
          } else {
            result = await PhoneTools.run('${c['name']}', args);
          }
          responses.add({
            'id': c['id'],
            'name': c['name'],
            'response': {'result': result},
          });
        }
        _channel?.sink.add(jsonEncode({
          'toolResponse': {'functionResponses': responses}
        }));
        return;
      }

      if (data['error'] != null) {
        _fail('Error: ${data['error']}');
        return;
      }

      final sc = data['serverContent'];
      if (sc is! Map) return;

      // User ne beech me tok diya: Sara turant chup.
      if (sc['interrupted'] == true) {
        _dropAudio = false;
        _listenTimer?.cancel();
        await _flushPlayer();
        _saveTurn();
        onTurnComplete?.call();
        onState?.call(LiveState.listening);
        return;
      }

      final turn = sc['modelTurn'];
      if (turn is Map && turn['parts'] is List) {
        for (final part in turn['parts']) {
          final inline = part['inlineData'];
          if (inline is Map && inline['data'] is String) {
            await _playChunk(base64Decode(inline['data'] as String));
          }
        }
      }

      final it = sc['inputTranscription'];
      if (it is Map && it['text'] is String) {
        _dropAudio = false;
        _uBuf += it['text'] as String;
        onTranscript?.call(it['text'] as String, true);
      }
      final ot = sc['outputTranscription'];
      if (ot is Map && ot['text'] is String) {
        _zBuf += ot['text'] as String;
        onTranscript?.call(ot['text'] as String, false);
      }

      if (sc['turnComplete'] == true) {
        _dropAudio = false;
        _saveTurn();
        onTurnComplete?.call();
        _scheduleListening();
        if (_sleepPending) {
          _sleepPending = false;
          final wait = _speakUntil
              .add(const Duration(milliseconds: 400))
              .difference(DateTime.now());
          Timer(wait.isNegative ? Duration.zero : wait, () => onSleep?.call());
        }
      }
    } catch (e) {
      // Ek kharab message se poora session band nahi karna.
    }
  }

  Future<void> _startMic() async {
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
    ));
    _micSub = stream.listen((Uint8List chunk) {
      if (!_setupDone || !_active) return;
      if (!bargeIn) {
        // Sara bol rahi ho to mic band rakho (apni awaaz na sune).
        final until = _speakUntil.add(const Duration(milliseconds: 700));
        if (DateTime.now().isBefore(until)) return;
      }
      _channel?.sink.add(jsonEncode({
        'realtimeInput': {
          'audio': {
            'data': base64Encode(chunk),
            'mimeType': 'audio/pcm;rate=16000',
          }
        }
      }));
    });
    onState?.call(LiveState.listening);
  }

  Future<void> _playChunk(Uint8List bytes) async {
    final len = bytes.length - (bytes.length % 2);
    if (len <= 0 || _flushing || _dropAudio) return;

    // Is chunk ki awaaz kitni der chalegi (24000 samples/sec * 2 bytes).
    final now = DateTime.now();
    final base = _speakUntil.isAfter(now) ? _speakUntil : now;
    _speakUntil = base.add(Duration(milliseconds: len ~/ 48));

    onState?.call(LiveState.speaking);
    await FlutterPcmSound.feed(
      PcmArrayInt16(bytes: ByteData.sublistView(bytes, 0, len)),
    );
    if (!_playerStarted) {
      _playerStarted = true;
      FlutterPcmSound.start();
    }
  }

  /// Is turn ki baat yaaddaasht me daalo.
  void _saveTurn() {
    final u = _uBuf.trim();
    final z = _zBuf.trim();
    _uBuf = '';
    _zBuf = '';
    if (u.isEmpty && z.isEmpty) return;
    () async {
      if (!await _mem.isOn()) return;
      if (u.isNotEmpty) await _mem.appendRecent(u, true);
      if (z.isNotEmpty) await _mem.appendRecent(z, false);
    }();
  }

  /// Bajti hui awaaz turant band karo.
  Future<void> _flushPlayer() async {
    _flushing = true;
    try {
      await FlutterPcmSound.release();
      await FlutterPcmSound.setup(sampleRate: 24000, channelCount: 1);
    } catch (_) {}
    _playerStarted = false;
    _speakUntil = DateTime.fromMillisecondsSinceEpoch(0);
    _flushing = false;
  }

  /// "Chup karo" button: Sara ki awaaz abhi band.
  Future<void> silence() async {
    _dropAudio = true;
    _listenTimer?.cancel();
    await _flushPlayer();
    onState?.call(LiveState.listening);
  }

  void _scheduleListening() {
    _listenTimer?.cancel();
    final wait = _speakUntil
        .add(const Duration(milliseconds: 300))
        .difference(DateTime.now());
    _listenTimer = Timer(wait.isNegative ? Duration.zero : wait, () {
      if (_active) onState?.call(LiveState.listening);
    });
  }

  void _onClosed() {
    if (!_active) return;
    final reason = _channel?.closeReason;
    final code = _channel?.closeCode;
    _fail('Session band ho gaya'
        '${code != null ? ' (code $code)' : ''}'
        '${reason != null && reason.isNotEmpty ? ': $reason' : ''}');
  }

  Future<void> _fail(String message) async {
    await _teardown();
    onError?.call(message);
  }

  Future<void> stop() async {
    await _teardown();
    onState?.call(LiveState.idle);
  }

  Future<void> _teardown() async {
    _active = false;
    _setupDone = false;
    _listenTimer?.cancel();
    try {
      await _micSub?.cancel();
      _micSub = null;
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
    try {
      await _wsSub?.cancel();
      _wsSub = null;
      await _channel?.sink.close();
      _channel = null;
    } catch (_) {}
    try {
      await FlutterPcmSound.release();
    } catch (_) {}
    try {
      await _pc.keepAliveStop();
    } catch (_) {}
  }
}
