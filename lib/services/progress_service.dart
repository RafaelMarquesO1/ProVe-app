import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/user_model.dart';
import 'dart:developer' as developer;

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  List<int> getChaptersForDate(DateTime date) {
    int day = date.day;
    // Pega o último dia do mês atual
    int lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;

    if (day < lastDayOfMonth) {
      // Se não é o último dia, lê apenas o capítulo do dia (limitado a 31)
      return [day > 31 ? 31 : day];
    } else {
      // No último dia do mês, lê do dia atual até o final (Capítulo 31)
      // Isso garante que mesmo em meses curtos (28, 29 ou 30 dias),
      // todos os 31 capítulos de Provérbios sejam lidos no ciclo mensal.
      return List.generate(31 - day + 1, (index) => day + index);
    }
  }

  Future<Map<String, dynamic>> getChapterForToday() async {
    final user = _currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userDocRef.get();

    // Se o documento do usuário não existe no Firestore, cria um.
    if (!userSnapshot.exists) {
      final creationDate = user.metadata.creationTime ?? DateTime.now();
      final newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Usuário',
        email: user.email ?? '',
        createdAt: creationDate,
        longestStreak: 0,
      );
      await userDocRef.set(newUser.toFirestore());
      return {'chapters': getChaptersForDate(DateTime.now()), 'canRead': true};
    }

    final userModel = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final bool hasReadToday = userModel.lastReadDate != null && !userModel.lastReadDate!.isBefore(startOfToday);
    final chapters = getChaptersForDate(now);

    return {
      'chapters': chapters,
      'canRead': !hasReadToday,
    };
  }

  Future<void> markChapterAsRead() async {
    final user = _currentUser;
    if (user == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) throw Exception("Usuário não encontrado.");

    final userModel = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Se já leu hoje, não faz nada
    if (userModel.lastReadDate != null && !userModel.lastReadDate!.isBefore(startOfToday)) {
      developer.log("Leitura de hoje já foi registrada.", name: 'ProgressService');
      return;
    }

    // Lógica da Ofensiva (Streak)
    int newStreak = 1;
    if (userModel.lastReadDate != null) {
      final lastRead = userModel.lastReadDate!;
      final startOfLastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);
      final difference = startOfToday.difference(startOfLastReadDay).inDays;

      if (difference == 1) {
        newStreak = userModel.readingStreak + 1;
      }
    }

    final int newLongestStreak = max(userModel.longestStreak, newStreak);
    
    final int lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final int nextDayChapter = (now.day >= lastDayOfMonth) ? 1 : (now.day + 1);
    final Timestamp readTimestamp = Timestamp.fromDate(now);

    // Sempre atualizamos a data e adicionamos aos dias concluídos para garantir o feedback visual
    await userDocRef.update({
      'lastReadDate': readTimestamp,
      'readingStreak': newStreak,
      'longestStreak': newLongestStreak,
      'completedDays': FieldValue.arrayUnion([readTimestamp]),
      'currentChapter': nextDayChapter, 
    });
    developer.log("Leitura registrada. Ofensiva: $newStreak", name: 'ProgressService');
  }
}
