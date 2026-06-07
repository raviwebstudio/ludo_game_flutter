# 🎮 Ludo Elite (Flutter)

A premium, highly polished Ludo game built with **Flutter** and **BLoC state management**. Renders a modern dark‑themed interface with glassmorphism, responsive controls, and a custom‑painted 3D dice.

---

## 🎯 Features

- **Local Multiplayer**: Play with 2, 3, or 4 players on a single device.
- **Custom-Painted 3D Dice**: Beautiful, dynamic 3D dice using Flutter's `CustomPaint` engine.
- **Persistent Stats**: Tracks player XP, levels, total games, wins, win rate, and win streak using SharedPreferences.
- **Audio & Haptics**: Full audio support for rolls, moves, captures, and victories with persisted toggles.
- **Dynamic Board Themes**: Swap board designs on the fly between **Neon Dark**, **Classic Board**, and **Royal Gold**.
- **PopScope System Back Handling**: Confirmation dialog prevents accidental exits from active matches.
- **BLoC Architecture**: Uses the BLoC pattern for predictable state transitions and scalable codebase.
- **Dependency Injection**: Integrated with `get_it` for clean service locator setups.

---

## 🚀 Technologies Used

- **Flutter**: Modern cross-platform framework.
- **Dart**: Programming language.
- **flutter_bloc**: State management.
- **shared_preferences**: Persistence engine for player statistics and configurations.
- **flutter_animate**: Micro-interactions and transitional animations.
- **audioplayers**: Sound effects playing.

---

## 🛠️ Folder Structure

```plaintext
lib/
├── core/
│   ├── constants/            # Thematic colors, text styles, and dimensions
│   ├── services/             # SoundManager, PlayerPrefs, HapticService
│   └── theme/                # Global MaterialApp AppTheme
├── data/
│   └── game_repository_impl.dart # Ludo logic (collisions, path generation, moves)
├── domain/
│   ├── models/               # BoardPosition, CaptureResult, Player/Token models
│   └── services/             # Safe zones definitions
├── features/
│   ├── game/                 # GamePlay screens and custom painters/widgets
│   ├── home/                 # Main Dashboard interface
│   ├── profile/              # Statistics, XP progress, and profile editing
│   ├── settings/             # Persistent configurations (sound, volume, haptics, theme)
│   └── splash/               # Animated splash screen with dynamic particles
├── presentation/
│   └── bloc/                 # Core game BLoC (State, Events, Bloc logic)
├── injection.dart            # Dependency injection configuration
└── main.dart                 # App initialization and routing
```

---

## 📦 Installation & Setup

1. Setup the Flutter SDK on your machine ([Flutter installation guide](https://docs.flutter.dev/get-started/install)).
2. Clone this repository:
   ```bash
   git clone <repo-url>
   ```
3. Navigate into the directory and pull dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🤝 License

This project is licensed under the MIT License.
