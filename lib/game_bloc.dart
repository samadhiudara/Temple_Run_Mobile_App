// lib/bloc/game_bloc.dart

import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_event.dart';
import 'game_models.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const double kGravity = 28.0;
const double kJumpVelocity = 10.0;
const double kBaseSpeed = 6.0;
const double kMaxSpeed = 18.0;
const double kSpeedIncrement = 0.0015;
const double kObstacleSpawnInterval = 1.8; // seconds between spawns
const double kObstacleZFar = 1.0;
const double kObstacleZNear = 0.0;
const double kCollisionZone = 0.08;
const double kCoinMagnetRange = 0.25;
const double kSlideHeight = -0.3;
const double kJumpHeight = 0.6;
const double kPowerupDuration = 8.0;

// ─── Game BLoC ───────────────────────────────────────────────────────────────

class GameBloc extends Bloc<GameEvent, GameState> {
  final Random _rng = Random();
  double _spawnTimer = 0.0;
  int _obstacleCounter = 0;
  int _trackCounter = 0;

  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<GamePaused>(_onGamePaused);
    on<GameResumed>(_onGameResumed);
    on<GameTicked>(_onGameTicked);
    on<PlayerSwipedLeft>(_onSwipeLeft);
    on<PlayerSwipedRight>(_onSwipeRight);
    on<PlayerSwipedUp>(_onSwipeUp);
    on<PlayerSwipedDown>(_onSwipeDown);
    on<GameReset>(_onGameReset);
    on<HighScoreLoaded>(_onHighScoreLoaded);

    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final hs = prefs.getInt('high_score') ?? 0;
    add(HighScoreLoaded(hs));
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('high_score', score);
  }

  // ─── Event Handlers ────────────────────────────────────────────────────────

  void _onHighScoreLoaded(HighScoreLoaded event, Emitter<GameState> emit) {
    emit(state.copyWith(highScore: event.highScore));
  }

  void _onGameStarted(GameStarted event, Emitter<GameState> emit) {
    _spawnTimer = 0.0;
    _obstacleCounter = 0;
    _trackCounter = 0;

    final initialTracks = List.generate(
      5,
      (i) => TrackSegment(
        id: 'track_${_trackCounter++}',
        zStart: i * 0.2,
        type: TrackType.straight,
      ),
    );

    emit(GameState(
      status: GameStatus.playing,
      player: const Player(),
      obstacles: [],
      trackSegments: initialTracks,
      highScore: state.highScore,
    ));
  }

  void _onGamePaused(GamePaused event, Emitter<GameState> emit) {
    if (state.status == GameStatus.playing) {
      emit(state.copyWith(status: GameStatus.paused));
    }
  }

  void _onGameResumed(GameResumed event, Emitter<GameState> emit) {
    if (state.status == GameStatus.paused) {
      emit(state.copyWith(status: GameStatus.playing));
    }
  }

  void _onGameReset(GameReset event, Emitter<GameState> emit) {
    emit(GameState(highScore: state.highScore));
  }

  void _onSwipeLeft(PlayerSwipedLeft event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final player = state.player;
    if (player.state == PlayerState.dead) return;

    final newLane = switch (player.lane) {
      LanePosition.right => LanePosition.center,
      LanePosition.center => LanePosition.left,
      LanePosition.left => LanePosition.left,
    };
    emit(state.copyWith(player: player.copyWith(lane: newLane)));
  }

  void _onSwipeRight(PlayerSwipedRight event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final player = state.player;
    if (player.state == PlayerState.dead) return;

    final newLane = switch (player.lane) {
      LanePosition.left => LanePosition.center,
      LanePosition.center => LanePosition.right,
      LanePosition.right => LanePosition.right,
    };
    emit(state.copyWith(player: player.copyWith(lane: newLane)));
  }

  void _onSwipeUp(PlayerSwipedUp event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final player = state.player;
    if (player.state == PlayerState.dead) return;

    // Only jump if on ground
    if (player.yOffset <= 0.01 && player.state != PlayerState.jumping) {
      emit(state.copyWith(
        player: player.copyWith(
          state: PlayerState.jumping,
          jumpVelocity: kJumpVelocity,
        ),
      ));
    }
  }

  void _onSwipeDown(PlayerSwipedDown event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    final player = state.player;
    if (player.state == PlayerState.dead) return;

    if (player.state == PlayerState.jumping) {
      // Fast fall
      emit(state.copyWith(
        player: player.copyWith(jumpVelocity: -kJumpVelocity),
      ));
    } else if (player.state != PlayerState.sliding) {
      // Slide on ground
      emit(state.copyWith(
        player: player.copyWith(state: PlayerState.sliding),
      ));
      // Auto-stand after 0.6s is handled in tick via slideTimer below
    }
  }

  // ─── Main Game Tick ────────────────────────────────────────────────────────

  void _onGameTicked(GameTicked event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;

    final dt = event.dt.clamp(0.0, 0.05); // cap to avoid huge jumps
    final newSpeed = (state.gameSpeed + kSpeedIncrement * dt * 60).clamp(1.0, kMaxSpeed / kBaseSpeed);
    final actualSpeed = kBaseSpeed * newSpeed;

    // ── Physics ──
    var player = _updatePlayerPhysics(state.player, dt);

    // ── Slide auto-recovery ──
    // Slide lasts ~0.6 s; we track it via a pseudo-timer embedded in yOffset sign trick
    // Instead we use a simple flag – if sliding and yOffset == 0, the player stays slide
    // We'll recover after a fixed duration using a counter embedded in animationFrame as timer
    if (player.state == PlayerState.sliding) {
      final slideTimer = player.animationFrame + dt;
      if (slideTimer >= 0.6) {
        player = player.copyWith(state: PlayerState.running, animationFrame: 0.0);
      } else {
        player = player.copyWith(animationFrame: slideTimer);
      }
    } else if (player.state != PlayerState.jumping) {
      // cycle run animation
      player = player.copyWith(
        animationFrame: (player.animationFrame + dt * 8) % (2 * pi),
      );
    }

    // ── Obstacles ──
    _spawnTimer += dt;
    var obstacles = _moveObstacles(state.obstacles, actualSpeed, dt);
    if (_spawnTimer >= kObstacleSpawnInterval / newSpeed) {
      _spawnTimer = 0.0;
      obstacles = [...obstacles, ..._spawnObstacleGroup()];
    }
    // Remove off-screen
    obstacles = obstacles.where((o) => o.zPosition > -0.1).toList();

    // ── Collect coins / powerups ──
    var coins = state.coins;
    var score = state.score + (actualSpeed * dt * 10).toInt();
    var combo = state.combo;
    var activePowerup = state.activePowerup;
    var powerupTimer = state.powerupTimer;
    var player2 = player;
    bool clearPowerup = false;

    // Powerup timer countdown
    if (activePowerup != null) {
      powerupTimer -= dt;
      if (powerupTimer <= 0) {
        clearPowerup = true;
        player2 = player2.copyWith(hasShield: false, hasMagnet: false);
      }
    }

    final updatedObstacles = <Obstacle>[];
    for (final obs in obstacles) {
      if (obs.collected) {
        updatedObstacles.add(obs);
        continue;
      }
      if (_isInCollectRange(obs, player2)) {
        if (obs.isCoin) {
          coins++;
          score += 50 + (combo * 10);
          combo++;
          updatedObstacles.add(obs.copyWith(collected: true));
          continue;
        }
        if (obs.isPowerup) {
          final pt = obs.powerupType!;
          activePowerup = pt;
          powerupTimer = kPowerupDuration;
          clearPowerup = false;
          if (pt == PowerupType.shield) player2 = player2.copyWith(hasShield: true);
          if (pt == PowerupType.magnet) player2 = player2.copyWith(hasMagnet: true);
          updatedObstacles.add(obs.copyWith(collected: true));
          continue;
        }
      } else {
        combo = 0; // reset combo if passed an item without collecting
      }

      // Magnet attraction for coins
      if (player2.hasMagnet && obs.isCoin && !obs.collected) {
        if (_isInMagnetRange(obs, player2)) {
          coins++;
          score += 50;
          updatedObstacles.add(obs.copyWith(collected: true));
          continue;
        }
      }

      updatedObstacles.add(obs);
    }

    // ── Collision detection ──
    var lives = state.lives;
    var gameStatus = state.status;
    bool hitDetected = false;
    final collisionObstacles = updatedObstacles.map((obs) => obs).toList();

    for (final obs in collisionObstacles) {
      if (!obs.isBarrier || obs.collected) continue;
      if (!_isColliding(obs, player2)) continue;

      hitDetected = true;
      if (player2.hasShield) {
        // Shield absorbs one hit
        player2 = player2.copyWith(hasShield: false);
        clearPowerup = true;
        activePowerup = null;
        break;
      }

      lives--;
      if (lives <= 0) {
        player2 = player2.copyWith(state: PlayerState.dead);
        gameStatus = GameStatus.gameOver;
        final newHighScore = max(score, state.highScore);
        if (newHighScore > state.highScore) _saveHighScore(newHighScore);
      } else {
        // Stumble animation — brief invincibility via shield
        player2 = player2.copyWith(hasShield: true);
        activePowerup = PowerupType.shield;
        powerupTimer = 1.5; // 1.5s invincibility
        clearPowerup = false;
      }
      break;
    }

    // ── Track scrolling ──
    final distance = state.distance + actualSpeed * dt;

    // ── Emit new state ──
    final newHighScore = max(score, state.highScore);

    emit(state.copyWith(
      status: gameStatus,
      player: player2,
      obstacles: updatedObstacles,
      score: score,
      coins: coins,
      highScore: newHighScore,
      gameSpeed: newSpeed,
      distance: distance,
      lives: lives,
      combo: combo,
      powerupTimer: powerupTimer > 0 ? powerupTimer : 0.0,
      activePowerup: activePowerup,
      clearPowerup: clearPowerup,
    ));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Player _updatePlayerPhysics(Player player, double dt) {
    if (player.state != PlayerState.jumping) return player;

    final newVelocity = player.jumpVelocity - kGravity * dt;
    final newYOffset = (player.yOffset + player.jumpVelocity * dt).clamp(-0.5, kJumpHeight);

    if (newYOffset <= 0.0 && newVelocity < 0) {
      return player.copyWith(
        state: PlayerState.running,
        yOffset: 0.0,
        jumpVelocity: 0.0,
      );
    }

    return player.copyWith(
      yOffset: newYOffset,
      jumpVelocity: newVelocity,
    );
  }

  List<Obstacle> _moveObstacles(List<Obstacle> obstacles, double speed, double dt) {
    return obstacles.map((obs) {
      final newZ = obs.zPosition - speed * dt * 0.08;
      return obs.copyWith(zPosition: newZ);
    }).toList();
  }

  List<Obstacle> _spawnObstacleGroup() {
    final List<Obstacle> spawned = [];
    final pattern = _rng.nextInt(8);

    switch (pattern) {
      case 0: // single barrier in random lane
        spawned.add(_makeBarrier(_randomLane(), kObstacleZFar));
        break;
      case 1: // two barriers
        final lanes = _twoRandomLanes();
        for (final lane in lanes) {
          spawned.add(_makeBarrier(lane, kObstacleZFar));
        }
        break;
      case 2: // low barrier (must slide)
        spawned.add(_makeLowBarrier(_randomLane(), kObstacleZFar));
        break;
      case 3: // coin row
        for (final lane in LanePosition.values) {
          spawned.add(_makeCoin(lane, kObstacleZFar));
          spawned.add(_makeCoin(lane, kObstacleZFar + 0.05));
        }
        break;
      case 4: // coin arc in one lane
        final lane = _randomLane();
        for (int i = 0; i < 5; i++) {
          spawned.add(_makeCoin(lane, kObstacleZFar + i * 0.04));
        }
        break;
      case 5: // powerup
        spawned.add(_makePowerup(_randomLane(), kObstacleZFar));
        break;
      case 6: // barrier + coins on other lanes
        final bLane = _randomLane();
        spawned.add(_makeBarrier(bLane, kObstacleZFar));
        for (final lane in LanePosition.values) {
          if (lane != bLane) {
            spawned.add(_makeCoin(lane, kObstacleZFar + 0.05));
          }
        }
        break;
      case 7: // alternating barriers
        spawned.add(_makeBarrier(LanePosition.left, kObstacleZFar));
        spawned.add(_makeBarrier(LanePosition.right, kObstacleZFar + 0.1));
        break;
    }

    return spawned;
  }

  Obstacle _makeBarrier(LanePosition lane, double z) => Obstacle(
        id: 'obs_${_obstacleCounter++}',
        type: ObstacleType.barrier,
        lane: lane,
        zPosition: z,
      );

  Obstacle _makeLowBarrier(LanePosition lane, double z) => Obstacle(
        id: 'obs_${_obstacleCounter++}',
        type: ObstacleType.lowBarrier,
        lane: lane,
        zPosition: z,
      );

  Obstacle _makeCoin(LanePosition lane, double z) => Obstacle(
        id: 'coin_${_obstacleCounter++}',
        type: ObstacleType.coin,
        lane: lane,
        zPosition: z,
      );

  Obstacle _makePowerup(LanePosition lane, double z) {
    final types = PowerupType.values;
    return Obstacle(
      id: 'pow_${_obstacleCounter++}',
      type: ObstacleType.powerup,
      lane: lane,
      zPosition: z,
      powerupType: types[_rng.nextInt(types.length)],
    );
  }

  LanePosition _randomLane() {
    return LanePosition.values[_rng.nextInt(3)];
  }

  List<LanePosition> _twoRandomLanes() {
    final all = [...LanePosition.values];
    all.shuffle(_rng);
    return all.take(2).toList();
  }

  bool _isInCollectRange(Obstacle obs, Player player) {
    if (obs.zPosition > 0.12 || obs.zPosition < -0.05) return false;
    return obs.lane == player.lane;
  }

  bool _isInMagnetRange(Obstacle obs, Player player) {
    if (obs.zPosition > kCoinMagnetRange || obs.zPosition < -0.05) return false;
    return true; // magnet pulls coins from all lanes when close
  }

  bool _isColliding(Obstacle obs, Player player) {
    if (obs.lane != player.lane) return false;
    if (obs.zPosition > kCollisionZone * 2 || obs.zPosition < -0.02) return false;

    // Barrier collision: player must be on ground
    if (obs.type == ObstacleType.barrier) {
      return player.yOffset < 0.25; // must jump over
    }
    // Low barrier: player must slide
    if (obs.type == ObstacleType.lowBarrier) {
      return player.state != PlayerState.sliding;
    }
    return false;
  }
}
