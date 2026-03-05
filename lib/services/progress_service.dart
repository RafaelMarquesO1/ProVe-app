import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const _lastReadDateKey = 'lastReadDate';
  static const _lastChapterKey = 'lastChapter';
  static const _streakKey = 'streak';

  // Helper para normalizar uma data para meia-noite, crucial para comparações baseadas em dias.
  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  Future<void> markAsRead(DateTime date, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    // Primeiro, obtenha a data da última leitura ANTES de sobrescrevê-la.
    final previousReadDate = await getLastReadDate();

    // Agora, atualize a sequência com base na nova leitura.
    await _updateStreak(date, previousReadDate);

    // Finalmente, salve as informações da nova leitura.
    await prefs.setString(_lastReadDateKey, date.toIso8601String());
    await prefs.setInt(_lastChapterKey, chapter);
  }

  Future<DateTime?> getLastReadDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastReadDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  Future<int> getLastReadChapter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastChapterKey) ?? 0;
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadDate = await getLastReadDate();

    if (lastReadDate == null) {
      return 0; // Nenhuma leitura ainda, sem sequência.
    }

    final normalizedToday = _normalizeDate(DateTime.now());
    final normalizedLastRead = _normalizeDate(lastReadDate);

    final difference = normalizedToday.difference(normalizedLastRead).inDays;

    if (difference > 1) {
      // Já se passou mais de um dia desde a última leitura, então a sequência foi quebrada.
      await prefs.setInt(_streakKey, 0);
      return 0;
    } else {
      // A sequência ainda está ativa (leitura hoje ou ontem).
      return prefs.getInt(_streakKey) ?? 0;
    }
  }

  Future<void> _updateStreak(DateTime newReadDate, DateTime? previousReadDate) async {
    final prefs = await SharedPreferences.getInstance();
    int streak = prefs.getInt(_streakKey) ?? 0;

    final normalizedNewRead = _normalizeDate(newReadDate);

    if (previousReadDate != null) {
      final normalizedPreviousRead = _normalizeDate(previousReadDate);
      final difference = normalizedNewRead.difference(normalizedPreviousRead).inDays;

      if (difference == 1) {
        // Continuou a sequência
        streak++;
      } else if (difference > 1) {
        // A sequência foi quebrada e está sendo reiniciada
        streak = 1;
      }
      // Se a diferença for 0, o usuário leu duas vezes no mesmo dia. A sequência não muda.
    } else {
      // Esta é a primeira leitura.
      streak = 1;
    }

    await prefs.setInt(_streakKey, streak);
  }
}
