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

/// Poori screen ke chaaro kinaron par ghoomti 12 rangon ki line.
class ScreenBorder extends StatefulWidget {
  const ScreenBorder({super.key});

  @override
  State<ScreenBorder> createState() => _ScreenBorderState();
}

class _ScreenBorderState extends State<ScreenBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _BorderPainter(_c.value),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final double t;
  _BorderPainter(this.t);

  /// 12 rang. Speed badalni ho to upar duration (6 seconds) badlo.
  static const _colors = <Color>[
    Color(0xFFFF1744), // laal
    Color(0xFFFF9100), // narangi
    Color(0xFFFFEA00), // peela
    Color(0xFF76FF03), // lime
    Color(0xFF00E676), // hara
    Color(0xFF1DE9B6), // teal
    Color(0xFF00E5FF), // cyan
    Color(0xFF2979FF), // neela
    Color(0xFF651FFF), // indigo
    Color(0xFFD500F9), // jamuni
    Color(0xFFFF2BD6), // magenta
    Color(0xFFFF4081), // gulabi
  ];

  Color _at(double x) {
    x = x % 1.0;
    if (x < 0) x += 1.0;
    final f = x * _colors.length;
    final i = f.floor();
    return Color.lerp(
      _colors[i % _colors.length],
      _colors[(i + 1) % _colors.length],
      f - i,
    )!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    const radius = 36.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(radius)));
    final metric = path.computeMetrics().first;
    final len = metric.length;

    // Glow (kam tukde, dhundhli roshni)
    const glowSegs = 30;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (var i = 0; i < glowSegs; i++) {
      final a = len * i / glowSegs;
      final b = math.min(len, len * (i + 1) / glowSegs + 1);
      glow.color = _at(i / glowSegs - t).withAlpha(110);
      canvas.drawPath(metric.extractPath(a, b), glow);
    }

    // Asli line
    const segs = 120;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (var i = 0; i < segs; i++) {
      final a = len * i / segs;
      final b = math.min(len, len * (i + 1) / segs + 1);
      line.color = _at(i / segs - t);
      canvas.drawPath(metric.extractPath(a, b), line);
    }
  }

  @override
  bool shouldRepaint(_BorderPainter old) => old.t != t;
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


/// Dashboard ka ek chhota dabba (icon + naam + chhoti line).
class NeonGridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool dim;

  const NeonGridTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.55 : 1.0,
      child: Material(
        color: NeonColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: NeonColors.purple.withAlpha(140), width: 1.4),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: NeonColors.cyan),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: NeonColors.cyan.withAlpha(200)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widgets ko 2 kolam me lagata hai. Aakhri akela ho to poori chaudai leta hai.
Widget neonRows(List<Widget> tiles, {double gap = 12, double height = 108}) {
  final rows = <Widget>[];
  for (var i = 0; i < tiles.length; i += 2) {
    final pair = i + 1 < tiles.length;
    rows.add(Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: tiles[i]),
            if (pair) ...[
              SizedBox(width: gap),
              Expanded(child: tiles[i + 1]),
            ],
          ],
        ),
      ),
    ));
  }
  return Column(children: rows);
}
