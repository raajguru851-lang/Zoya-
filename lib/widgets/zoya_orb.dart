import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/live_service.dart';
import 'neon.dart';

/// Gola ka ek design: [chamak, mukhya rang, gehra rang].
class OrbDesign {
  final String name;
  final List<Color> colors;
  const OrbDesign(this.name, this.colors);
}

class OrbDesigns {
  static const all = <OrbDesign>[
    OrbDesign('Siri Original',
        [Color(0xFFB39DFF), Color(0xFF5B6CFF), Color(0xFFFF6FB5)]),
    OrbDesign('Ocean Blue',
        [Color(0xFF7DF9FF), Color(0xFF1E88E5), Color(0xFF00BFA5)]),
    OrbDesign('Neon Pink',
        [Color(0xFFFF9BEA), Color(0xFFFF2BD6), Color(0xFF7B1FA2)]),
    OrbDesign('Emerald',
        [Color(0xFFC6FF00), Color(0xFF00E676), Color(0xFF006064)]),
    OrbDesign('Sunset',
        [Color(0xFFFFE082), Color(0xFFFF7043), Color(0xFFD81B60)]),
    OrbDesign('Violet',
        [Color(0xFFE1BEE7), Color(0xFF8E24AA), Color(0xFF311B92)]),
    OrbDesign('Aurora',
        [Color(0xFF69F0AE), Color(0xFF40C4FF), Color(0xFFAA00FF)]),
    OrbDesign('Gold',
        [Color(0xFFFFF8E1), Color(0xFFFFC107), Color(0xFFE65100)]),
    OrbDesign('Ruby',
        [Color(0xFFFF8A80), Color(0xFFE53935), Color(0xFF4A0000)]),
    OrbDesign('Ice',
        [Color(0xFFFFFFFF), Color(0xFF80DEEA), Color(0xFF3949AB)]),
  ];

  static OrbDesign at(int i) => all[i.clamp(0, all.length - 1)];
}

/// Ek sthir (na hilne wala) chamakta gola.
class OrbBall extends StatelessWidget {
  final OrbDesign design;
  final double size;
  final double glow;

  const OrbBall({
    super.key,
    required this.design,
    this.size = 72,
    this.glow = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = design.colors;
    final shadowAlpha = (150 * glow).round().clamp(0, 255);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [Colors.white.withAlpha(235), c[0], c[1], c[2]],
          stops: const [0.0, 0.22, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: c[1].withAlpha(shadowAlpha),
            blurRadius: size * 0.25,
            spreadRadius: size * 0.03,
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [c[2].withAlpha(130), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

/// Voice screen ka chalta hua gola. Halat ke hisaab se dhadkan badalti hai.
class ZoyaOrb extends StatefulWidget {
  final LiveState state;
  final OrbDesign design;
  final double size;

  const ZoyaOrb({
    super.key,
    required this.state,
    required this.design,
    this.size = 150,
  });

  @override
  State<ZoyaOrb> createState() => _ZoyaOrbState();
}

class _ZoyaOrbState extends State<ZoyaOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        double speed;
        double amp;
        switch (widget.state) {
          case LiveState.idle:
            speed = 1;
            amp = 0.015;
            break;
          case LiveState.connecting:
            speed = 2;
            amp = 0.03;
            break;
          case LiveState.listening:
            speed = 1;
            amp = 0.04;
            break;
          case LiveState.speaking:
            speed = 3;
            amp = 0.07;
            break;
        }
        final pulse = 1 + amp * math.sin(_c.value * 2 * math.pi * speed);
        final glow = widget.state == LiveState.idle ? 0.5 : 1.0;

        return SizedBox(
          width: s * 1.3,
          height: s * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _c.value * 2 * math.pi,
                child: Container(
                  width: s * 1.22,
                  height: s * 1.22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: NeonColors.ring),
                  ),
                ),
              ),
              Container(
                width: s * 1.14,
                height: s * 1.14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonColors.bg,
                ),
              ),
              Transform.scale(
                scale: pulse,
                child: OrbBall(design: widget.design, size: s, glow: glow),
              ),
            ],
          ),
        );
      },
    );
  }
}
