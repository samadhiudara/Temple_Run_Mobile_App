// lib/screens/overlay_screens.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_bloc.dart';
import 'game_event.dart';


// ─── Home Screen Overlay ──────────────────────────────────────────────────────

class HomeOverlay extends StatefulWidget {
  final int highScore;
  const HomeOverlay({super.key, required this.highScore});

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0A1A), Color(0xFF1A0A2E), Color(0xFF2D0A0A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Temple icon
            AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, _) => Transform.scale(
                scale: _scale.value,
                child: _TempleIcon(glow: _glow.value),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'TEMPLE',
              style: GoogleFonts.cinzel(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFD4A832),
                letterSpacing: 8,
                shadows: const [
                  Shadow(color: Color(0xFFFF6600), blurRadius: 20),
                  Shadow(color: Color(0xFF000000), blurRadius: 4),
                ],
              ),
            ),
            Text(
              'RUNNER',
              style: GoogleFonts.cinzel(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFD4A832).withOpacity(0.7),
                letterSpacing: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4A832).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // High score
            if (widget.highScore > 0) ...[
              Text(
                'BEST  ${widget.highScore.toString().padLeft(6, '0')}',
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  color: Colors.white54,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Play button
            _GoldButton(
              label: 'RUN!',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.read<GameBloc>().add(const GameStarted()),
            ),
            const SizedBox(height: 40),
            // Controls hint
            _ControlsHint(),
          ],
        ),
      ),
    );
  }
}

class _TempleIcon extends StatelessWidget {
  final double glow;
  const _TempleIcon({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A832).withOpacity(0.4 * glow),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: CustomPaint(painter: _TemplePainter(glow: glow)),
    );
  }
}

class _TemplePainter extends CustomPainter {
  final double glow;
  _TemplePainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background circle
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3D1A0A), Color(0xFF1A0A0A)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width / 2)),
    );

    // Temple shape
    final paint = Paint()
      ..color = Color.lerp(const Color(0xFFD4A832), const Color(0xFFFFE566), glow)!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx - 35, cy + 30);
    path.lineTo(cx - 35, cy - 5);
    path.lineTo(cx - 20, cy - 5);
    path.lineTo(cx - 20, cy - 25);
    path.lineTo(cx - 10, cy - 25);
    path.lineTo(cx - 10, cy - 45);
    path.lineTo(cx, cy - 58);
    path.lineTo(cx + 10, cy - 45);
    path.lineTo(cx + 10, cy - 25);
    path.lineTo(cx + 20, cy - 25);
    path.lineTo(cx + 20, cy - 5);
    path.lineTo(cx + 35, cy - 5);
    path.lineTo(cx + 35, cy + 30);
    path.close();
    canvas.drawPath(path, paint);

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 18), width: 18, height: 24),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFF1A0A0A),
    );

    // Glow halo
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2 - 4,
      Paint()
        ..color = const Color(0xFFD4A832).withOpacity(0.15 * glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_TemplePainter old) => old.glow != glow;
}

class _ControlsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            'HOW TO PLAY',
            style: GoogleFonts.cinzel(fontSize: 11, color: Colors.white38, letterSpacing: 4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HintItem(icon: Icons.swipe_left, label: 'Move Left'),
              const SizedBox(width: 20),
              _HintItem(icon: Icons.swipe_right, label: 'Move Right'),
              const SizedBox(width: 20),
              _HintItem(icon: Icons.swipe_up, label: 'Jump'),
              const SizedBox(width: 20),
              _HintItem(icon: Icons.swipe_down, label: 'Slide'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HintItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4A832), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cinzel(fontSize: 9, color: Colors.white54),
        ),
      ],
    );
  }
}

// ─── Game Over Overlay ────────────────────────────────────────────────────────

class GameOverOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final int coins;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.coins,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideUp = Tween(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewRecord = widget.score >= widget.highScore && widget.score > 0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => Opacity(
        opacity: _fadeIn.value,
        child: Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D0A1A).withOpacity(0.95),
                  const Color(0xFF2D0A0A).withOpacity(0.95),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Death icon
                  Icon(
                    Icons.dangerous_rounded,
                    size: 72,
                    color: const Color(0xFFFF3333).withOpacity(0.8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GAME OVER',
                    style: GoogleFonts.cinzel(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF3333),
                      letterSpacing: 6,
                      shadows: const [Shadow(color: Color(0xFFFF0000), blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Score card
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4A832).withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        if (isNewRecord) ...[
                          Text(
                            '✦ NEW RECORD ✦',
                            style: GoogleFonts.cinzel(
                              fontSize: 14,
                              color: const Color(0xFFFFD700),
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _StatRow(
                          label: 'SCORE',
                          value: widget.score.toString().padLeft(6, '0'),
                          color: const Color(0xFFD4A832),
                          large: true,
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        _StatRow(
                          label: 'BEST',
                          value: widget.highScore.toString().padLeft(6, '0'),
                          color: Colors.white60,
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          label: 'COINS',
                          value: widget.coins.toString(),
                          color: const Color(0xFFFFD700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Buttons
                  _GoldButton(
                    label: 'PLAY AGAIN',
                    icon: Icons.replay_rounded,
                    onTap: () => context.read<GameBloc>().add(const GameStarted()),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => context.read<GameBloc>().add(const GameReset()),
                    child: Text(
                      'MAIN MENU',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        color: Colors.white38,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;
  const _StatRow({required this.label, required this.value, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cinzel(fontSize: large ? 14 : 12, color: Colors.white38, letterSpacing: 3),
        ),
        Text(
          value,
          style: GoogleFonts.cinzel(
            fontSize: large ? 32 : 18,
            fontWeight: large ? FontWeight.w900 : FontWeight.bold,
            color: color,
            letterSpacing: large ? 4 : 2,
          ),
        ),
      ],
    );
  }
}

// ─── Pause Overlay ────────────────────────────────────────────────────────────

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                size: 80, color: Color(0xFFD4A832)),
            const SizedBox(height: 16),
            Text(
              'PAUSED',
              style: GoogleFonts.cinzel(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFD4A832),
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 40),
            _GoldButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.read<GameBloc>().add(const GameResumed()),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<GameBloc>().add(const GameReset()),
              child: Text(
                'QUIT',
                style: GoogleFonts.cinzel(fontSize: 16, color: Colors.white38, letterSpacing: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Gold Button ───────────────────────────────────────────────────────

class _GoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GoldButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.94).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4A832), Color(0xFFFFE566), Color(0xFFD4A832)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Color(0xFFD4A832), blurRadius: 20, spreadRadius: 2, offset: Offset(0, 4)),
              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: const Color(0xFF1A0A00), size: 26),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A0A00),
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
