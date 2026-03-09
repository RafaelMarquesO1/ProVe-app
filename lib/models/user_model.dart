import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? lastReadDate;
  final int readingStreak;
  final List<DateTime> completedDays;
  final int currentChapter;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.lastReadDate,
    this.readingStreak = 0,
    this.completedDays = const [],
    this.currentChapter = 1,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Lógica de conversão segura para Timestamps
    DateTime? parseLastReadDate(dynamic date) {
      if (date is Timestamp) {
        return date.toDate();
      }
      return null;
    }

    List<DateTime> parseCompletedDays(dynamic list) {
      if (list is List) {
        return list.whereType<Timestamp>().map((ts) => ts.toDate()).toList();
      }
      return [];
    }

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      lastReadDate: parseLastReadDate(data['lastReadDate']),
      readingStreak: data['readingStreak'] ?? 0,
      completedDays: parseCompletedDays(data['completedDays']),
      currentChapter: data['currentChapter'] ?? 1,
    );
  }

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: 'Convidado',
      email: '',
      lastReadDate: null,
      readingStreak: 0,
      completedDays: [],
      currentChapter: 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'readingStreak': readingStreak,
      'completedDays': completedDays.map((date) => Timestamp.fromDate(date)).toList(),
      'currentChapter': currentChapter,
    };
  }
}
