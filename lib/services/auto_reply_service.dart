import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../features/modes/modes.dart';
import 'assistant_service.dart';
import 'memory_service.dart';
import 'settings_service.dart';

/// WhatsApp auto-reply ka asli kaam native (notification listener) karta hai.
/// Ye class use batati hai ki kis andaaz me jawab likhna hai.
class AutoReplyService {
  AutoReplyService._();
  static final instance = AutoReplyService._();

  final _settings = SettingsService();
  bool _inited = false;

  void init() {
    if (_inited) return;
    _inited = true;
    MemoryEvents.tick.addListener(sync);
    sync();
  }

  /// Native code ke padhne ke liye prompt aur model prefs me likh do.
  Future<void> sync() async {
    final prefs = await SharedPreferences.getInstance();
    final owner = await _settings.getAutoOwner();
    final tone = await _settings.getAutoTone();
    var facts = '';
    if (await _settings.getAutoMem()) {
      facts = await MemoryService().promptBlock();
    }
    final persona =
        'Tum $owner ki AI assistant ${AppConstants.appName} ho. $owner abhi '
        'busy hain, isliye tum unki taraf se WhatsApp par jawab de rahi ho. '
        'Andaaz: $tone.\n\n'
        'Niyam: Sirf 1-2 chhote vakya me jawab do, usi bhasha me jisme samne '
        'wala likhe (Hindi, Hinglish ya English). Sirf jawab ka text likho, '
        'koi explanation ya quotes nahi. Kabhi paise, OTP, password, pata '
        '(address) ya koi nijii jaankari mat do, aur $owner ki taraf se koi '
        'pakka vaada ya faisla mat karo. Zaroori ho to bolo "$owner abhi busy '
        'hain, baad me jawab denge". Koi emergency bataye to bolo ki $owner '
        'ko turant call karein.'
        '${facts.isEmpty ? '' : '\n\nJo tumhe $owner ke bare me yaad hai:\n$facts'}';
    await prefs.setString('auto_persona', persona);
    await prefs.setString('auto_model', AssistantService.model);
  }
}
