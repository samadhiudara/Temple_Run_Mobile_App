// lib/widgets/game_hud.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_bloc.dart';
import 'game_event.dart';
import 'game_models.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        return Stack(
          children: [
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScoreDisplay(score: state.score, distance: state.distance),
                    _LivesDisplay(lives: state.lives),
                    _PauseButton(),
                  ],
                ),
              ),
            ),
            // Coins
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _CoinDisplay(coins: state.coins),
                ),
              ),
            ),
            // Powerup bar
            if (state.activePowerup != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: _PowerupTimer(
                      powerup: state.activePowerup!,
                      timer: state.powerupTimer,
                    ),
                  ),
                ),
              ),
            // Combo
            if (state.combo > 2)
              Align(
                alignment: const Alignment(0, -0.3),
                child: _ComboDisplay(combo: state.combo),
              ),
            // Speed indicator
            Align(
              alignment: const Alignment(0.9, 0.0),
              child: _SpeedBar(speed: state.gameSpeed),
            ),
          ],
        );
      },
    );
  }
}

// ─── Score Display ────────────────────────────────────────────────────────────

class _ScoreDisplay extends StatelessWidget {
  final int score;
  final double distance;
  const _ScoreDisplay({required this.score, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4A832).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toString().padLeft(6, '0'),
            style: GoogleFonts.cinzel(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4A832),
              letterSpacing: 2,
            ),
          ),
          Text(
            '${distance.toInt()}m',
            style: GoogleFonts.cinzel(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lives ────────────────────────────────────────────────────────────────────

class _LivesDisplay extends StatelessWidget {
  final int lives;
  const _LivesDisplay({required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.favorite,
            size: 22,
            color: i < lives
                ? const Color(0xFFFF3366)
                : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

// ─── Pause Button ─────────────────────────────────────────────────────────────

class _PauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<GameBloc>().add(const GamePaused()),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD4A832).withOpacity(0.4)),
        ),
        child: const Icon(Icons.pause_rounded, color: Color(0xFFD4A832), size: 24),
      ),
    );
  }
}

// ─── Coin Display ─────────────────────────────────────────────────────────────

class _CoinDisplay extends StatelessWidget {
  final int coins;
  const _CoinDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4A832).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFFFFE566), Color(0xFFD4A832)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            coins.toString(),
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4A832),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Powerup Timer ────────────────────────────────────────────────────────────

class _PowerupTimer extends StatelessWidget {
  final PowerupType powerup;
  final double timer;
  const _PowerupTimer({required this.powerup, required this.timer});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (powerup) {
      PowerupType.shield => ('SHIELD', const Color(0xFF00AAFF), Icons.shield),
      PowerupType.magnet => ('MAGNET', const Color(0xFFFF00AA), Icons.electric_bolt),
      PowerupType.speedBoost => ('BOOST', const Color(0xFF00FF88), Icons.speed),
    };
    final fraction = (timer / 8.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Combo Display ────────────────────────────────────────────────────────────

class _ComboDisplay extends StatelessWidget {
  final int combo;
  const _ComboDisplay({required this.combo});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        'x$combo COMBO!',
        style: GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFD700),
          letterSpacing: 3,
          shadows: [
            const Shadow(color: Color(0xFFFF6600), blurRadius: 20),
            const Shadow(color: Colors.black, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Speed Bar ────────────────────────────────────────────────────────────────

class _SpeedBar extends StatelessWidget {
  final double speed;
  const _SpeedBar({required this.speed});

  @override
  Widget build(BuildContext context) {
    final fraction = ((speed - 1.0) / 2.0).clamp(0.0, 1.0);
    final color = Color.lerp(const Color(0xFF00FF88), const Color(0xFFFF3333), fraction)!;

    return RotatedBox(
      quarterTurns: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SPEED',
            style: GoogleFonts.cinzel(fontSize: 8, color: Colors.white38, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
