import 'package:shared_preferences/shared_preferences.dart';

class CoachStore {
  const CoachStore();

  static const _prefix = 'coach_seen_';

  Future<bool> hasSeen(String tourId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefix$tourId') ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markSeen(String tourId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$tourId', true);
    } catch (_) {
      // Estado local apenas; falha não deve travar navegação.
    }
  }

  Future<void> reset(String tourId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$tourId');
    } catch (_) {
      // Estado local apenas; falha não deve travar navegação.
    }
  }
}
