# 🎮 Ludo Game Built with Flutter

A beautifully designed **Ludo game** that brings the classic board game to life with **Flutter's Material Design**. This project features **smooth animations**, **multiplayer gameplay**, and **responsive controls**, ensuring a fun and engaging experience. It leverages **BLoC (Business Logic Component) state management**, **Dependency Injection**, and **Hive** for efficient data handling, making it a high-quality mobile gaming experience.

---

## 📱 Screenshots

_(Include your screenshots here to showcase different game modes, dice rolling, and player movements.)_

---

## 🎯 Features

- **Classic Ludo Gameplay**: Enjoy the traditional Ludo game with friends or AI.
- **Multiplayer Mode**: Challenge your friends in local multiplayer.
- **BLoC State Management**: Ensures smooth gameplay with structured logic.
- **Material Design**: Clean and modern UI adhering to Flutter's Material principles.
- **Animated Dice Roll**: Smooth animations make the gameplay visually appealing.
- **Turn-Based System**: Manages player turns efficiently to keep the game engaging.

---

## 🚀 Technologies Used

- **Flutter**: The cross-platform framework for mobile game development.
- **Dart**: The programming language used for Flutter apps.
- **BLoC**: Efficient state management for handling game logic.
- **Hive**: Fast, lightweight local database for storing game history.
- **Dependency Injection**: For modular and scalable code structure.

---

## 📦 Installation

1. Ensure Flutter is installed. Follow the guide [here](https://docs.flutter.dev/get-started/install).
2. Clone this repository:
   ```bash
   git clone https://github.com/arpit24sahu/ludo-game.git
   ```
3. Navigate to the project directory:
   ```bash
   cd ludo-game
   ```
4. Fetch dependencies:
   ```bash
   flutter pub get
   ```
5. Run the app:
   ```bash
   flutter run
   ```

---

## 🛠️ How It Works

1. **Game Board**: The Ludo board with four colored zones is displayed.
2. **Dice Rolling**: Players take turns rolling a dice, determining movement.
3. **Pawn Movement**: Pawns move based on dice results and follow Ludo rules.
4. **Capturing Opponents**: Send opponent pawns back to their base.
5. **Winning Condition**: Move all pawns to the center home to win the game.
6. **Game Save**: The game progress is automatically stored using Hive.

---

## 👤 Folder Structure

```plaintext
ludo-game-flutter/
├── lib/
│   ├── data/                          # Game logic and repository
│   ├── domain/                     # Data models
│   ├── presentation/            # UI files
│   ├── ├── bloc/                   # Bloc Files
│   ├── ├── painters/            # Board painter
│   ├── ├── screens/            # The screens
│   ├── ├── widgets/            # Various widgets
│   ├── main.dart                  # Main entry point
│   ├── injection.dart            # Dependency injection setup
└── pubspec.yaml                # Project dependencies
```

---

## 🧐 Future Improvements

- **Online Multiplayer and AI**: Play Ludo with friends across the world. Play with AI when no one is there.
- **Custom Rules Mode**: Modify Ludo rules for a personalized experience.
- **Leaderboards & Achievements**: Track scores and unlock achievements.
- **Hive Storage**: Saves game progress and tracks previous match stats.

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues and pull requests to improve the game.

---

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
