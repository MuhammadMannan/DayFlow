import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/models.dart';
import '../theme/tokens.dart';

/// Streak lengths that get a celebration.
const streakMilestones = [7, 30, 100, 365];

/// The milestone reached by going from [before] to [after] days, if any.
int? milestoneReached(int before, int after) {
  for (final m in streakMilestones) {
    if (before < m && after >= m) return m;
  }
  return null;
}

String _message(int days) {
  final nextIndex = streakMilestones.indexWhere((m) => m > days);
  final next = nextIndex == -1
      ? ''
      : ' Next milestone: ${streakMilestones[nextIndex]} days.';
  final lead = switch (days) {
    7 => 'A full week of getting things done.',
    30 => 'A whole month without dropping the thread.',
    100 => 'One hundred days. This is a habit now.',
    365 => 'A full year. Remarkable.',
    _ => '$days days of getting things done.',
  };
  return '$lead$next';
}

Future<void> showMilestone(
  BuildContext context, {
  required int days,
  required Map<DateTime, int> completions,
}) {
  HapticFeedback.heavyImpact();
  return Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) =>
        MilestoneScreen(days: days, completions: completions),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ));
}

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen(
      {super.key, required this.days, required this.completions});

  final int days;
  final Map<DateTime, int> completions;

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final _pieces = _makePieces();

  List<_Piece> _makePieces() {
    final r = math.Random(widget.days);
    const colors = [
      Color(0xFFFFFFFF),
      Color(0xFFFF7A1A),
      Color(0xFFFFD166),
      Color(0xFF8DA4FF),
      Color(0xFF7EE0C3),
    ];
    return List.generate(
      70,
      (_) => _Piece(
        angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.5,
        speed: 260 + r.nextDouble() * 520,
        spin: (r.nextDouble() - 0.5) * 14,
        size: 6 + r.nextDouble() * 6,
        color: colors[r.nextInt(colors.length)],
        delay: r.nextDouble() * 0.15,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Respect the system "Reduce Motion" setting.
      if (MediaQuery.of(context).disableAnimations) {
        _intro.value = 1;
      } else {
        _intro.forward();
        _confetti.forward();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final today = dateOnly(DateTime.now());
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final pop = CurvedAnimation(parent: _intro, curve: Curves.elasticOut);
    final fade = CurvedAnimation(
        parent: _intro, curve: const Interval(0.25, 0.8, curve: Curves.easeOut));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.primary,
        body: Stack(
          children: [
            // Soft concentric rings behind the flame.
            Positioned.fill(
              child: CustomPaint(painter: _RingsPainter()),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (_, _) => CustomPaint(
                    painter: _ConfettiPainter(_pieces, _confetti.value),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DfSpace.s6),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    ScaleTransition(
                      scale: pop,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: DfShadow.floating,
                        ),
                        child: Icon(LucideIcons.flame,
                            size: 56, color: DfColors.light.flame),
                      ),
                    ),
                    const SizedBox(height: DfSpace.s2),
                    FadeTransition(
                      opacity: fade,
                      child: Column(
                        children: [
                          Text(
                            '${widget.days}',
                            style: DfText.display.copyWith(
                              color: Colors.white,
                              fontSize: 88,
                              height: 1,
                            ),
                          ),
                          Text('day streak!',
                              style: DfText.h1.copyWith(color: Colors.white)),
                          const SizedBox(height: DfSpace.s4),
                          Text(
                            _message(widget.days),
                            textAlign: TextAlign.center,
                            style: DfText.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: DfSpace.s5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 6; i >= 0; i--)
                                Builder(builder: (context) {
                                  final day = DateTime(today.year,
                                      today.month, today.day - i);
                                  final done =
                                      (widget.completions[day] ?? 0) > 0 ||
                                          i == 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: done
                                                ? Colors.white
                                                : Colors.white
                                                    .withValues(alpha: 0.25),
                                          ),
                                          child: done
                                              ? Icon(LucideIcons.check,
                                                  size: 16, color: c.primary)
                                              // A frozen day kept the streak.
                                              : const Icon(
                                                  LucideIcons.snowflake,
                                                  size: 14,
                                                  color: Colors.white),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          letters[day.weekday - 1],
                                          style: DfText.caption.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85)),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 4),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DfRadius.lg),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: Center(
                            child: Text('Keep going',
                                style: DfText.bodyStrong
                                    .copyWith(color: DfColors.light.primary)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.40);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(center, size.width * 0.62, paint);
    canvas.drawCircle(center, size.width * 0.40, paint);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => false;
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.delay,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.36);
    const seconds = 2.6;
    const gravity = 520.0;
    for (final p in pieces) {
      final time = (t - p.delay).clamp(0.0, 1.0) * seconds;
      if (time <= 0) continue;
      // Launch outwards, slow with drag, then fall.
      final drag = 1 - math.exp(-1.6 * time);
      final dx = math.cos(p.angle) * p.speed * drag / 1.6;
      final dy =
          math.sin(p.angle) * p.speed * drag / 1.6 + 0.5 * gravity * time * time * 0.5;
      final opacity = (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * time);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
