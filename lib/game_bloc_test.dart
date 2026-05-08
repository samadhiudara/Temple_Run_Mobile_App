// test/bloc/game_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_bloc.dart';
import 'game_event.dart';
import 'game_models.dart';


void main() {
  group('GameBloc', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = GameBloc();
    });

    tearDown(() {
      gameBloc.close();
    });

    test('initial state is idle', () {
      expect(gameBloc.state.status, GameStatus.idle);
    });

    blocTest<GameBloc, GameState>(
      'emits playing status when GameStarted',
      build: () => GameBloc(),
      act: (bloc) => bloc.add(const GameStarted()),
      expect: () => [
        predicate<GameState>((s) => s.status == GameStatus.playing),
      ],
    );

    blocTest<GameBloc, GameState>(
      'pauses game when GamePaused during play',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const GamePaused());
      },
      expect: () => [
        predicate<GameState>((s) => s.status == GameStatus.playing),
        predicate<GameState>((s) => s.status == GameStatus.paused),
      ],
    );

    blocTest<GameBloc, GameState>(
      'resumes game when GameResumed during pause',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const GamePaused());
        bloc.add(const GameResumed());
      },
      expect: () => [
        predicate<GameState>((s) => s.status == GameStatus.playing),
        predicate<GameState>((s) => s.status == GameStatus.paused),
        predicate<GameState>((s) => s.status == GameStatus.playing),
      ],
    );

    blocTest<GameBloc, GameState>(
      'player moves left from center',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const PlayerSwipedLeft());
      },
      expect: () => [
        predicate<GameState>((s) => s.player.lane == LanePosition.center),
        predicate<GameState>((s) => s.player.lane == LanePosition.left),
      ],
    );

    blocTest<GameBloc, GameState>(
      'player moves right from center',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const PlayerSwipedRight());
      },
      expect: () => [
        predicate<GameState>((s) => s.player.lane == LanePosition.center),
        predicate<GameState>((s) => s.player.lane == LanePosition.right),
      ],
    );

    blocTest<GameBloc, GameState>(
      'player cannot move left of leftmost lane',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const PlayerSwipedLeft());
        bloc.add(const PlayerSwipedLeft());
      },
      expect: () => [
        predicate<GameState>((s) => s.player.lane == LanePosition.center),
        predicate<GameState>((s) => s.player.lane == LanePosition.left),
        predicate<GameState>((s) => s.player.lane == LanePosition.left),
      ],
    );

    blocTest<GameBloc, GameState>(
      'player jumps when swiping up on ground',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const PlayerSwipedUp());
      },
      expect: () => [
        predicate<GameState>((s) => s.player.state == PlayerState.running),
        predicate<GameState>((s) => s.player.state == PlayerState.jumping),
      ],
    );

    blocTest<GameBloc, GameState>(
      'resets to idle on GameReset',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const GameReset());
      },
      expect: () => [
        predicate<GameState>((s) => s.status == GameStatus.playing),
        predicate<GameState>((s) => s.status == GameStatus.idle),
      ],
    );

    blocTest<GameBloc, GameState>(
      'high score is loaded correctly',
      build: () => GameBloc(),
      act: (bloc) => bloc.add(const HighScoreLoaded(9999)),
      expect: () => [
        predicate<GameState>((s) => s.highScore == 9999),
      ],
    );

    blocTest<GameBloc, GameState>(
      'score increases on game tick during play',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const GameStarted());
        bloc.add(const GameTicked(0.016));
      },
      expect: () => [
        predicate<GameState>((s) => s.status == GameStatus.playing),
        predicate<GameState>((s) => s.score > 0),
      ],
    );
  });
}
