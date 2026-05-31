import 'dart:developer' as developer;
import 'dart:math';

import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/local_auth_service.dart';

class ProgressService {
  Stream<UserModel?> get userStream async* {
    await LocalAuthService.instance.init();
    yield LocalAuthService.instance.currentUser;
    yield* LocalAuthService.instance.profileChanges;
  }

  List<int> getChaptersForDate(DateTime date) {
    final day = date.day;
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;

    if (day < lastDayOfMonth) {
      return [day > 31 ? 31 : day];
    }

    return List.generate(31 - day + 1, (index) => day + index);
  }

  Future<UserModel> getCurrentUser() async {
    await LocalAuthService.instance.init();
    final user = LocalAuthService.instance.currentUser;
    if (user == null) throw Exception('Perfil local nao encontrado.');
    return user;
  }

  Future<Map<String, dynamic>> getChapterForToday() async {
    final userModel = await getCurrentUser();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final hasReadToday = userModel.lastReadDate != null &&
        !userModel.lastReadDate!.isBefore(startOfToday);
    final chapters = getChaptersForDate(now);

    return {
      'chapters': chapters,
      'canRead': !hasReadToday,
    };
  }

  Future<void> markChapterAsRead() async {
    final userModel = await getCurrentUser();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (userModel.lastReadDate != null &&
        !userModel.lastReadDate!.isBefore(startOfToday)) {
      developer.log('Leitura de hoje ja foi registrada.', name: 'ProgressService');
      return;
    }

    var newStreak = 1;
    if (userModel.lastReadDate != null) {
      final lastRead = userModel.lastReadDate!;
      final startOfLastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);
      final difference = startOfToday.difference(startOfLastReadDay).inDays;

      if (difference == 1) {
        newStreak = userModel.readingStreak + 1;
      }
    }

    final newLongestStreak = max(userModel.longestStreak, newStreak);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final nextDayChapter = (now.day >= lastDayOfMonth) ? 1 : (now.day + 1);
    final completedDays = [
      ...userModel.completedDays,
      now,
    ];

    final updated = userModel.copyWith(
      lastReadDate: now,
      readingStreak: newStreak,
      longestStreak: newLongestStreak,
      completedDays: completedDays,
      currentChapter: nextDayChapter,
    );

    await DatabaseService.instance.updateReadingProgress(updated);
    await LocalAuthService.instance.refreshProfile();

    developer.log('Leitura registrada. Ofensiva: $newStreak', name: 'ProgressService');
  }
}
