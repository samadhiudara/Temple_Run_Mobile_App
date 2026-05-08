import 'package:equatable/equatable.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum PlayerState { running, jumping, sliding, turning, dead }

enum LanePosition { left, center, right }

enum ObstacleType { barrier, lowBarrier, coin, powerup }

enum PowerupType { shield, magnet, speedBoost }

enum GameStatus { idle, playing, paused, gameOver }

// ─── Player Model ────────────────────────────────────────────────────────────

class Player extends Equatable {
  final LanePosition lane;
  final PlayerState state;
  final double yOffset; // vertical position (for jump/slide)
  final double jumpVelocity;
  final bool hasShield;
  final bool hasMagnet;
  final double animationFrame;

  const Player({
    this.lane = LanePosition.center,
    this.state = PlayerState.running,
    this.yOffset = 0.0,
    this.jumpVelocity = 0.0,
    this.hasShield = false,
    this.hasMagnet = false,
    this.animationFrame = 0.0,
  });

  Player copyWith({
    LanePosition? lane,
    PlayerState? state,
    double? yOffset,
    double? jumpVelocity,
    bool? hasShield,
    bool? hasMagnet,
    double? animationFrame,
  }) {
    return Player(
      lane: lane ?? this.lane,
      state: state ?? this.state,
      yOffset: yOffset ?? this.yOffset,
      jumpVelocity: jumpVelocity ?? this.jumpVelocity,
      hasShield: hasShield ?? this.hasShield,
      hasMagnet: hasMagnet ?? this.hasMagnet,
      animationFrame: animationFrame ?? this.animationFrame,
    );
  }

  @override
  List<Object?> get props => [
        lane,
        state,
        yOffset,
        jumpVelocity,
        hasShield,
        hasMagnet,
        animationFrame,
      ];
}

// ─── Obstacle Model ──────────────────────────────────────────────────────────

class Obstacle extends Equatable {
  final String id;
  final ObstacleType type;
  final LanePosition lane;
  final double zPosition; // 0 = player, 1 = far
  final PowerupType? powerupType;
  final bool collected;

  const Obstacle({
    required this.id,
    required this.type,
    required this.lane,
    required this.zPosition,
    this.powerupType,
    this.collected = false,
  });

  Obstacle copyWith({
    double? zPosition,
    bool? collected,
  }) {
    return Obstacle(
      id: id,
      type: type,
      lane: lane,
      zPosition: zPosition ?? this.zPosition,
      powerupType: powerupType,
      collected: collected ?? this.collected,
    );
  }

  bool get isCoin => type == ObstacleType.coin;
  bool get isPowerup => type == ObstacleType.powerup;
  bool get isBarrier => type == ObstacleType.barrier || type == ObstacleType.lowBarrier;

  @override
  List<Object?> get props => [id, type, lane, zPosition, powerupType, collected];
}

// ─── Track Segment Model ─────────────────────────────────────────────────────

class TrackSegment extends Equatable {
  final String id;
  final double zStart;
  final TrackType type;

  const TrackSegment({
    required this.id,
    required this.zStart,
    required this.type,
  });

  @override
  List<Object?> get props => [id, zStart, type];
}

enum TrackType { straight, leftCurve, rightCurve }

// ─── Game State ──────────────────────────────────────────────────────────────

class GameState extends Equatable {
  final GameStatus status;
  final Player player;
  final List<Obstacle> obstacles;
  final List<TrackSegment> trackSegments;
  final int score;
  final int coins;
  final int highScore;
  final double gameSpeed;
  final double distance;
  final int lives;
  final int combo;
  final double powerupTimer;
  final PowerupType? activePowerup;

  const GameState({
    this.status = GameStatus.idle,
    this.player = const Player(),
    this.obstacles = const [],
    this.trackSegments = const [],
    this.score = 0,
    this.coins = 0,
    this.highScore = 0,
    this.gameSpeed = 1.0,
    this.distance = 0.0,
    this.lives = 3,
    this.combo = 0,
    this.powerupTimer = 0.0,
    this.activePowerup,
  });

  GameState copyWith({
    GameStatus? status,
    Player? player,
    List<Obstacle>? obstacles,
    List<TrackSegment>? trackSegments,
    int? score,
    int? coins,
    int? highScore,
    double? gameSpeed,
    double? distance,
    int? lives,
    int? combo,
    double? powerupTimer,
    PowerupType? activePowerup,
    bool clearPowerup = false,
  }) {
    return GameState(
      status: status ?? this.status,
      player: player ?? this.player,
      obstacles: obstacles ?? this.obstacles,
      trackSegments: trackSegments ?? this.trackSegments,
      score: score ?? this.score,
      coins: coins ?? this.coins,
      highScore: highScore ?? this.highScore,
      gameSpeed: gameSpeed ?? this.gameSpeed,
      distance: distance ?? this.distance,
      lives: lives ?? this.lives,
      combo: combo ?? this.combo,
      powerupTimer: powerupTimer ?? this.powerupTimer,
      activePowerup: clearPowerup ? null : (activePowerup ?? this.activePowerup),
    );
  }

  @override
  List<Object?> get props => [
        status,
        player,
        obstacles,
        trackSegments,
        score,
        coins,
        highScore,
        gameSpeed,
        distance,
        lives,
        combo,
        powerupTimer,
        activePowerup,
      ];
}
