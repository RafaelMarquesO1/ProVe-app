import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/user_model.dart';
import 'dart:developer' as developer;

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<int> getChaptersForDate(DateTime date) {
    int day = date.day;
    int lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;

    if (day < lastDayOfMonth) {
      if (day > 31) return [31]; // Segurança para meses hipotéticos
      return [day];
    } else {
      // Último dia do mês: lê do dia atual até o 31
      return List.generate(31 - day + 1, (index) => day + index);
    }
  }

  Future<Map<String, dynamic>> getChapterForToday() async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(_currentUser.uid);
    final userSnapshot = await userDocRef.get();

    // Se o documento do usuário não existe no Firestore, cria um.
    if (!userSnapshot.exists) {
      final creationDate = _currentUser!.metadata.creationTime ?? DateTime.now();
      final newUser = UserModel(
        uid: _currentUser.uid,
        name: _currentUser!.displayName ?? 'Usuário',
        email: _currentUser!.email ?? '',
        createdAt: creationDate,
        longestStreak: 0,
      );
      await userDocRef.set(newUser.toFirestore());
      return {'chapters': getChaptersForDate(DateTime.now()), 'canRead': true};
    }

    final user = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final bool hasReadToday = user.lastReadDate != null && !user.lastReadDate!.isBefore(startOfToday);
    final chapters = getChaptersForDate(now);

    return {
      'chapters': chapters,
      'canRead': !hasReadToday,
    };
  }

  Future<void> markChapterAsRead() async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(_currentUser.uid);
    final userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) throw Exception("Usuário não encontrado.");

    final user = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (user.lastReadDate != null && !user.lastReadDate!.isBefore(startOfToday)) {
      developer.log("Leitura de hoje já foi registrada.", name: 'ProgressService');
      return;
    }

    int newStreak = 1;
    if (user.lastReadDate != null) {
      final lastRead = user.lastReadDate!;
      final startOfLastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);
      final difference = startOfToday.difference(startOfLastReadDay).inDays;

      if (difference == 1) {
        newStreak = user.readingStreak + 1;
      }
    }

    final int newLongestStreak = max(user.longestStreak, newStreak);
    
    // O campo currentChapter agora é derivado da data, mas mantemos atualizado para o dia seguinte 
    // apenas para manter os dados do Firestore consistentes com a versão anterior do app, se necessário.
    final int nextDayChapter = (now.day % 31) + 1; 
    final Timestamp readTimestamp = Timestamp.fromDate(now);

    await userDocRef.update({
      'lastReadDate': readTimestamp,
      'readingStreak': newStreak,
      'longestStreak': newLongestStreak,
      'completedDays': FieldValue.arrayUnion([readTimestamp]),
      'currentChapter': nextDayChapter, 
    });
    developer.log("Leitura concluída. Ofensiva: $newStreak", name: 'ProgressService');
  }
}
