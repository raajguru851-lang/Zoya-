import '../features/modes/modes.dart';
import 'memory_service.dart';
import 'phone_control.dart';
import 'settings_service.dart';

/// Sara (AI) jo phone-actions kar sakti hai, unki list aur unko chalane ka kaam.
/// Naya action jodna ho to declarations me ek entry aur run me ek case jodo.
class PhoneTools {
  static final _pc = PhoneControl();
  static final _settings = SettingsService();

  static const prompt =
      'Tumhare paas phone control ke tools hain (app kholna, home, back, '
      'recents, notifications, scroll, tap). Jab user phone par kuch karne '
      'ko kahe to tool use karo aur ek chhoti line me batao ki kya kiya. '
      'Bina kahe koi action mat karo. Paise bhejna, kuch delete karna ya '
      'message bhejna jaise kaam karne se pehle user se ek baar poochh lo.\n\n'
      'Tum ek "manager" ki tarah bhi kaam karti ho: user kabhi bhi mode '
      'badalne ko kahe (jaise "gf mode lagao", "best friend mode on karo", '
      '"ab professional ban jao") to abhi kaunsa bhi mode chal raha ho, '
      'turant set_mode tool call karo. Uske baad pehle seedhe, professional '
      'andaaz me bolo: "<mode> active kar diya hai. Ab sirf <mode> bolegi." '
      'Phir naye mode ke andaaz me baat karo aur purane mode ka andaaz poori '
      'tarah chhod do. Tool ke jawab me naye mode ke jo niyam aayein, unhi se '
      'baat karo. Koi poochhe ki abhi kaunsa mode hai to get_mode call karo.\n\n'
      'Yaaddaasht: jab user apne bare me koi zaroori, der tak kaam aane wali '
      'baat bataye (naam, pasand, birthday, kaam, rishte, aadat) ya "yaad '
      'rakhna" kahe, to remember tool se ek chhote vakya me save karo. '
      '"Bhool jao" kahe to forget call karo. Password, card number, OTP '
      'jaisi sensitive cheezein kabhi yaad mat rakho. Jo yaad hai uska '
      'istemal natural tareeke se karo, har baar mat dohrao.\n\n'
      'Aur tools: set_alarm (agle 24 ghante ke andar ka alarm/reminder), '
      'set_timer, flashlight, set_volume, dial_number (sirf dialer kholta '
      'hai), whatsapp_message (message likhkar WhatsApp kholta hai, bhejna '
      'user ko hai), web_search, open_link, battery_status, current_time. '
      'Call ya message ke liye poora number chahiye (country code ke saath); '
      'number na ho to user se poochho. Bhejne se pehle user se confirm karo.\n\n'
      'Phone khud chalana: make_call (call lagana, pehle user se confirm '
      'karo), answer_call (aati call uthana), end_call (call kaatna), '
      'play_music (gaana chalana), media_control (play/pause/next/previous), '
      'read_screen (screen par kya dikh raha hai), tap_text, tap_xy, '
      'type_text, submit_text. Kaam kai kadam me karo: pehle app kholo ya '
      'play_music, phir read_screen se dekho, phir tap/type karo, aur har '
      'kadam ke baad read_screen se pakka karo ki sahi hua. Paise, UPI, '
      'bank ya password wali screen par kuch mat karo. Kuch samajh na aaye '
      'to user se poochho.';

