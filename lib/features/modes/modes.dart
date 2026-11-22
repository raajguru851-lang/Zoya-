import 'package:flutter/foundation.dart';

/// Sara ke saare modes yahan hain.
/// Naya mode add karna ho to list me ek AssistantMode jod do.
class AssistantMode {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String prompt;

  const AssistantMode({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.prompt,
  });
}

/// Mode badalne par screens ko khabar dene ke liye.
class ModeEvents {
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
}

class Modes {
  static const all = <AssistantMode>[
    AssistantMode(
      id: 'bestfriend',
      name: 'Best Friend',
      emoji: '🤝',
      description: 'Dost jaisi, mazaakiya aur sachchi baat',
      prompt: 'Tum user ki best friend ho. Bilkul dost ki tarah casual '
          'Hinglish me baat karo, thoda mazaak karo, sachchi aur seedhi '
          'salah do, aur zarurat par support karo.',
    ),
    AssistantMode(
      id: 'gf',
      name: 'GF Mode',
      emoji: '💖',
      description: 'Pyaari, caring aur pyar bhari baatein',
      prompt: 'Tum user ki pyaari, caring girlfriend ho. Meethi, apnepan '
          'wali Hinglish me baat karo, user ka khayal rakho, uska din '
          'poochho, thoda cute nakhre dikhao. Baatein pyaari aur saaf-suthri '
          'rakho.',
    ),
    AssistantMode(
      id: 'professional',
      name: 'Professional',
      emoji: '💼',
      description: 'Seedha, saaf aur kaam ki baat',
      prompt: 'Tum ek professional assistant ho. Seedhe, saaf aur '
          'sabhya andaaz me chhote jawab do. Faltu baatein mat karo.',
    ),
    AssistantMode(
      id: 'funny',
      name: 'Funny',
      emoji: '😂',
      description: 'Har baat me hansi-mazaak',
      prompt: 'Tum bahut mazaakiya ho. Jawab me halka-fulka humor aur '
          'jokes daalo, par kaam ki baat bhi batao.',
    ),
    AssistantMode(
      id: 'motivator',
      name: 'Motivator',
      emoji: '🔥',
      description: 'Himmat badhane wala, thoda strict',
      prompt: 'Tum ek motivator ho. User ko josh dilao, aalas par pyaar se '
          'daant lagao, aur chhote-chhote action steps batao.',
    ),
    AssistantMode(
      id: 'teacher',
      name: 'Teacher',
      emoji: '📚',
      description: 'Aasan bhasha me samjhane wali',
      prompt: 'Tum ek achhi teacher ho. Har cheez bahut aasan Hinglish me, '
          'chhote steps aur example ke saath samjhao.',
    ),
  ];

  static AssistantMode byId(String? id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);

  /// "gf", "best friend", "teacher" jaise shabdon se mode dhoondho.
  static AssistantMode? resolve(String q) {
    final t = q.toLowerCase().replaceAll(RegExp(r'[_\-]'), ' ');
    bool has(List<String> k) => k.any(t.contains);
    String? id;
    if (has(['best friend', 'bestfriend', 'dost', 'bff'])) {
      id = 'bestfriend';
    } else if (has(['gf', 'girlfriend', 'girl friend'])) {
      id = 'gf';
    } else if (has(['professional', 'formal', 'office'])) {
      id = 'professional';
    } else if (has(['funny', 'mazak', 'mazaak', 'comedy', 'joke'])) {
      id = 'funny';
    } else if (has(['motivat', 'josh'])) {
      id = 'motivator';
    } else if (has(['teacher', 'padhai', 'study', 'tutor'])) {
      id = 'teacher';
    }
    if (id == null) return null;
    return all.firstWhere((m) => m.id == id);
  }

  /// "gf mode lagao" jaisa seedha hukm ho to uska mode, warna null.
  static AssistantMode? parseCommand(String text) {
    final t = text.toLowerCase();
    if (!t.contains('mode')) return null;
    if (t.contains('?') || t.contains('kya ') || t.contains('kaun')) return null;
    final verb = RegExp(
        r'\b(lagao|laga|on|active|chalu|kro|karo|kar do|kardo|set|switch|badlo|change|shuru|start)\b');
    if (!verb.hasMatch(t)) return null;
    return resolve(t);
  }
}
