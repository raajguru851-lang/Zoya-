import 'package:flutter/material.dart';
import '../../services/live_service.dart';
import '../../services/phone_control.dart';
import '../../services/settings_service.dart';
import '../../widgets/zoya_orb.dart';
import '../modes/modes.dart';

class _Line {
  final String text;
  final bool isUser;
  _Line(this.text, this.isUser);
}

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final _live = LiveService();
  LiveState _state = LiveState.idle;
  AssistantMode _mode = Modes.all.first;
  String? _error;
  bool _barge = false;
  String _userBuf = '';
  String _zoyaBuf = '';
  final List<_Line> _lines = [];

  @override
  void initState() {
    super.initState();
    SettingsService().getMode().then((id) {
      if (mounted) setState(() => _mode = Modes.byId(id));
    });

    _live.onState = (s) {
      if (mounted) setState(() => _state = s);
    };
    _live.onTranscript = (text, isUser) {
      if (!mounted) return;
      setState(() {
        if (isUser) {
          _userBuf += text;
        } else {
          _zoyaBuf += text;
        }
      });
    };
    _live.onTurnComplete = () {
      if (!mounted) return;
      setState(() {
        if (_userBuf.trim().isNotEmpty) _lines.add(_Line(_userBuf.trim(), true));
        if (_zoyaBuf.trim().isNotEmpty) _lines.add(_Line(_zoyaBuf.trim(), false));
        _userBuf = '';
        _zoyaBuf = '';
      });
    };
    _live.onError = (msg) {
      if (!mounted) return;
      setState(() {
        _error = msg;
        _state = LiveState.idle;
      });
    };
  }

  @override
  void dispose() {
    _live.onState = null;
    _live.onTranscript = null;
    _live.onTurnComplete = null;
    _live.onError = null;
    _live.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == LiveState.idle) {
      // Earphones lage hain to beech me tokna ON, speaker me OFF.
      final hp = await PhoneControl().hasHeadphones();
      _live.bargeIn = hp;
      setState(() {
        _error = null;
        _barge = hp;
      });
      await _live.start();
    } else {
      await _live.stop();
    }
  }

  String get _statusText {
    switch (_state) {
      case LiveState.idle:
        return 'Mic dabao aur bolo';
      case LiveState.connecting:
        return 'Connect ho raha hai...';
      case LiveState.listening:
        return 'Sun rahi hoon... bolo';
      case LiveState.speaking:
        return 'Zoya bol rahi hai...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _state != LiveState.idle;
    final all = [
      ..._lines,
      if (_userBuf.trim().isNotEmpty) _Line(_userBuf.trim(), true),
      if (_zoyaBuf.trim().isNotEmpty) _Line(_zoyaBuf.trim(), false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_mode.emoji} Voice • ${LiveService.voiceName}'),
        actions: [
          IconButton(
            tooltip: _barge ? 'Beech me tokna: ON' : 'Beech me tokna: OFF',
            icon: Icon(
                _barge ? Icons.record_voice_over : Icons.voice_over_off),
            onPressed: () => setState(() {
              _barge = !_barge;
              _live.bargeIn = _barge;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ZoyaOrb(state: _state),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_statusText,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_state == LiveState.speaking)
            TextButton.icon(
              onPressed: _live.silence,
              icon: const Icon(Icons.volume_off),
              label: const Text('Chup karo'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: all.length,
              itemBuilder: (_, i) {
                final l = all[i];
                return Align(
                  alignment:
                      l.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: l.isUser
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(l.text),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Speaker me Zoya bolte waqt sunti nahi. Earphones lagao to beech me tok sakte ho.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton.large(
                onPressed: _toggle,
                child: Icon(active ? Icons.stop : Icons.mic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
