// lib/screens/game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_bloc.dart';
import 'game_event.dart';
import 'game_hud.dart';
import 'game_models.dart';
import 'game_painter.dart';
import 'overlay_screens.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  Timer? _gameLoop;
  DateTime? _lastTick;

  // Swipe detection
  Offset? _swipeStart;
  static const double _minSwipeDistance = 30.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startGameLoop();
  }

  void _startGameLoop() {
    _lastTick = DateTime.now();
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastTick!).inMicroseconds / 1000000.0;
      _lastTick = now;
      context.read<GameBloc>().add(GameTicked(dt));
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    _swipeStart = d.globalPosition;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_swipeStart == null) return;
    final velocity = d.velocity.pixelsPerSecond;
    final bloc = context.read<GameBloc>();

    // Determine swipe direction by velocity
    if (velocity.distance < 200) return; // too slow

    final dx = velocity.dx.abs();
    final dy = velocity.dy.abs();

    if (dx > dy) {
      if (velocity.dx < 0) {
        bloc.add(const PlayerSwipedLeft());
      } else {
        bloc.add(const PlayerSwipedRight());
      }
    } else {
      if (velocity.dy < 0) {
        bloc.add(const PlayerSwipedUp());
      } else {
        bloc.add(const PlayerSwipedDown());
      }
    }
    _swipeStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          return Stack(
            children: [
              // ── Game Canvas ──────────────────────────────────────────────
              GestureDetector(
                onPanStart: _onPanStart,
                onPanEnd: _onPanEnd,
                onTap: () {
                  // Tap to jump (alternative control)
                  if (state.status == GameStatus.playing) {
                    context.read<GameBloc>().add(const PlayerSwipedUp());
                  }
                },
                child: CustomPaint(
                  painter: GamePainter(state),
                  size: Size.infinite,
                  child: const SizedBox.expand(),
                ),
              ),

              // ── HUD ──────────────────────────────────────────────────────
              if (state.status == GameStatus.playing || state.status == GameStatus.paused)
                const GameHud(),

              // ── Overlays ─────────────────────────────────────────────────
              if (state.status == GameStatus.idle)
                HomeOverlay(highScore: state.highScore),

              if (state.status == GameStatus.paused)
                const PauseOverlay(),

              if (state.status == GameStatus.gameOver)
                GameOverOverlay(
                  score: state.score,
                  highScore: state.highScore,
                  coins: state.coins,
                ),

              // ── Swipe indicators (brief visual feedback) ─────────────────
              if (state.status == GameStatus.playing)
                _SwipeHintLayer(state: state),
            ],
          );
        },
      ),
    );
  }
}

// ─── Swipe visual hint layer ─────────────────────────────────────────────────

class _SwipeHintLayer extends StatelessWidget {
  final GameState state;
  const _SwipeHintLayer({required this.state});

  @override
  Widget build(BuildContext context) {
    // Show brief arrow hints at the start
    if (state.distance < 5) {
      return Align(
        alignment: const Alignment(0, 0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ArrowHint(icon: Icons.arrow_back_ios_rounded, label: 'SWIPE\nLEFT'),
            _ArrowHint(icon: Icons.arrow_upward_rounded, label: 'SWIPE\nUP'),
            _ArrowHint(icon: Icons.arrow_forward_ios_rounded, label: 'SWIPE\nRIGHT'),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ArrowHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ArrowHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white30, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white24,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
