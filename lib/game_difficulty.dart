import 'package:shared_preferences/shared_preferences.dart';

enum GameDifficulty {
  easy('Easy', 5, 3),
  medium('Medium', 6, 3),
  hard('Hard', 8, 4);

  const GameDifficulty(this.label, this.columns, this.rows);

  static const prefsKey = 'mosaic_game_difficulty';

  final String label;
  final int columns;
  final int rows;

  int get cellCount => columns * rows;

  static GameDifficulty fromName(String? name) {
    return GameDifficulty.values.firstWhere(
      (difficulty) => difficulty.name == name,
      orElse: () => GameDifficulty.hard,
    );
  }

  static Future<GameDifficulty> load() async {
    final prefs = await SharedPreferences.getInstance();
    return fromName(prefs.getString(prefsKey));
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, name);
  }
}
