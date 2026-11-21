import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../services/vision_service.dart';
import '../../widgets/neon.dart';

/// Camera se photo kheencho, Zoya usko dekhkar batati hai.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  static const _defaultQ = 'Is photo me kya hai? Chhote me batao.';

  final _vision = VisionService();
  final _q = TextEditingController();

  List<CameraDescription>? _cameras;
  CameraController? _controller;
  int _index = 0;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  Uint8List? _shot;
  String? _answer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _q.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _controller = null;
      if (mounted) setState(() => _ready = false);
    } else if (state == AppLifecycleState.resumed) {
      _start(_index);
    }
  }

  Future<void> _start(int index) async {
    if (mounted) {
      setState(() {
        _error = null;
        _ready = false;
      });
    }
    try {
      _cameras ??= await availableCameras();
      if (_cameras!.isEmpty) {
        if (mounted) setState(() => _error = 'Is phone me camera nahi mila.');
        return;
      }
      _index = index % _cameras!.length;
      final old = _controller;
      final c = CameraController(
        _cameras![_index],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = c;
      await old?.dispose();
      await c.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code.contains('Denied')
            ? 'Camera ki permission do: Phone Settings → Apps → Zoya → '
                'Permissions → Camera.'
            : 'Camera error: ${e.description ?? e.code}';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera shuru nahi hua: $e');
    }
  }

  Future<void> _snap() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _shot = bytes;
        _answer = null;
      });
      await _ask(_defaultQ);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Photo nahi khichi: ${e.description ?? e.code}';
        });
      }
    }
  }

  Future<void> _ask(String question) async {
    final bytes = _shot;
    if (bytes == null) return;
    setState(() => _busy = true);
    final a = await _vision.ask(bytes, question);
    if (!mounted) return;
    setState(() {
      _answer = a;
      _busy = false;
    });
  }

  void _askCustom() {
    final q = _q.text.trim();
    if (q.isEmpty || _busy) return;
    _q.clear();
    _ask(q);
  }

  void _again() {
    setState(() {
      _shot = null;
      _answer = null;
      _busy = false;
    });
  }

  Widget _previewBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final c = _controller;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: (_ready && c != null && c.value.isInitialized)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / c.value.aspectRatio,
                      child: CameraPreview(c),
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Photo Gemini (Google) ko bheji jaati hai.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FloatingActionButton.large(
              onPressed: _busy ? null : _snap,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(_shot!, height: 260, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              if (_busy) const LinearProgressIndicator(),
              if (_answer != null)
                NeonBorder(
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_answer!),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Ye kya hai?'),
                    onPressed: _busy ? null : () => _ask(_defaultQ),
                  ),
                  ActionChip(
                    label: const Text('Text padho'),
                    onPressed: _busy
                        ? null
                        : () => _ask(
                            'Is photo me jo bhi likha hai, wo padhkar batao.'),
                  ),
                  ActionChip(
                    label: const Text('Samjhao'),
                    onPressed: _busy
                        ? null
                        : () => _ask('Is photo ko aasan bhasha me samjhao.'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askCustom(),
                    decoration: InputDecoration(
                      hintText: 'Is photo ke bare me poochho...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _askCustom,
                  icon: const Icon(Icons.send),
                ),
                IconButton(
                  tooltip: 'Naya photo',
                  onPressed: _again,
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera vision'),
        actions: [
          if (_shot == null && _ready && (_cameras?.length ?? 0) > 1)
            IconButton(
              tooltip: 'Camera badlo',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => _start(_index + 1),
            ),
        ],
      ),
      body: _shot == null ? _previewBody() : _resultBody(),
    );
  }
}
