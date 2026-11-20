import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zoya ke neon rang.
class NeonColors {
  static const cyan = Color(0xFF00E5FF);
  static const blue = Color(0xFF2979FF);
  static const purple = Color(0xFF8A2BFF);
  static const magenta = Color(0xFFFF2BD6);
  static const bg = Color(0xFF07070F);
  static const card = Color(0xFF0F0F1C);

  /// Pehla aur aakhri rang same, taaki ghoomti line me jod na dikhe.
  static const ring = <Color>[cyan, blue, purple, magenta, cyan];
}

/// Kisi bhi widget ke chaaro taraf ghoomti rangeen glowing line.
class NeonBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  final double thickness;
  final Duration duration;

  const NeonBorder({
    super.key,
    required this.child,
    this.radius = 18,
    this.thickness = 2,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<NeonBorder> createState() => _NeonBorderState();
}

class _NeonBorderState extends State<NeonBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(widget.thickness),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
              colors: NeonColors.ring,
              transform: GradientRotation(_c.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: NeonColors.purple.withAlpha(90),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius:
                  BorderRadius.circular(widget.radius - widget.thickness),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Screen ke dono kinare par upar-neeche daudti rangeen glowing lines.
class SideLines extends StatefulWidget {
  const SideLines({super.key});

  @override
  State<SideLines> createState() => _SideLinesState();
}

class _SideLinesState extends State<SideLines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _line(double t, double dir) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1 + 2 * t * dir),
          end: Alignment(0, 1 + 2 * t * dir),
          colors: NeonColors.ring,
          tileMode: TileMode.repeated,
        ),
        boxShadow: [
          BoxShadow(color: NeonColors.cyan.withAlpha(110), blurRadius: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_line(_c.value, 1), _line(_c.value, -1)],
        );
      },
    );
  }
}

/// 3D jaisa tirchha, glow wala button (home screen ke liye).
class NeonTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const NeonTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<NeonTile> createState() => _NeonTileState();
}

class _NeonTileState extends State<NeonTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-0.05)
          ..rotateY(0.04),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: NeonBorder(
            radius: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [NeonColors.cyan, NeonColors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(widget.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: NeonColors.cyan),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
