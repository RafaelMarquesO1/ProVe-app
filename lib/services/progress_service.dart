import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/user_model.dart';
import 'dart:developer' as developer;

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> getChapterForToday() async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
    final userSnapshot = await userDocRef.get();

    // Se o documento do usuário não existe no Firestore, cria um.
    if (!userSnapshot.exists) {
      // Usa a data de criação da conta de autenticação.
      final creationDate = _currentUser!.metadata.creationTime ?? DateTime.now();
      final newUser = UserModel(
        uid: _currentUser!.uid,
        name: _currentUser!.displayName ?? 'Usuário',
        email: _currentUser!.email ?? '',
        createdAt: creationDate, // Data de criação real
        longestStreak: 0,
      );
      await userDocRef.set(newUser.toFirestore());
      developer.log("Novo usuário criado no Firestore com data de criação correta.", name: 'ProgressService');
      return {'chapter': newUser.currentChapter, 'canRead': true};
    }

    final data = userSnapshot.data()!;

    // Migração para usuários antigos: se não houver 'createdAt', adiciona.
    if (!data.containsKey('createdAt') || data['createdAt'] == null) {
      final creationDate = _currentUser!.metadata.creationTime ?? DateTime.now();
      await userDocRef.update({'createdAt': Timestamp.fromDate(creationDate)});
      developer.log("Usuário antigo migrado com a data de criação correta.", name: 'ProgressService');
      // Atualiza os dados locais para refletir a mudança imediatamente
      data['createdAt'] = Timestamp.fromDate(creationDate);
    }

    final user = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final bool hasReadToday = user.lastReadDate != null && !user.lastReadDate!.isBefore(startOfToday);

    if (hasReadToday) {
      int chapterReadToday = user.currentChapter == 1 ? 31 : user.currentChapter - 1;
      return {'chapter': chapterReadToday, 'canRead': false};
    } else {
      return {'chapter': user.currentChapter, 'canRead': true};
    }
  }

  Future<void> markChapterAsRead() async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
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
    final int nextChapter = (user.currentChapter % 31) + 1;
    final Timestamp readTimestamp = Timestamp.fromDate(now);

    await userDocRef.update({
      'lastReadDate': readTimestamp,
      'readingStreak': newStreak,
      'longestStreak': newLongestStreak,
      'completedDays': FieldValue.arrayUnion([readTimestamp]),
      'currentChapter': nextChapter,
    });
    developer.log("Capítulo lido. Ofensiva: $newStreak, Maior Ofensiva: $newLongestStreak", name: 'ProgressService');
  }
}