  static const declarations = <Map<String, dynamic>>[
    {
      'name': 'set_mode',
      'description': 'Sara ka mode badlo (gf, bestfriend, professional, '
          'funny, motivator, teacher).',
      'parameters': {
        'type': 'object',
        'properties': {
          'mode': {
            'type': 'string',
            'enum': [
              'gf',
              'bestfriend',
              'professional',
              'funny',
              'motivator',
              'teacher'
            ],
            'description':
                'gf = GF Mode, bestfriend = Best Friend Mode, professional, '
                    'funny, motivator, teacher',
          },
        },
        'required': ['mode'],
      },
    },
    {'name': 'get_mode', 'description': 'Abhi kaunsa mode chal raha hai.'},
    {
      'name': 'set_alarm',
      'description': 'Alarm ya reminder lagao (agle 24 ghante ke andar ka).',
      'parameters': {
        'type': 'object',
        'properties': {
          'hour': {'type': 'integer', 'description': '24 ghante wala ghanta, 0-23'},
          'minute': {'type': 'integer', 'description': 'minute, 0-59'},
          'label': {'type': 'string', 'description': 'Alarm ka naam ya reminder'},
        },
        'required': ['hour', 'minute'],
      },
    },
    {
      'name': 'set_timer',
      'description': 'Countdown timer lagao.',
      'parameters': {
        'type': 'object',
        'properties': {
          'seconds': {'type': 'integer', 'description': 'Kitne second ka'},
          'label': {'type': 'string', 'description': 'Timer ka naam'},
        },
        'required': ['seconds'],
      },
    },
    {
      'name': 'flashlight',
      'description': 'Flashlight (torch) on ya off karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'on': {'type': 'boolean', 'description': 'true = on, false = off'},
        },
        'required': ['on'],
      },
    },
    {
      'name': 'set_volume',
      'description': 'Media volume badlo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['up', 'down', 'mute', 'set'],
            'description': 'up/down/mute, ya set (percent ke saath)',
          },
          'percent': {'type': 'integer', 'description': 'set ke liye 0-100'},
        },
        'required': ['action'],
      },
    },
    {
      'name': 'dial_number',
      'description': 'Dialer me number likhkar kholo. Call user khud dabayega.',
      'parameters': {
        'type': 'object',
        'properties': {
          'number': {'type': 'string', 'description': 'Phone number'},
        },
        'required': ['number'],
      },
    },
    {
      'name': 'whatsapp_message',
      'description':
          'WhatsApp me message likhkar kholo. Bhejna user khud dabayega.',
      'parameters': {
        'type': 'object',
        'properties': {
          'phone': {
            'type': 'string',
            'description': 'Country code ke saath number, jaise 919876543210',
          },
          'text': {'type': 'string', 'description': 'Message ka text'},
        },
        'required': ['phone', 'text'],
      },
    },
    {
      'name': 'web_search',
      'description': 'Google par kuch search karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Kya search karna hai'},
        },
        'required': ['query'],
      },
    },
    {
      'name': 'open_link',
      'description': 'Koi website ya link kholo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'url': {'type': 'string', 'description': 'Link'},
        },
        'required': ['url'],
      },
    },
    {
      'name': 'make_call',
      'description': 'Number par seedha call lagao. Pehle user se confirm karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'number': {'type': 'string', 'description': 'Phone number'},
        },
        'required': ['number'],
      },
    },
    {'name': 'answer_call', 'description': 'Aati hui call uthao.'},
    {'name': 'end_call', 'description': 'Chalti hui call kaato.'},
    {
      'name': 'play_music',
      'description': 'Gaana chalane ke liye music app me search karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Gaane ya artist ka naam'},
        },
        'required': ['query'],
      },
    },
    {
      'name': 'media_control',
      'description': 'Chalta hua gaana play/pause/next/previous karo.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['play_pause', 'next', 'previous', 'stop'],
          },
        },
        'required': ['action'],
      },
    },
    {
      'name': 'read_screen',
      'description':
          'Screen par abhi kya dikh raha hai uski list (text, kya tap ho '
          'sakta hai, aur jagah x,y).',
    },
    {
      'name': 'tap_xy',
      'description': 'Screen par x, y jagah tap karo (read_screen se jagah lo).',
      'parameters': {
        'type': 'object',
        'properties': {
          'x': {'type': 'integer'},
          'y': {'type': 'integer'},
        },
        'required': ['x', 'y'],
      },
    },
    {
      'name': 'type_text',
      'description': 'Text box me text likho.',
      'parameters': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
        },
        'required': ['text'],
      },
    },
    {
      'name': 'submit_text',
      'description': 'Text box me Enter / Search dabao.',
    },
    {'name': 'battery_status', 'description': 'Battery kitni hai aur charge ho rahi hai ya nahi.'},
    {'name': 'current_time', 'description': 'Abhi ka samay aur tarikh.'},
    {
      'name': 'remember',
      'description': 'User ke bare me ek zaroori baat yaad rakho.',
      'parameters': {
        'type': 'object',
        'properties': {
          'fact': {
            'type': 'string',
            'description': 'Ek chhota vakya, jaise "User ka naam Rahul hai".',
          },
        },
        'required': ['fact'],
      },
    },
    {
      'name': 'forget',
      'description': 'Koi yaad bhool jao.',
      'parameters': {
        'type': 'object',
        'properties': {
          'about': {
            'type': 'string',
            'description': 'Us yaad ka koi ek shabd.',
          },
        },
        'required': ['about'],
      },
    },
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
    if (name == 'set_mode') return _setMode('${args['mode'] ?? ''}');
    if (name == 'current_time') {
      final t = DateTime.now();
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
        'Sunday'
      ];
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ];
      final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final ap = t.hour < 12 ? 'AM' : 'PM';
      final mm = t.minute.toString().padLeft(2, '0');
      return 'Abhi $h12:$mm $ap hai, ${days[t.weekday - 1]} '
          '${t.day} ${months[t.month - 1]} ${t.year}.';
    }
    const nativeTools = {
      'set_alarm',
      'set_timer',
      'flashlight',
      'set_volume',
      'dial_number',
      'whatsapp_message',
      'web_search',
      'open_link',
      'battery_status',
      'make_call',
      'answer_call',
      'end_call',
      'play_music',
      'media_control',
      'read_screen',
      'tap_xy',
      'type_text',
      'submit_text',
    };
    if (nativeTools.contains(name)) return _pc.tool(name, args);
    if (name == 'remember') {
      final ok = await MemoryService().addFact('${args['fact'] ?? ''}');
      return ok ? 'yaad kar liya' : 'ye pehle se yaad hai';
    }
    if (name == 'forget') {
      final n = await MemoryService().forgetMatching('${args['about'] ?? ''}');
      return n > 0 ? '$n yaad bhool gayi' : 'aisa kuch yaad nahi tha';
    }
    if (name == 'get_mode') {
      final m = Modes.byId(await _settings.getMode());
      return 'Abhi ${m.name} chal raha hai.';
    }
    if (!await _pc.isEnabled()) {
      return 'Accessibility band hai. User ko batao ki Sara ke Phone Control '
          'screen se Accessibility me Sara ko ON kare.';
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

  static Future<String> _setMode(String q) async {
    final m = Modes.resolve(q);
    if (m == null) {
      return 'Ye mode nahi mila. Available modes: '
          '${Modes.all.map((e) => e.name).join(', ')}.';
    }
    await _settings.setMode(m.id);
    ModeEvents.tick.value++;
    final short = m.name.replaceAll(' Mode', '');
    return 'Mode badal gaya: ${m.name}. Pehle seedhe, professional andaaz me '
        'bolo: "${m.name} active kar diya hai. Ab sirf $short bolegi." '
        'Uske baad sirf is naye mode ke niyam se baat karo (purana mode bhool '
        'jao): ${m.prompt}';
  }
}
