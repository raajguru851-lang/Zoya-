import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/live_service.dart';

enum HairStyle { pigtails, buns }

/// Ek cute doll ka design. Naya doll jodna ho to Dolls.all me ek entry badhao.
class DollDesign {
  final String name;
  final List<Color> skin; // [chamak, mukhya, parchhai]
  final List<Color> hair; // [halka, mukhya, gehra]
  final List<Color> dress; // [halka, mukhya, gehra]
  final List<Color> accent; // [halka, mukhya] (ribbon, joote)
  final List<Color> iris; // [neeche ka halka, upar ka mukhya]
  final Color blush;
  final HairStyle hairStyle;

  const DollDesign({
    required this.name,
    required this.skin,
    required this.hair,
    required this.dress,
    required this.accent,
    required this.iris,
    required this.blush,
    this.hairStyle = HairStyle.pigtails,
  });
}

class Dolls {
  static const all = <DollDesign>[
    // Prompt 1: bade expressive aankhein, pyaari muskaan, soft 3D cartoon,
    // bright pastel colours.
    DollDesign(
      name: 'Pastel Candy',
      skin: [Color(0xFFFFEDE0), Color(0xFFFFD2B3), Color(0xFFF0A98C)],
      hair: [Color(0xFFEFE2FF), Color(0xFFBDA5F7), Color(0xFF8E72D8)],
      dress: [Color(0xFFFFE0EE), Color(0xFFFFADCF), Color(0xFFFF80B2)],
      accent: [Color(0xFFD2FFEE), Color(0xFF7FE9C2)],
      iris: [Color(0xFF9BDCFF), Color(0xFF3B8FE0)],
      blush: Color(0xFFFF8FB1),
      hairStyle: HairStyle.pigtails,
    ),
  ];

  static DollDesign at(int i) => all[i.clamp(0, all.length - 1)];
}

class DollPainter extends CustomPainter {
  final DollDesign d;
  final double blink; // 0 khuli, 1 band
  final double mouth; // 0 band, 1 poora khula
  final double bob; // upar-neeche (px)
  final double tilt; // halka jhukav (radian)

  DollPainter(
    this.d, {
    this.blink = 0,
    this.mouth = 0,
    this.bob = 0,
    this.tilt = 0,
  });

  Paint _fill(Color c) => Paint()..color = c;

