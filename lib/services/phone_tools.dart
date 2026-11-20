import 'phone_control.dart';

/// Zoya (AI) jo phone-actions kar sakti hai, unki list aur unko chalane ka kaam.
/// Naya action jodna ho to declarations me ek entry aur run me ek case jodo.
class PhoneTools {
  static final _pc = PhoneControl();

  static const prompt =
      'Tumhare paas phone control ke tools hain (app kholna, home, back, '
      'recents, notifications, scroll, tap). Jab user phone par kuch karne '
      'ko kahe to tool use karo aur ek chhoti line me batao ki kya kiya. '
      'Bina kahe koi action mat karo. Paise bhejna, kuch delete karna ya '
      'message bhejna jaise kaam karne se pehle user se ek baar poochh lo.';

  static const declarations = <Map<String, dynamic>>[
    {
      'name': 'open_app',
      'description': 'Phone me koi app kholo (jaise WhatsApp, YouTube).',
      'parameters': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'App ka naam'},
        },
        'required': ['name'],
      },
    },
    {'name': 'go_home', 'description': 'Home screen par jao.'},
    {'name': 'go_back', 'description': 'Back dabao.'},
    {'name': 'open_recents', 'description': 'Recent apps dikhao.'},
    {'name': 'open_notifications', 'description': 'Notification panel kholo.'},
    {
      'name': 'scroll',
      'description': 'Screen ko scroll karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'direction': {'type': 'string', 'description': 'down ya up'},
        },
        'required': ['direction'],
      },
    },
    {
      'name': 'tap_text',
      'description':
          'Screen par jis button ya text par ye likha ho, usko tap karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string', 'description': 'Screen par likha text'},
        },
        'required': ['text'],
      },
    },
  ];

  /// Action chalao aur AI ko chhota sa natija batao.
  static Future<String> run(String name, Map<String, dynamic> args) async {
    if (!await _pc.isEnabled()) {
      return 'Accessibility band hai. User ko batao ki Zoya ke Phone Control '
          'screen se Accessibility me Zoya ko ON kare.';
    }
    bool ok;
    switch (name) {
      case 'open_app':
        ok = await _pc.openApp('${args['name'] ?? ''}');
        break;
      case 'go_home':
        ok = await _pc.home();
        break;
      case 'go_back':
        ok = await _pc.back();
        break;
      case 'open_recents':
        ok = await _pc.recents();
        break;
      case 'open_notifications':
        ok = await _pc.notifications();
        break;
      case 'scroll':
        ok = '${args['direction']}'.toLowerCase() == 'up'
            ? await _pc.scrollUp()
            : await _pc.scrollDown();
        break;
      case 'tap_text':
        ok = await _pc.tapText('${args['text'] ?? ''}');
        break;
      default:
        return 'Ye action maujood nahi hai.';
    }
    return ok ? 'ho gaya' : 'nahi ho paya';
  }
}
