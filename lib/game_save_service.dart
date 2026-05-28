import 'package:shared_preferences/shared_preferences.dart';

import 'game_difficulty.dart';
import 'story_scenes_screen.dart';

class GameSaveService {
  static const slotCount = 6;
  static const _completedKey = 'mosaic_game_completed';
  static const _sequenceKey = 'mosaic_game_pattern_order';
  static const progressKey = 'mosaic_game_target_index';
  static const currentSceneKey = 'mosaic_game_current_scene_index';
  static const _activeSlotKey = 'mosaic_active_save_slot';

  static const _saveExistsKey = 'mosaic_save_exists';
  static const _saveCompletedKey = 'mosaic_save_completed';
  static const _saveCompletedPagesKey = 'mosaic_save_completed_pages';
  static const _saveCurrentSceneKey = 'mosaic_save_current_scene';
  static const _saveDifficultyKey = 'mosaic_save_difficulty';
  static const _saveSequenceKey = 'mosaic_save_pattern_order';
  static const _saveProgressKey = 'mosaic_save_target_index';
  static const _saveTimestampKey = 'mosaic_save_timestamp';

  static List<String> createSequence() {
    final indices = [0, 1, 2, 3, 4, 5, 6]..shuffle();
    return indices.map((index) => index.toString()).toList();
  }

  static Future<void> startNewGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSlotKey);
    await prefs.setBool(_completedKey, false);
    await prefs.setInt(mosaicCompletedGamePagesKey, 0);
    await prefs.setInt(progressKey, 1);
    await prefs.setInt(currentSceneKey, 0);
    await prefs.setStringList(_sequenceKey, createSequence());
  }

  static Future<void> resetGridSequence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, false);
    await prefs.setInt(mosaicCompletedGamePagesKey, 0);
    await prefs.setInt(progressKey, 1);
    await prefs.setStringList(_sequenceKey, createSequence());
  }

  static Future<void> resetCurrentSceneSequence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, false);
    await prefs.setInt(progressKey, 1);
    await prefs.setStringList(_sequenceKey, createSequence());
  }

  static String _slotKey(String key, int slotIndex) => '${key}_$slotIndex';

  static Future<int?> activeSlotIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_activeSlotKey);
    if (index == null || index < 0 || index >= slotCount) return null;
    return index;
  }

  static Future<bool> loadActiveGame() async {
    final slotIndex = await activeSlotIndex();
    if (slotIndex == null) return false;
    return loadGame(slotIndex: slotIndex);
  }

  static Future<void> saveActiveGame({int? targetIndex}) async {
    final slotIndex = await activeSlotIndex();
    if (slotIndex == null) return;
    await saveGame(slotIndex: slotIndex, targetIndex: targetIndex);
  }

  static Future<void> saveGame({int? targetIndex, int slotIndex = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final sequence = prefs.getStringList(_sequenceKey) ?? createSequence();
    final progress = targetIndex ?? prefs.getInt(progressKey) ?? 1;

    await Future.wait([
      prefs.setInt(_activeSlotKey, slotIndex),
      prefs.setBool(_slotKey(_saveExistsKey, slotIndex), true),
      prefs.setBool(
        _slotKey(_saveCompletedKey, slotIndex),
        prefs.getBool(_completedKey) ?? false,
      ),
      prefs.setInt(
        _slotKey(_saveCompletedPagesKey, slotIndex),
        prefs.getInt(mosaicCompletedGamePagesKey) ?? 0,
      ),
      prefs.setInt(
        _slotKey(_saveCurrentSceneKey, slotIndex),
        prefs.getInt(currentSceneKey) ?? 0,
      ),
      prefs.setString(
        _slotKey(_saveDifficultyKey, slotIndex),
        prefs.getString(GameDifficulty.prefsKey) ?? GameDifficulty.hard.name,
      ),
      prefs.setStringList(_slotKey(_saveSequenceKey, slotIndex), sequence),
      prefs.setInt(_slotKey(_saveProgressKey, slotIndex), progress),
      prefs.setString(
        _slotKey(_saveTimestampKey, slotIndex),
        DateTime.now().toIso8601String(),
      ),
    ]);
  }

  static Future<bool> hasSavedGame({int slotIndex = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_slotKey(_saveExistsKey, slotIndex)) ?? false;
  }

  static Future<bool> loadGame({int slotIndex = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_slotKey(_saveExistsKey, slotIndex)) ?? false)) {
      return false;
    }

    await Future.wait([
      prefs.setInt(_activeSlotKey, slotIndex),
      prefs.setBool(
        _completedKey,
        prefs.getBool(_slotKey(_saveCompletedKey, slotIndex)) ?? false,
      ),
      prefs.setInt(
        mosaicCompletedGamePagesKey,
        prefs.getInt(_slotKey(_saveCompletedPagesKey, slotIndex)) ?? 0,
      ),
      prefs.setInt(
        currentSceneKey,
        prefs.getInt(_slotKey(_saveCurrentSceneKey, slotIndex)) ?? 0,
      ),
      prefs.setString(
        GameDifficulty.prefsKey,
        prefs.getString(_slotKey(_saveDifficultyKey, slotIndex)) ??
            GameDifficulty.hard.name,
      ),
      prefs.setStringList(
        _sequenceKey,
        prefs.getStringList(_slotKey(_saveSequenceKey, slotIndex)) ??
            createSequence(),
      ),
      prefs.setInt(
        progressKey,
        prefs.getInt(_slotKey(_saveProgressKey, slotIndex)) ?? 1,
      ),
    ]);
    return true;
  }

  static Future<String?> savedAtLabel({int slotIndex = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_slotKey(_saveTimestampKey, slotIndex));
    if (timestamp == null) return null;

    final savedAt = DateTime.tryParse(timestamp);
    if (savedAt == null) return null;
    return '${savedAt.year.toString().padLeft(4, '0')}-'
        '${savedAt.month.toString().padLeft(2, '0')}-'
        '${savedAt.day.toString().padLeft(2, '0')} '
        '${savedAt.hour.toString().padLeft(2, '0')}:'
        '${savedAt.minute.toString().padLeft(2, '0')}';
  }
}
