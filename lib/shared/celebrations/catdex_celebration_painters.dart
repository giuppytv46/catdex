import 'dart:math' as math;

import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';

enum CatDexParticleShape { spark, star, paw, ember }

@immutable
class CatDexParticleTrajectory {
  const CatDexParticleTrajectory({
    required this.angle,
    required this.distance,
    required this.delay,
    required this.lifetime,
    required this.size,
    required this.gravity,
    required this.rotation,
    required this.colorIndex,
    required this.shape,
  });

  final double angle;
  final double distance;
  final double delay;
  final double lifetime;
  final double size;
  final double gravity;
  final double rotation;
  final int colorIndex;
  final CatDexParticleShape shape;
}

@immutable
class CatDexFireworkTrajectory {
  const CatDexFireworkTrajectory({
    required this.origin,
    required this.delay,
    required this.sparkAngles,
    required this.colorIndex,
  });

  final Alignment origin;
  final double delay;
  final List<double> sparkAngles;
  final int colorIndex;
}

@immutable
class CatDexCelebrationScene {
  const CatDexCelebrationScene({
    required this.particles,
    required this.fireworks,
  });

  factory CatDexCelebrationScene.generate({
    required CatDexCelebrationTheme theme,
    required int seed,
  }) {
    final random = math.Random(seed);
    const sparksPerCornerBurst = 6;
    final cornerSparkCount = theme.fireworkCount * sparksPerCornerBurst;
    final radialParticleCount = math.max(
      0,
      theme.particleCount - cornerSparkCount,
    );
    final particles = List<CatDexParticleTrajectory>.generate(
      radialParticleCount,
      (index) {
        final shape = switch (index % 9) {
          0 || 5 => CatDexParticleShape.star,
          3 => CatDexParticleShape.paw,
          7
              when theme.palette == CatDexCelebrationPalette.halloween ||
                  theme.palette == CatDexCelebrationPalette.halloweenPremium =>
            CatDexParticleShape.ember,
          _ => CatDexParticleShape.spark,
        };
        return CatDexParticleTrajectory(
          angle:
              (math.pi * 2 * index / math.max(1, radialParticleCount)) +
              ((random.nextDouble() - 0.5) * 0.34),
          distance: 0.28 + (random.nextDouble() * 0.58),
          delay: random.nextDouble() * 0.24,
          lifetime: 0.58 + (random.nextDouble() * 0.14),
          size: 1.8 + (random.nextDouble() * 4.2),
          gravity: (random.nextDouble() * 0.12) + 0.02,
          rotation: (random.nextDouble() - 0.5) * math.pi,
          colorIndex: random.nextInt(theme.colors.length),
          shape: shape,
        );
      },
      growable: false,
    );
    const origins = [Alignment(-0.72, -0.48), Alignment(0.72, -0.44)];
    final fireworks = List<CatDexFireworkTrajectory>.generate(
      theme.fireworkCount,
      (index) => CatDexFireworkTrajectory(
        origin: origins[index % origins.length],
        delay: 0.36 + (index * 0.10),
        sparkAngles: List<double>.generate(
          sparksPerCornerBurst,
          (spark) =>
              (math.pi * 2 * spark / sparksPerCornerBurst) +
              ((random.nextDouble() - 0.5) * 0.14),
          growable: false,
        ),
        colorIndex: index % theme.colors.length,
      ),
      growable: false,
    );
    return CatDexCelebrationScene(
      particles: particles,
      fireworks: fireworks,
    );
  }

  final List<CatDexParticleTrajectory> particles;
  final List<CatDexFireworkTrajectory> fireworks;

  int get totalParticleCount =>
      particles.length +
      fireworks.fold<int>(
        0,
        (total, burst) => total + burst.sparkAngles.length,
      );
}

/// One bounded painter owns the complete visual effect. Its scene is immutable
/// and precomputed, while the animation only interpolates existing values.
class CatDexCelebrationPainter extends CustomPainter {
  CatDexCelebrationPainter({
    required Animation<double> progress,
    required this.scene,
    required this.theme,
  }) : _progress = progress,
       super(repaint: progress);

  final Animation<double> _progress;
  final CatDexCelebrationScene scene;
  final CatDexCelebrationTheme theme;
  final Paint _fillPaint = Paint();
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Path _unitStar = _createUnitStar();

  @override
  void paint(Canvas canvas, Size size) {
    final progress = _progress.value;
    final center = Offset(size.width / 2, size.height * 0.46);
    final maxDistance = size.shortestSide;
    _paintLightBurst(canvas, center, maxDistance, progress);
    _paintShockwaves(canvas, center, maxDistance, progress);
    _paintCornerBursts(canvas, size, progress);
    _paintRadialParticles(canvas, center, maxDistance, progress);
  }

