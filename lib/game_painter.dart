// lib/widgets/game_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

import 'game_models.dart';


class GamePainter extends CustomPainter {
  final GameState gameState;

  GamePainter(this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawTrack(canvas, size);
    _drawObstacles(canvas, size);
    _drawPlayer(canvas, size);
    _drawFog(canvas, size);
  }

  // ─── Sky & Background ───────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    final skyGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D0A1A),
        const Color(0xFF1A0A2E),
        const Color(0xFF2D1B4E),
        const Color(0xFF3D1A0A),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    final skyPaint = Paint()
      ..shader = skyGrad.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.7);
    final rng = Random(42);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.45;
      final r = rng.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    // Temple silhouette in the background
    _drawTempleSilhouette(canvas, size);
  }

  void _drawTempleSilhouette(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A0A2E).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final horizon = size.height * 0.42;
    final cx = size.width / 2;

    final path = Path();
    // Main temple structure
    path.moveTo(cx - 80, horizon);
    path.lineTo(cx - 80, horizon - 60);
    path.lineTo(cx - 50, horizon - 60);
    path.lineTo(cx - 50, horizon - 100);
    path.lineTo(cx - 30, horizon - 100);
    path.lineTo(cx - 30, horizon - 130);
    path.lineTo(cx, horizon - 160);
    path.lineTo(cx + 30, horizon - 130);
    path.lineTo(cx + 30, horizon - 100);
    path.lineTo(cx + 50, horizon - 100);
    path.lineTo(cx + 50, horizon - 60);
    path.lineTo(cx + 80, horizon - 60);
    path.lineTo(cx + 80, horizon);
    path.close();

    // Left tower
    final lp = Path();
    lp.moveTo(cx - 150, horizon);
    lp.lineTo(cx - 150, horizon - 80);
    lp.lineTo(cx - 130, horizon - 80);
    lp.lineTo(cx - 130, horizon - 110);
    lp.lineTo(cx - 140, horizon - 130);
    lp.lineTo(cx - 120, horizon - 110);
    lp.lineTo(cx - 120, horizon - 80);
    lp.lineTo(cx - 100, horizon - 80);
    lp.lineTo(cx - 100, horizon);
    lp.close();

    // Right tower mirror
    final rp = Path();
    rp.moveTo(cx + 100, horizon);
    rp.lineTo(cx + 100, horizon - 80);
    rp.lineTo(cx + 120, horizon - 80);
    rp.lineTo(cx + 120, horizon - 110);
    rp.lineTo(cx + 140, horizon - 130);
    rp.lineTo(cx + 150, horizon - 110);
    rp.lineTo(cx + 150, horizon - 80);
    rp.lineTo(cx + 160, horizon - 80);
    rp.lineTo(cx + 160, horizon);
    rp.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(lp, paint);
    canvas.drawPath(rp, paint);
  }

  // ─── Track ──────────────────────────────────────────────────────────────────

  static const double _horizonY = 0.42; // fraction of screen height

  Offset _laneCenter(LanePosition lane, Size size, double zDepth) {
    // zDepth: 0=near (bottom), 1=far (horizon)
    final y = size.height * (_horizonY + (1 - _horizonY) * (1 - zDepth));
    final spread = size.width * 0.35 * (1 - zDepth * 0.7);
    final cx = size.width / 2;
    return switch (lane) {
      LanePosition.left => Offset(cx - spread, y),
      LanePosition.center => Offset(cx, y),
      LanePosition.right => Offset(cx + spread, y),
    };
  }

  void _drawTrack(Canvas canvas, Size size) {
    final horizon = size.height * _horizonY;
    final bottom = size.height;
    final cx = size.width / 2;

    // Ground fill
    final groundGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF3D1A0A),
        const Color(0xFF5C2A10),
        const Color(0xFF7A3A18),
      ],
    );
    final groundPaint = Paint()
      ..shader = groundGrad.createShader(Rect.fromLTWH(0, horizon, size.width, bottom - horizon));

    // Track trapezoid
    final trackPath = Path()
      ..moveTo(cx - 40, horizon)
      ..lineTo(cx + 40, horizon)
      ..lineTo(cx + size.width * 0.48, bottom)
      ..lineTo(cx - size.width * 0.48, bottom)
      ..close();
    canvas.drawPath(trackPath, groundPaint);

    // Track surface (stone tiles feel)
    final stonePaint = Paint()
      ..color = const Color(0xFF8B5E3C).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Scroll lines using distance
    final scrollOffset = (gameState.distance * 0.3) % 1.0;
    for (int row = 0; row < 12; row++) {
      final t = (row / 12.0 + scrollOffset) % 1.0;
      final y = horizon + (bottom - horizon) * t;
      final halfW = 40 + (size.width * 0.48 - 40) * t;
      canvas.drawLine(Offset(cx - halfW, y), Offset(cx + halfW, y), stonePaint);
    }

    // Lane dividers
    for (final offset in [-1, 1]) {
      final laneLinePaint = Paint()
        ..color = const Color(0xFFD4A44C).withOpacity(0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cx + offset * 38, horizon),
        Offset(cx + offset * size.width * 0.34, bottom),
        laneLinePaint,
      );
    }

    // Side walls
    _drawSideWalls(canvas, size, horizon, bottom, cx);
  }

  void _drawSideWalls(Canvas canvas, Size size, double horizon, double bottom, double cx) {
    final wallPaint = Paint()
      ..color = const Color(0xFF6B3A1F)
      ..style = PaintingStyle.fill;

    // Left wall
    final leftWall = Path()
      ..moveTo(0, horizon)
      ..lineTo(cx - 40, horizon)
      ..lineTo(cx - size.width * 0.48, bottom)
      ..lineTo(0, bottom)
      ..close();
    canvas.drawPath(leftWall, wallPaint);

    // Right wall
    final rightWall = Path()
      ..moveTo(size.width, horizon)
      ..lineTo(cx + 40, horizon)
      ..lineTo(cx + size.width * 0.48, bottom)
      ..lineTo(size.width, bottom)
      ..close();
    canvas.drawPath(rightWall, wallPaint);

    // Wall texture lines
    final texPaint = Paint()
      ..color = const Color(0xFF3D1A0A).withOpacity(0.4)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 6; i++) {
      final t = i / 6.0;
      // Left wall horizontal lines
      canvas.drawLine(
        Offset(0, horizon + (bottom - horizon) * t),
        Offset(cx - 40 - (size.width * 0.48 - 40) * t, horizon + (bottom - horizon) * t),
        texPaint,
      );
      // Right wall
      canvas.drawLine(
        Offset(size.width, horizon + (bottom - horizon) * t),
        Offset(cx + 40 + (size.width * 0.48 - 40) * t, horizon + (bottom - horizon) * t),
        texPaint,
      );
    }

    // Glowing torches on walls
    _drawTorch(canvas, size, Offset(size.width * 0.08, size.height * 0.65));
    _drawTorch(canvas, size, Offset(size.width * 0.92, size.height * 0.65));
  }

  void _drawTorch(Canvas canvas, Size size, Offset pos) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final flicker = 0.8 + 0.2 * sin(t * 7.3 + pos.dx);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.15 * flicker)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(pos, 40, glowPaint);

    // Flame
    final flamePaint = Paint()
      ..color = Color.lerp(const Color(0xFFFF4400), const Color(0xFFFFAA00), flicker)!;
    canvas.drawOval(
      Rect.fromCenter(center: pos - const Offset(0, 8), width: 10 * flicker, height: 14),
      flamePaint,
    );

    // Torch body
    final bodyPaint = Paint()..color = const Color(0xFF5C3010);
    canvas.drawRect(Rect.fromCenter(center: pos + const Offset(0, 8), width: 6, height: 16), bodyPaint);
  }

  // ─── Obstacles & Coins ─────────────────────────────────────────────────────

  void _drawObstacles(Canvas canvas, Size size) {
    for (final obs in gameState.obstacles) {
      if (obs.collected) continue;
      if (obs.zPosition < -0.05 || obs.zPosition > 1.0) continue;

      final pos = _laneCenter(obs.lane, size, obs.zPosition);
      final scale = (1 - obs.zPosition * 0.75).clamp(0.1, 1.0);

      switch (obs.type) {
        case ObstacleType.barrier:
          _drawBarrier(canvas, pos, scale, size);
          break;
        case ObstacleType.lowBarrier:
          _drawLowBarrier(canvas, pos, scale, size);
          break;
        case ObstacleType.coin:
          _drawCoin(canvas, pos, scale);
          break;
        case ObstacleType.powerup:
          _drawPowerup(canvas, pos, scale, obs.powerupType!);
          break;
      }
    }
  }

  void _drawBarrier(Canvas canvas, Offset pos, double scale, Size size) {
    final w = 60.0 * scale;
    final h = 80.0 * scale;

    // Stone pillar
    final pillarPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF8B6914), const Color(0xFFD4A832), const Color(0xFF6B4F0F)],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromCenter(center: pos, width: w, height: h));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - Offset(0, h / 2), width: w, height: h),
        Radius.circular(4 * scale),
      ),
      pillarPaint,
    );

    // Glowing runes on barrier
    final runePaint = Paint()
      ..color = const Color(0xFFFF4400).withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale);
    final rw = w * 0.3;
    canvas.drawLine(
      pos - Offset(rw, h * 0.6),
      pos - Offset(rw, h * 0.2),
      runePaint..strokeWidth = 2 * scale,
    );
    canvas.drawLine(
      pos + Offset(rw, -h * 0.6),
      pos + Offset(rw, -h * 0.2),
      runePaint,
    );
    canvas.drawLine(
      pos - Offset(rw * 1.5, h * 0.4),
      pos + Offset(rw * 1.5, -h * 0.4),
      runePaint,
    );

    // Top ornament
    final topPaint = Paint()..color = const Color(0xFFD4A832);
    canvas.drawCircle(pos - Offset(0, h + scale * 5), 7 * scale, topPaint);
  }

  void _drawLowBarrier(Canvas canvas, Offset pos, double scale, Size size) {
    final w = 75.0 * scale;
    final h = 30.0 * scale;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF5C3010), const Color(0xFF9B6020), const Color(0xFF5C3010)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: pos - Offset(0, h / 2), width: w, height: h));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - Offset(0, h / 2), width: w, height: h),
        Radius.circular(3 * scale),
      ),
      paint,
    );

    // Spike tops
    final spikePaint = Paint()..color = const Color(0xFFD4A832);
    for (int i = -2; i <= 2; i++) {
      final sx = pos.dx + i * 14 * scale;
      final sy = pos.dy - h - 10 * scale;
      final sp = Path()
        ..moveTo(sx, sy)
        ..lineTo(sx - 5 * scale, sy + 12 * scale)
        ..lineTo(sx + 5 * scale, sy + 12 * scale)
        ..close();
      canvas.drawPath(sp, spikePaint);
    }
  }

  void _drawCoin(Canvas canvas, Offset pos, double scale) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final spin = sin(t * 4 + pos.dx) * 0.8 + 0.2;
    final r = 12.0 * scale;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
    canvas.drawCircle(pos, r * 1.6, glowPaint);

    // Coin ellipse (spin effect)
    final coinPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFFFE566), const Color(0xFFD4A832), const Color(0xFFAA7A10)],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCenter(center: pos, width: r * 2, height: r * 2));
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: r * 2 * spin.abs(), height: r * 2),
      coinPaint,
    );

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.5 * spin.abs())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawOval(
      Rect.fromCenter(center: pos - Offset(0, 2 * scale), width: r * 1.2 * spin.abs(), height: r * 1.2),
      highlightPaint,
    );
  }

  void _drawPowerup(Canvas canvas, Offset pos, double scale, PowerupType type) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulse = 0.9 + 0.1 * sin(t * 3);
    final r = 18.0 * scale * pulse;

    final color = switch (type) {
      PowerupType.shield => const Color(0xFF00AAFF),
      PowerupType.magnet => const Color(0xFFFF00AA),
      PowerupType.speedBoost => const Color(0xFF00FF88),
    };

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale);
    canvas.drawCircle(pos, r * 2, glowPaint);

    // Body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.9), color.withOpacity(0.4)],
      ).createShader(Rect.fromCenter(center: pos, width: r * 2, height: r * 2));
    canvas.drawCircle(pos, r, bodyPaint);

    // Icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;
    final iconSize = r * 0.65;
    switch (type) {
      case PowerupType.shield:
        // Shield shape
        final sp = Path()
          ..moveTo(pos.dx, pos.dy - iconSize)
          ..lineTo(pos.dx + iconSize * 0.8, pos.dy - iconSize * 0.3)
          ..lineTo(pos.dx + iconSize * 0.8, pos.dy + iconSize * 0.3)
          ..lineTo(pos.dx, pos.dy + iconSize)
          ..lineTo(pos.dx - iconSize * 0.8, pos.dy + iconSize * 0.3)
          ..lineTo(pos.dx - iconSize * 0.8, pos.dy - iconSize * 0.3)
          ..close();
        canvas.drawPath(sp, iconPaint..style = PaintingStyle.stroke);
        break;
      case PowerupType.magnet:
        // U-shape
        final mp = Path()
          ..moveTo(pos.dx - iconSize * 0.6, pos.dy - iconSize * 0.5)
          ..lineTo(pos.dx - iconSize * 0.6, pos.dy + iconSize * 0.3)
          ..arcToPoint(Offset(pos.dx + iconSize * 0.6, pos.dy + iconSize * 0.3),
              radius: Radius.circular(iconSize * 0.6), clockwise: false)
          ..lineTo(pos.dx + iconSize * 0.6, pos.dy - iconSize * 0.5);
        canvas.drawPath(mp, iconPaint);
        break;
      case PowerupType.speedBoost:
        // Lightning bolt
        final lp = Path()
          ..moveTo(pos.dx + iconSize * 0.2, pos.dy - iconSize)
          ..lineTo(pos.dx - iconSize * 0.3, pos.dy)
          ..lineTo(pos.dx + iconSize * 0.1, pos.dy)
          ..lineTo(pos.dx - iconSize * 0.2, pos.dy + iconSize)
          ..lineTo(pos.dx + iconSize * 0.3, pos.dy - iconSize * 0.1)
          ..lineTo(pos.dx - iconSize * 0.1, pos.dy - iconSize * 0.1)
          ..close();
        canvas.drawPath(lp, iconPaint..style = PaintingStyle.fill..color = Colors.white);
        break;
    }
  }

  // ─── Player ─────────────────────────────────────────────────────────────────

  void _drawPlayer(Canvas canvas, Size size) {
    final player = gameState.player;
    if (player.state == PlayerState.dead) return;

    final lanePos = _laneCenter(player.lane, size, 0.0);
    final groundY = lanePos.dy;

    // Apply jump/slide offset
    final bodyY = groundY - 50 - player.yOffset * 80;
    final pos = Offset(lanePos.dx, bodyY);

    final isSliding = player.state == PlayerState.sliding;
    final isJumping = player.state == PlayerState.jumping;

    canvas.save();
    if (isSliding) canvas.translate(0, 25);
    _drawCharacter(canvas, pos, player, isSliding, isJumping);
    canvas.restore();

    // Shield aura
    if (player.hasShield) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final pulse = 0.7 + 0.3 * sin(t * 5);
      final shieldPaint = Paint()
        ..color = const Color(0xFF00AAFF).withOpacity(0.25 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(pos, 55, shieldPaint);
      final shieldBorderPaint = Paint()
        ..color = const Color(0xFF00AAFF).withOpacity(0.6 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(pos, 52, shieldBorderPaint);
    }
  }

  void _drawCharacter(Canvas canvas, Offset pos, Player player, bool isSliding, bool isJumping) {
    final frame = player.animationFrame;
    final runSwing = isSliding ? 0.0 : sin(frame) * 15;

    // Shadow on ground
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + (isSliding ? 30 : 60)),
        width: isSliding ? 60 : 30,
        height: isSliding ? 12 : 8,
      ),
      shadowPaint,
    );

    if (isSliding) {
      _drawSlideCharacter(canvas, pos);
    } else {
      _drawRunCharacter(canvas, pos, runSwing, isJumping);
    }
  }

  void _drawRunCharacter(Canvas canvas, Offset pos, double swing, bool jumping) {
    final bodyColor = const Color(0xFF2A6EBB);
    final skinColor = const Color(0xFFDEB887);
    final hairColor = const Color(0xFF3D1A00);

    // Legs
    final legPaint = Paint()..color = const Color(0xFF1A3A6B);
    // Left leg
    canvas.save();
    canvas.translate(pos.dx - 8, pos.dy + 20);
    canvas.rotate(-swing * pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-5, 0, 10, 28), legPaint);
    canvas.restore();
    // Right leg
    canvas.save();
    canvas.translate(pos.dx + 8, pos.dy + 20);
    canvas.rotate(swing * pi / 180);
    canvas.drawRect(const Rect.fromLTWH(-5, 0, 10, 28), legPaint);
    canvas.restore();

    // Boots
    final bootPaint = Paint()..color = const Color(0xFF3D1A00);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx - 8 - sin(-swing * pi / 180) * 10, pos.dy + 50), width: 14, height: 10),
        const Radius.circular(3),
      ),
      bootPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pos.dx + 8 + sin(swing * pi / 180) * 10, pos.dy + 50), width: 14, height: 10),
        const Radius.circular(3),
      ),
      bootPaint,
    );

    // Body / jacket
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [bodyColor, const Color(0xFF1A4A8B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: pos, width: 30, height: 40));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - const Offset(0, 10), width: 30, height: 38),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Arms
    final armPaint = Paint()..color = bodyColor;
    canvas.save();
    canvas.translate(pos.dx - 18, pos.dy - 8);
    canvas.rotate(swing * pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -5, 12, 26), const Radius.circular(4)),
      armPaint,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(pos.dx + 18, pos.dy - 8);
    canvas.rotate(-swing * pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -5, 12, 26), const Radius.circular(4)),
      armPaint,
    );
    canvas.restore();

    // Head
    final headPaint = Paint()..color = skinColor;
    canvas.drawCircle(pos - const Offset(0, 28), 16, headPaint);

    // Hair
    final hair = Paint()..color = hairColor;
    canvas.drawArc(
      Rect.fromCenter(center: pos - const Offset(0, 30), width: 32, height: 28),
      pi, pi, true, hair,
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(pos - const Offset(5, 28), 3, eyePaint);
    canvas.drawCircle(pos - const Offset(-5, 28), 3, eyePaint);

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos - const Offset(4, 29), 1.2, shinePaint);
    canvas.drawCircle(pos - const Offset(-6, 29), 1.2, shinePaint);

    // Hat (explorer hat)
    final hatPaint = Paint()..color = const Color(0xFF8B6914);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - const Offset(0, 43), width: 28, height: 12),
        const Radius.circular(3),
      ),
      hatPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - const Offset(0, 50), width: 20, height: 14),
        const Radius.circular(4),
      ),
      hatPaint,
    );
    // Hat brim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos - const Offset(0, 43), width: 36, height: 6),
        const Radius.circular(2),
      ),
      hatPaint..color = const Color(0xFF6B4F0F),
    );
  }

  void _drawSlideCharacter(Canvas canvas, Offset pos) {
    final skinColor = const Color(0xFFDEB887);
    final bodyColor = const Color(0xFF2A6EBB);

    // Horizontal body (sliding)
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [bodyColor, const Color(0xFF1A4A8B)],
      ).createShader(Rect.fromCenter(center: pos, width: 60, height: 22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: 60, height: 22),
        const Radius.circular(8),
      ),
      bodyPaint,
    );

    // Head at front
    final headPaint = Paint()..color = skinColor;
    canvas.drawCircle(pos - const Offset(25, 0), 13, headPaint);
    final hairPaint = Paint()..color = const Color(0xFF3D1A00);
    canvas.drawArc(
      Rect.fromCenter(center: pos - const Offset(26, 2), width: 26, height: 22),
      pi + 0.3, pi - 0.6, true, hairPaint,
    );

    // Legs extended back
    final legPaint = Paint()..color = const Color(0xFF1A3A6B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos + const Offset(22, 6), width: 30, height: 10),
        const Radius.circular(4),
      ),
      legPaint,
    );
  }

  // ─── Fog overlay ───────────────────────────────────────────────────────────

  void _drawFog(Canvas canvas, Size size) {
    final horizon = size.height * _horizonY;
    final fogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A0A2E).withOpacity(0.0),
          const Color(0xFF1A0A2E).withOpacity(0.5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizon));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizon), fogPaint);
  }

  @override
  bool shouldRepaint(GamePainter old) => true;
}