  Paint _hairPaint(Rect r) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: d.hair,
    ).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 260);

    // zameen par parchhai
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 250), width: 110, height: 16),
      Paint()
        ..color = Colors.black.withAlpha(70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.save();
    canvas.translate(100, 130 + bob);
    canvas.rotate(tilt);
    canvas.translate(-100, -130);

    _backHair(canvas);
    _body(canvas);
    _head(canvas);
    _face(canvas);
    _frontHair(canvas);
    _bow(canvas);

    canvas.restore();
    canvas.restore();
  }

  void _backHair(Canvas canvas) {
    final hp = _hairPaint(const Rect.fromLTWH(30, 30, 140, 140));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 100), width: 144, height: 140),
      hp,
    );
    if (d.hairStyle == HairStyle.pigtails) {
      canvas.drawCircle(const Offset(34, 134), 24, hp);
      canvas.drawCircle(const Offset(166, 134), 24, hp);
    } else {
      canvas.drawCircle(const Offset(50, 42), 22, hp);
      canvas.drawCircle(const Offset(150, 42), 22, hp);
    }
  }

  void _body(Canvas canvas) {
    final skin = _fill(d.skin[1]);

    // taangein aur joote
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(82, 228), width: 18, height: 30),
          const Radius.circular(9)),
      skin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(118, 228), width: 18, height: 30),
          const Radius.circular(9)),
      skin,
    );
    final shoe = _fill(d.accent[1]);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(80, 245), width: 28, height: 15),
        shoe);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(120, 245), width: 28, height: 15),
        shoe);

    // baanhein
    final arm = Paint()
      ..color = d.skin[1]
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(68, 178), const Offset(46, 204), arm);
    canvas.drawLine(const Offset(132, 178), const Offset(154, 204), arm);
    canvas.drawCircle(const Offset(44, 208), 8, skin);
    canvas.drawCircle(const Offset(156, 208), 8, skin);

    // frock
    final dress = Path()
      ..moveTo(70, 168)
      ..lineTo(130, 168)
      ..quadraticBezierTo(150, 196, 156, 226)
      ..quadraticBezierTo(100, 240, 44, 226)
      ..quadraticBezierTo(50, 196, 70, 168)
      ..close();
    canvas.drawPath(
      dress,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: d.dress,
        ).createShader(const Rect.fromLTWH(44, 168, 112, 72)),
    );
    // kinare ki jhaalar
    final ruffle = _fill(d.dress[0].withAlpha(235));
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(Offset(52 + i * 16.0, 230), 9, ruffle);
    }
    // baanh ke phoole hue sleeves
    final sleeve = _fill(d.dress[1]);
    canvas.drawCircle(const Offset(68, 176), 13, sleeve);
    canvas.drawCircle(const Offset(132, 176), 13, sleeve);
    // belt
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(72, 184, 128, 192),
          const Radius.circular(4)),
      _fill(d.accent[1]),
    );
    // chamak
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(86, 204), width: 18, height: 30),
      Paint()..color = Colors.white.withAlpha(55),
    );
  }

  void _head(Canvas canvas) {
    final rect =
        Rect.fromCenter(center: const Offset(100, 104), width: 128, height: 118);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.0,
          colors: d.skin,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
  }

  void _face(Canvas canvas) {
    // gaalon ki laali
    final blush = Paint()
      ..color = d.blush.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(60, 132), width: 26, height: 15),
        blush);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(140, 132), width: 26, height: 15),
        blush);

    _eye(canvas, const Offset(74, 118));
    _eye(canvas, const Offset(126, 118));

    // bhauein
    final brow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = d.hair[2].withAlpha(210);
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(74, 94), width: 24, height: 10),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        brow);
    canvas.drawArc(
        Rect.fromCenter(center: const Offset(126, 94), width: 24, height: 10),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        brow);

    // naak
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 134), width: 6, height: 4),
      Paint()..color = d.skin[2].withAlpha(170),
    );

    _mouth(canvas);
  }

  void _eye(Canvas canvas, Offset c) {
    final ry = 20.0 * (1 - 0.92 * blink);
    const rx = 15.0;
    final eye = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);

    canvas.drawOval(
      eye,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF2B1B3A), d.iris[1], d.iris[0]],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(eye),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, 2), width: 14, height: math.max(1, ry * 1.1)),
      _fill(const Color(0xFF1A1026)),
    );
    if (blink < 0.5) {
      canvas.drawCircle(c.translate(-5, -ry * 0.4), 5, _fill(Colors.white));
      canvas.drawCircle(
          c.translate(5, ry * 0.35), 2.6, _fill(Colors.white.withAlpha(210)));
    }
    // palak ki line
    canvas.drawArc(
      eye.inflate(1),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A2748),
    );
  }

  void _mouth(Canvas canvas) {
    if (mouth > 0.08) {
      final h = 4 + 14 * mouth;
      final r = Rect.fromCenter(center: const Offset(100, 147), width: 20, height: h);
      canvas.drawOval(r, _fill(const Color(0xFF9E2B4F)));
      canvas.save();
      canvas.clipPath(Path()..addOval(r));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(100, 147 + h * 0.3), width: 12, height: h * 0.55),
        _fill(const Color(0xFFFF8FA8)),
      );
      canvas.restore();
    } else {
      final p = Path()
        ..moveTo(90, 143)
        ..quadraticBezierTo(100, 153, 110, 143);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFC2547A),
      );
    }
  }

  void _frontHair(Canvas canvas) {
    final hp = _hairPaint(const Rect.fromLTWH(30, 36, 140, 60));
    // upar ki topi
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 62), width: 132, height: 52),
      hp,
    );
    // bangs
    for (final c in const [Offset(66, 74), Offset(100, 71), Offset(134, 74)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 48, height: 34), hp);
    }
    // chehre ke kinare ki lataein
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(42, 112), width: 18, height: 52), hp);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(158, 112), width: 18, height: 52),
        hp);
    // chamak
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(100, 58), width: 100, height: 34),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withAlpha(110),
    );
  }

  void _bow(Canvas canvas) {
    final pos = d.hairStyle == HairStyle.pigtails
        ? const Offset(142, 50)
        : const Offset(100, 32);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(0.35);
    final wing = Paint()
      ..shader = LinearGradient(colors: d.accent)
          .createShader(const Rect.fromLTWH(-30, -14, 60, 28));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-15, 0), width: 28, height: 24),
        wing);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(15, 0), width: 28, height: 24),
        wing);
    canvas.drawCircle(Offset.zero, 7, _fill(d.accent[1]));
    canvas.drawCircle(
        const Offset(-1, -2), 2.5, _fill(Colors.white.withAlpha(170)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(DollPainter old) =>
      old.blink != blink ||
      old.mouth != mouth ||
      old.bob != bob ||
      old.tilt != tilt ||
      old.d != d;
}

/// Sthir (na hilne wali) doll, gallery me dikhane ke liye.
class DollPreview extends StatelessWidget {
  final DollDesign design;
  final double height;

  const DollPreview({super.key, required this.design, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 200 / 260,
      height: height,
      child: CustomPaint(painter: DollPainter(design)),
    );
  }
}

/// Chalti hui doll: palak jhapakti hai, bolte waqt munh hilta hai,
/// sunte waqt halka sa jhoomti hai.
class ZoyaDoll extends StatefulWidget {
  final LiveState state;
  final DollDesign design;
  final double height;

  const ZoyaDoll({
    super.key,
    required this.state,
    required this.design,
    this.height = 200,
  });

  @override
  State<ZoyaDoll> createState() => _ZoyaDollState();
}

class _ZoyaDollState extends State<ZoyaDoll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _blinkAt(double t, double center) {
    final d = (t - center).abs();
    return d < 0.03 ? 1 - d / 0.03 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final blink = math.max(_blinkAt(t, 0.45), _blinkAt(t, 0.85));
        final bob = math.sin(t * 2 * math.pi * 2) * 3;
        final speaking = widget.state == LiveState.speaking;
        final mouth = speaking
            ? ((math.sin(t * 2 * math.pi * 7) + math.sin(t * 2 * math.pi * 11)) /
                        4 +
                    0.5)
                .clamp(0.0, 1.0)
            : 0.0;
        final tilt = widget.state == LiveState.listening
            ? math.sin(t * 2 * math.pi * 2) * 0.04
            : 0.0;

        return SizedBox(
          width: widget.height * 200 / 260,
          height: widget.height,
          child: CustomPaint(
            painter: DollPainter(
              widget.design,
              blink: blink,
              mouth: mouth,
              bob: bob,
              tilt: tilt,
            ),
          ),
        );
      },
    );
  }
}
