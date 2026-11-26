import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../services/assistant_service.dart';
import '../../services/memory_service.dart';
import '../../services/settings_service.dart';
import '../modes/modes.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _service = AssistantService();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  AssistantMode _mode = Modes.all.first;

  @override
  void initState() {
    super.initState();
    _loadMode();
    ModeEvents.tick.addListener(_loadMode);
    _loadHistory();
  }

  /// Pichhli baat-cheet wapas dikhao.
  Future<void> _loadHistory() async {
    final mem = MemoryService();
    if (!await mem.isOn()) return;
    final lines = await mem.getRecent();
    if (!mounted || _messages.isNotEmpty) return;
    setState(() {
      _messages.addAll(lines.map((l) => ChatMessage(l.text, l.isUser)));
    });
    _scrollDown();
  }

  Future<void> _remember(String user, String reply) async {
    // "tool chala" wali jaanch line yaaddaasht me mat daalo
    reply = reply.split('\n\n\u{1F527}').first;
    final bad = reply.startsWith('Error:') ||
        reply.startsWith('Internet ya connection') ||
        reply.startsWith('Pehle ') ||
        reply.startsWith('Jawab nahi');
    if (bad) return;
    final mem = MemoryService();
    if (!await mem.isOn()) return;
    await mem.appendRecent(user, true);
    await mem.appendRecent(reply, false);
  }

  Future<void> _loadMode() async {
    final id = await SettingsService().getMode();
    if (!mounted) return;
    setState(() => _mode = Modes.byId(id));
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text, true));
      _loading = true;
    });
    _scrollDown();

    final reply = await _service.reply(_messages);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(reply, false));
      _loading = false;
    });
    _scrollDown();
    _remember(text, reply);
  }

  @override
  void dispose() {
    ModeEvents.tick.removeListener(_loadMode);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_mode.emoji} ${_mode.name}'),
        actions: [
          IconButton(
            tooltip: 'Mode badlo',
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.modes);
              _loadMode();
            },
          ),
          IconButton(
            tooltip: 'Chat saaf karo',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() => _messages.clear());
              MemoryService().clearRecent();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Kuch poocho...'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: m.isUser
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(m.text),
                        ),
                      );
                    },
                  ),
          ),
          if (_loading) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Kuch likho...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