  void _paintLightBurst(
    Canvas canvas,
    Offset center,
    double maxDistance,
    double progress,
  ) {
    final impact = ((progress - 0.13) / 0.19).clamp(0.0, 1.0);
    if (impact > 0 && impact < 1) {
      _fillPaint.color = Colors.white.withValues(
        alpha: math.sin(math.pi * impact) * 0.42,
      );
      canvas.drawCircle(
        center,
        maxDistance * (0.08 + impact * 0.32),
        _fillPaint,
      );
    }
    if (!theme.lightRays || progress < 0.18 || progress > 0.76) return;
    final rayFade = math.sin(
      math.pi * ((progress - 0.18) / 0.58).clamp(0.0, 1.0),
    );
    _strokePaint
      ..color = theme.colors.first.withValues(alpha: rayFade * 0.20)
      ..strokeWidth = 2;
    for (var index = 0; index < 12; index += 1) {
      final angle = (math.pi * 2 * index / 12) + progress * 0.24;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      canvas.drawLine(
        center + Offset(dx, dy) * 52,
        center + Offset(dx, dy) * (maxDistance * 0.58),
        _strokePaint,
      );
    }
  }

  void _paintShockwaves(
    Canvas canvas,
    Offset center,
    double maxDistance,
    double progress,
  ) {
    for (var index = 0; index < theme.shockwaveCount; index += 1) {
      final start = 0.16 + (index * 0.08);
      final local = ((progress - start) / 0.25).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      _strokePaint
        ..strokeWidth = 4 * (1 - local) + 1
        ..color = theme.colors[index % theme.colors.length].withValues(
          alpha: (1 - local) * 0.68,
        );
      canvas.drawCircle(
        center,
        maxDistance * (0.08 + local * 0.64),
        _strokePaint,
      );
    }
  }

  void _paintCornerBursts(Canvas canvas, Size size, double progress) {
    for (final burst in scene.fireworks) {
      final local = ((progress - burst.delay) / 0.36).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final origin = burst.origin.alongSize(size);
      final fade = 1 - local;
      final distance = size.shortestSide * (0.05 + 0.13 * local);
      _strokePaint
        ..color = theme.colors[burst.colorIndex].withValues(alpha: fade * 0.84)
        ..strokeWidth = 1.4 + fade;
      for (final angle in burst.sparkAngles) {
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        final direction = Offset(dx, dy);
        final start = origin + direction * distance * 0.30;
        final end = origin + direction * distance;
        canvas
          ..drawLine(start, end, _strokePaint)
          ..drawCircle(end, 1.2 + fade, _strokePaint);
      }
    }
  }

  void _paintRadialParticles(
    Canvas canvas,
    Offset center,
    double maxDistance,
    double progress,
  ) {
    if (progress <= 0.12) return;
    for (final particle in scene.particles) {
      final local = ((progress - 0.16 - particle.delay) / particle.lifetime)
          .clamp(
            0.0,
            1.0,
          );
      if (local <= 0 || local >= 1) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final direction = Offset(
        math.cos(particle.angle),
        math.sin(particle.angle),
      );
      final point =
          center +
          direction * (particle.distance * maxDistance * eased) +
          Offset(0, particle.gravity * maxDistance * local * local);
      final alpha = math.sin(math.pi * local).clamp(0.0, 1.0);
      _fillPaint.color = theme.colors[particle.colorIndex].withValues(
        alpha: alpha * 0.90,
      );
      final particleSize = particle.size * (1 - local * 0.25);
      switch (particle.shape) {
        case CatDexParticleShape.spark:
          canvas.drawCircle(point, particleSize, _fillPaint);
        case CatDexParticleShape.star:
          canvas
            ..save()
            ..translate(point.dx, point.dy)
            ..rotate(particle.rotation + local)
            ..scale(particleSize * 1.35)
            ..drawPath(_unitStar, _fillPaint)
            ..restore();
        case CatDexParticleShape.paw:
          _drawPaw(canvas, point, particleSize, _fillPaint);
        case CatDexParticleShape.ember:
          canvas.drawOval(
            Rect.fromCenter(
              center: point,
              width: particleSize,
              height: particleSize * 2.1,
            ),
            _fillPaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CatDexCelebrationPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.theme != theme;
}

class CatDexEnergyBuildupPainter extends CustomPainter {
  CatDexEnergyBuildupPainter({
    required this.progress,
    required this.color,
    this.particleCount = 18,
  });

  final double progress;
  final Color color;
  final int particleCount;
  final Paint _paint = Paint();
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.46;
    for (var index = 0; index < particleCount; index += 1) {
      final phase = (progress + index / particleCount) % 1;
      final angle = (math.pi * 2 * index / particleCount) + progress * 1.4;
      final point =
          center +
          Offset(math.cos(angle), math.sin(angle)) * radius * (1 - phase);
      _paint.color = color.withValues(alpha: 0.18 + phase * 0.58);
      canvas.drawCircle(point, 1.2 + (1 - phase) * 1.8, _paint);
    }
    _ringPaint
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.28 + progress * 0.20);
    canvas.drawCircle(
      center,
      radius * (0.72 + progress * 0.08),
      _ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CatDexEnergyBuildupPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

void _drawPaw(Canvas canvas, Offset center, double size, Paint paint) {
  canvas.drawOval(
    Rect.fromCenter(center: center, width: size * 1.5, height: size * 1.25),
    paint,
  );
  for (var index = 0; index < 3; index += 1) {
    canvas.drawCircle(
      center.translate((index - 1) * size * 0.62, -size * 0.78),
      size * 0.34,
      paint,
    );
  }
}

Path _createUnitStar() {
  final path = Path();
  for (var index = 0; index < 10; index += 1) {
    final angle = -math.pi / 2 + index * math.pi / 5;
    final radius = index.isEven ? 1.0 : 0.44;
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius;
    if (index == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path..close();
}
