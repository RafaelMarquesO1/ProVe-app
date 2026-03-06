import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int readingStreak;
  final DateTime? lastReadDate;
  final List<DateTime> completedDays;
  final int currentChapter; // CAMPO ADICIONADO

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.readingStreak,
    this.lastReadDate,
    required this.completedDays,
    required this.currentChapter, // CAMPO ADICIONADO
  });

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: 'Usuário',
      email: '',
      readingStreak: 0,
      lastReadDate: null,
      completedDays: [],
      currentChapter: 1, // VALOR PADRÃO
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final List<dynamic> completedTimestamps = data['completedDays'] ?? [];
    final List<DateTime> completedDates = completedTimestamps
        .map((ts) => (ts as Timestamp).toDate())
        .toList();

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'Usuário',
      email: data['email'] ?? '',
      readingStreak: data['readingStreak'] ?? 0,
      lastReadDate: (data['lastReadDate'] as Timestamp?)?.toDate(),
      completedDays: completedDates,
      currentChapter: data['currentChapter'] ?? 1, // VALOR PADRÃO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'readingStreak': readingStreak,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'completedDays': completedDays.map((date) => Timestamp.fromDate(date)).toList(),
      'currentChapter': currentChapter, // CAMPO ADICIONADO
    };
  }
}
