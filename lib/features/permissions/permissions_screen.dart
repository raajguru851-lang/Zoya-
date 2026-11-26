import 'package:flutter/material.dart';
import '../../services/phone_control.dart';
import '../../widgets/neon.dart';

/// Sara ko jo permissions chahiye, sab ek jagah.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final _pc = PhoneControl();
  bool _acc = false;
  bool _mic = false;
  bool _cam = false;
  bool _notif = false;
  bool _battery = false;
  bool _call = false;
  bool _contacts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final r = await Future.wait([
      _pc.isEnabled(),
      _pc.hasMic(),
      _pc.hasCamera(),
      _pc.hasNotif(),
      _pc.hasBattery(),
      _pc.hasCall(),
      _pc.hasContacts(),
    ]);
    if (!mounted) return;
    setState(() {
      _acc = r[0];
      _mic = r[1];
      _cam = r[2];
      _notif = r[3];
      _battery = r[4];
      _call = r[5];
      _contacts = r[6];
    });
  }

  Future<void> _askAll() async {
    await _pc.requestAll();
    // popup band hone ke baad status dobara dekho
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    _refresh();
  }

  Widget _perm(IconData icon, String title, String why, bool ok,
      VoidCallback fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: NeonColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: ok
                ? Colors.greenAccent.withAlpha(150)
                : NeonColors.purple.withAlpha(120),
            width: 1.3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(icon, color: NeonColors.cyan, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(why,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
              if (ok)
                const Icon(Icons.check_circle, color: Colors.greenAccent)
              else
                FilledButton.tonal(
                  onPressed: fix,
                  child: const Text('ON karo'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done =
        [_acc, _mic, _cam, _notif, _battery, _call, _contacts]
            .where((e) => e)
            .length;
    return Scaffold(
      appBar: AppBar(title: const Text('App permissions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          NeonBorder(
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done == 7 ? 'Sab taiyar hai' : '$done / 7 taiyar',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: done / 7),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _perm(Icons.accessibility_new, 'Accessibility',
              'Phone control, app kholna, rangeen light', _acc,
              _pc.openAccessibilitySettings),
          _perm(Icons.mic_none, 'Microphone', 'Voice me bolne ke liye', _mic,
              _askAll),
          _perm(Icons.photo_camera_outlined, 'Camera',
              'Camera vision ke liye', _cam, _askAll),
          _perm(Icons.notifications_none, 'Notifications',
              'Background me Sara ki notification', _notif, _askAll),
          _perm(Icons.call_outlined, 'Phone calls',
              'Call lagana aur uthana', _call, _askAll),
          _perm(Icons.contacts_outlined, 'Contacts',
              'Naam se call aur message ke liye', _contacts, _askAll),
          _perm(Icons.battery_charging_full, 'Battery: unrestricted',
              'Background me Android band na kare', _battery,
              _pc.openBattery),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _askAll,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Mic, Camera, Calls, Contacts, Notification ek saath maango'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pc.openAppSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Sara ki App settings kholo'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Agar popup na aaye, to App settings → Permissions me jaakar '
              'haath se allow karo. Battery me Sara ko "Unrestricted" chuno.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}
