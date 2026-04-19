import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoURL;
  final DateTime? lastReadDate;
  final int readingStreak;
  final int longestStreak; // Novo campo
  final List<DateTime> completedDays;
  final int currentChapter;
  final DateTime createdAt; // Novo campo

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL,
    this.lastReadDate,
    this.readingStreak = 0,
    this.longestStreak = 0,
    this.completedDays = const [],
    this.currentChapter = 1,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? parseDate(dynamic date) {
      return (date is Timestamp) ? date.toDate() : null;
    }

    List<DateTime> parseCompletedDays(dynamic list) {
      return (list is List) ? list.whereType<Timestamp>().map((ts) => ts.toDate()).toList() : [];
    }

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] as String?,
      lastReadDate: parseDate(data['lastReadDate']),
      readingStreak: data['readingStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      completedDays: parseCompletedDays(data['completedDays']),
      currentChapter: data['currentChapter'] ?? 1,
      // Se 'createdAt' não existir, usa uma data padrão para evitar erros
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: 'Convidado',
      email: '',
      photoURL: null,
      lastReadDate: null,
      readingStreak: 0,
      longestStreak: 0,
      completedDays: [],
      currentChapter: 1,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoURL': photoURL,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'readingStreak': readingStreak,
      'longestStreak': longestStreak,
      'completedDays': completedDays.map((date) => Timestamp.fromDate(date)).toList(),
      'currentChapter': currentChapter,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Método para formatar a data de criação
  String getMemberSince() {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }
}
