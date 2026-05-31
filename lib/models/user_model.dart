import 'package:intl/intl.dart';

const Object _sentinel = Object();

class UserModel {
  final String uid;
  final String name;
  final String? photoPath;
  final DateTime? lastReadDate;
  final int readingStreak;
  final int longestStreak;
  final List<DateTime> completedDays;
  final int currentChapter;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    this.photoPath,
    this.lastReadDate,
    this.readingStreak = 0,
    this.longestStreak = 0,
    this.completedDays = const [],
    this.currentChapter = 1,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photoPath: data['photoPath'] as String?,
      lastReadDate: _parseDate(data['lastReadDate']),
      readingStreak: data['readingStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      completedDays: _parseCompletedDays(data['completedDays']),
      currentChapter: data['currentChapter'] as int? ?? 1,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: 'Convidado',
      photoPath: null,
      lastReadDate: null,
      readingStreak: 0,
      longestStreak: 0,
      completedDays: const [],
      currentChapter: 1,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoPath': photoPath,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'readingStreak': readingStreak,
      'longestStreak': longestStreak,
      'completedDays': completedDays.map((date) => date.toIso8601String()).toList(),
      'currentChapter': currentChapter,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    Object? photoPath = _sentinel,
    DateTime? lastReadDate,
    int? readingStreak,
    int? longestStreak,
    List<DateTime>? completedDays,
    int? currentChapter,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoPath: photoPath == _sentinel ? this.photoPath : photoPath as String?,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      readingStreak: readingStreak ?? this.readingStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completedDays: completedDays ?? this.completedDays,
      currentChapter: currentChapter ?? this.currentChapter,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getMemberSince() {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static List<DateTime> _parseCompletedDays(dynamic value) {
    if (value is List) {
      return value.map(_parseDate).whereType<DateTime>().toList(growable: false);
    }
    return const [];
  }
}
