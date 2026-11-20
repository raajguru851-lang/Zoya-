import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/live_service.dart';
import 'neon.dart';

/// Voice screen ka 3D chamakta gola. Halat ke hisaab se rang aur dhadkan badalti hai.
class ZoyaOrb extends StatefulWidget {
  final LiveState state;
  final double size;

  const ZoyaOrb({super.key, required this.state, this.size = 150});

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

  Color get _color {
    switch (widget.state) {
      case LiveState.idle:
        return NeonColors.purple;
      case LiveState.connecting:
        return const Color(0xFFFFC400);
      case LiveState.listening:
        return NeonColors.cyan;
      case LiveState.speaking:
        return NeonColors.magenta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final speed = widget.state == LiveState.speaking ? 3.0 : 1.0;
        final amp = widget.state == LiveState.idle ? 0.015 : 0.05;
        final pulse = 1 + amp * math.sin(_c.value * 2 * math.pi * speed);
        final color = _color;

        return SizedBox(
          width: s * 1.3,
          height: s * 1.3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ghoomti rangeen ring
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
              // 3D gola
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      radius: 0.95,
                      colors: [
                        Colors.white,
                        color,
                        Color.lerp(color, Colors.black, 0.65)!,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(150),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
