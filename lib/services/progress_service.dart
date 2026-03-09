import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/user_model.dart';
import 'dart:developer' as developer;

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>> getChapterForToday() async {
    if (_currentUser == null) {
      throw Exception("Usuário não autenticado.");
    }

    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
    final userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) {
      throw Exception("Usuário não encontrado no Firestore.");
    }

    final user = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    // Início do dia de HOJE, no fuso horário local.
    final startOfToday = DateTime(now.year, now.month, now.day);

    final bool hasReadToday = user.lastReadDate != null &&
        !user.lastReadDate!.isBefore(startOfToday);

    developer.log("Verificando leitura: hasReadToday = $hasReadToday", name: 'ProgressService');

    if (hasReadToday) {
      int chapterReadToday;
      if (user.currentChapter == 1) {
        chapterReadToday = 31;
      } else {
        chapterReadToday = user.currentChapter - 1;
      }
      developer.log("Já leu hoje. Mostrando capítulo lido: $chapterReadToday", name: 'ProgressService');
      return {'chapter': chapterReadToday, 'canRead': false};
    } else {
      developer.log("Ainda não leu hoje. Mostrando capítulo para ler: ${user.currentChapter}", name: 'ProgressService');
      return {'chapter': user.currentChapter, 'canRead': true};
    }
  }

  Future<void> markChapterAsRead() async {
    if (_currentUser == null) {
      throw Exception("Usuário não autenticado.");
    }

    final userDocRef = _firestore.collection('users').doc(_currentUser!.uid);
    final userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) {
      throw Exception("Usuário não encontrado no Firestore.");
    }

    final user = UserModel.fromFirestore(userSnapshot);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Validação para impedir chamadas duplicadas
    if (user.lastReadDate != null && !user.lastReadDate!.isBefore(startOfToday)) {
      developer.log("Bloqueando chamada duplicada para markChapterAsRead.", name: 'ProgressService');
      return; // Já marcou como lido hoje, não faz nada.
    }
    
    int newStreak = 1;
    if (user.lastReadDate != null) {
      final lastRead = user.lastReadDate!;
      final startOfLastReadDay = DateTime(lastRead.year, lastRead.month, lastRead.day);
      
      // Calcula a diferença em dias corridos, ignorando a hora.
      final difference = startOfToday.difference(startOfLastReadDay).inDays;
      
      if (difference == 1) {
        newStreak = user.readingStreak + 1;
      } else if (difference == 0) {
        newStreak = user.readingStreak; // Segurança, não deve acontecer devido à validação acima
      }
    }

    final chapterJustRead = user.currentChapter;
    int nextChapter = (chapterJustRead % 31) + 1;

    // Salva o timestamp local exato
    final Timestamp readTimestamp = Timestamp.fromDate(now);

    await userDocRef.update({
      'lastReadDate': readTimestamp,
      'readingStreak': newStreak,
      'completedDays': FieldValue.arrayUnion([readTimestamp]),
      'currentChapter': nextChapter,
    });
    developer.log("Capítulo $chapterJustRead marcado como lido. Próximo capítulo: $nextChapter", name: 'ProgressService');
  }
}
