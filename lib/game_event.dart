// lib/bloc/game_event.dart

import 'package:equatable/equatable.dart';


abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

/// Start a new game
class GameStarted extends GameEvent {
  const GameStarted();
}

/// Pause / resume toggle
class GamePaused extends GameEvent {
  const GamePaused();
}

class GameResumed extends GameEvent {
  const GameResumed();
}

/// Called every frame by the game loop (~60fps)
class GameTicked extends GameEvent {
  final double dt; // delta-time in seconds
  const GameTicked(this.dt);
  @override
  List<Object?> get props => [dt];
}

/// Swipe / gesture events
class PlayerSwipedLeft extends GameEvent {
  const PlayerSwipedLeft();
}

class PlayerSwipedRight extends GameEvent {
  const PlayerSwipedRight();
}

class PlayerSwipedUp extends GameEvent {
  const PlayerSwipedUp();
}

class PlayerSwipedDown extends GameEvent {
  const PlayerSwipedDown();
}

/// Reset to home screen
class GameReset extends GameEvent {
  const GameReset();
}

/// High score loaded from storage
class HighScoreLoaded extends GameEvent {
  final int highScore;
  const HighScoreLoaded(this.highScore);
  @override
  List<Object?> get props => [highScore];
}
