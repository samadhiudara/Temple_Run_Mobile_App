🏛️ Temple Runner — Flutter BLoC Game
A fully-featured Temple Run-style endless runner built with Flutter and the BLoC state management pattern.
---
🎮 Gameplay
Gesture	Action
Swipe Left	Move to left lane
Swipe Right	Move to right lane
Swipe Up	Jump over barriers
Swipe Down	Slide under low barriers
Tap	Quick jump
Obstacles
Stone Pillar — Jump over it
Spike Gate (low) — Slide under it
Gold Coin — Collect for points & combos
Powerup Orb — Shield / Magnet / Speed Boost
Powerups
Icon	Effect
🛡️ Shield	Absorbs one hit
🧲 Magnet	Attracts nearby coins automatically
⚡ Speed Boost	Temporary invulnerability
---
🏗️ Architecture
```
lib/
├── main.dart                  # App entry, BlocProvider
├── bloc/
│   ├── game_bloc.dart         # Core game logic & physics
│   └── game_event.dart        # All game events
├── models/
│   └── game_models.dart       # Player, Obstacle, GameState, enums
├── screens/
│   ├── game_screen.dart       # Main screen, gesture detector, game loop
│   └── overlay_screens.dart   # Home, GameOver, Pause overlays
└── widgets/
    ├── game_painter.dart      # CustomPainter — renders all game visuals
    └── game_hud.dart          # Score, lives, coins, powerup timer
```
BLoC Pattern
```
UI (GestureDetector)
    │
    ▼ Events
GameBloc
    │  • GameStarted
    │  • GameTicked(dt)       ← 60fps timer
    │  • PlayerSwipedLeft/Right/Up/Down
    │  • GamePaused/Resumed
    │  • GameReset
    │
    ▼ GameState (immutable)
CustomPainter / Widgets
```
Game Loop
A `Timer.periodic(16ms)` fires `GameTicked(dt)` events. The BLoC handles:
Physics — jump arc with gravity, slide recovery
Speed increase — exponential ramp up to max speed
Obstacle spawning — 8 randomized pattern templates
Collision detection — per-lane z-depth proximity checks
Coin/powerup collection — magnet radius attraction
Score & combo — distance-based + coin bonuses
---
🚀 Getting Started
```bash
# Install dependencies
flutter pub get

# Run on device
flutter run

# Run tests
flutter test

# Build release APK
flutter build apk --release
```
Requirements
Flutter 3.10+
Dart 3.0+
Android / iOS device or emulator
---
📦 Dependencies
Package	Purpose
`flutter_bloc`	State management
`equatable`	Value equality for states
`shared_preferences`	High score persistence
`google_fonts`	Cinzel typeface
---
🎨 Visual Features
Procedural track with perspective projection (trapezoid lanes)
Temple silhouette background with tower art
Animated torches with flickering flame effect
Spinning coin animation with metallic shader
Character with run cycle, jump, and slide poses
Shield aura pulsing around protected player
Depth-scaled obstacles that grow as they approach
Star field night sky background
Fog overlay at horizon for depth feel
---
🧪 Tests
Located in `test/game_bloc_test.dart`. Covers:
Initial state
Start/pause/resume/reset
Lane switching edge cases
Jump mechanics
Score increment on tick
High score loading