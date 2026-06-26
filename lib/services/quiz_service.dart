import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prove/models/quiz_question.dart';

class QuizAttempt {
  final DateTime date;
  final int correct;
  final int total;
  final List<String> missedReferences;

  const QuizAttempt({
    required this.date,
    required this.correct,
    required this.total,
    required this.missedReferences,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'correct': correct,
        'total': total,
        'missedReferences': missedReferences,
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
        date: DateTime.parse(json['date'] as String),
        correct: json['correct'] as int,
        total: json['total'] as int,
        missedReferences: List<String>.from(json['missedReferences'] as List),
      );
}

class QuizService {
  static const String _highScoreKey = 'quiz_high_score';
  static const String _totalCorrectKey = 'quiz_total_correct';
  static const String _totalQuestionsKey = 'quiz_total_questions';
  static const String _historyKey = 'quiz_history';

  List<Map<String, dynamic>>? _bibleData;
  final _random = Random();

  Future<List<Map<String, dynamic>>> _loadBibleData() async {
    if (_bibleData != null) return _bibleData!;

    final jsonString = await rootBundle.loadString(
      'assets/proverbiosBibliaLivre.json',
    );
    _bibleData = List<Map<String, dynamic>>.from(json.decode(jsonString));
    return _bibleData!;
  }

  Future<List<QuizQuestion>> generateQuestions({int count = 10}) async {
    final data = await _loadBibleData();
    final allVerses = <Map<String, dynamic>>[];

    for (int c = 0; c < data.length; c++) {
      final chapter = data[c];
      final chapterNum = (c + 1).toString();
      final verses = chapter[chapterNum] as Map<String, dynamic>;
      for (final entry in verses.entries) {
        allVerses.add({
          'chapter': chapterNum,
          'verse': entry.key,
          'text': entry.value as String,
        });
      }
    }

    allVerses.shuffle(_random);
    final selected = allVerses.take(count * 2).toList();

    final questions = <QuizQuestion>[];
    for (int i = 0; i < count && i * 2 + 1 < selected.length; i++) {
      final type = _random.nextInt(2);
      if (type == 0) {
        final q = _buildCompletionQuestion(selected[i * 2], selected);
        if (q != null) questions.add(q);
      } else {
        final q = _buildChapterQuestion(selected[i * 2], data);
        if (q != null) questions.add(q);
      }
    }

    questions.shuffle(_random);
    return questions;
  }

  QuizQuestion? _buildCompletionQuestion(
    Map<String, dynamic> verse,
    List<Map<String, dynamic>> allVerses,
  ) {
    final text = verse['text'] as String;
    final words = text.split(' ');

    if (words.length < 5) return null;

    final splitPoint = _random.nextInt(words.length ~/ 2) + (words.length ~/ 3);
    if (splitPoint >= words.length - 2) return null;

    final startPart = words.take(splitPoint).join(' ');
    final correctEnd = words.skip(splitPoint).join(' ');

    if (correctEnd.trim().isEmpty || startPart.trim().isEmpty) return null;

    final wrongAnswers = <String>{};
    final pool = [...allVerses]..shuffle(_random);
    for (final v in pool) {
      if (wrongAnswers.length >= 3) break;
      final vText = v['text'] as String;
      final vWords = vText.split(' ');
      if (vWords.length < splitPoint + 2) continue;
      final vEnd = vWords.skip(splitPoint).join(' ');
      if (vEnd != correctEnd) {
        wrongAnswers.add(vEnd.length > 80 ? '${vEnd.substring(0, 80)}...' : vEnd);
      }
    }

    if (wrongAnswers.length < 3) return null;

    final options = [correctEnd, ...wrongAnswers];
    options.shuffle(_random);
    final correctIndex = options.indexOf(correctEnd);

    return QuizQuestion(
      question: '"$startPart..."',
      options: options,
      correctIndex: correctIndex,
      fullVerse: text,
      reference: 'Provérbios ${verse['chapter']}:${verse['verse']}',
    );
  }

  QuizQuestion? _buildChapterQuestion(
    Map<String, dynamic> verse,
    List<Map<String, dynamic>> data,
  ) {
    final correctChapter = verse['chapter'] as String;

    final wrongChapters = <String>{};
    while (wrongChapters.length < 3) {
      final r = (_random.nextInt(31) + 1).toString();
      if (r != correctChapter) wrongChapters.add(r);
    }

    final options = [correctChapter, ...wrongChapters];
    options.shuffle(_random);
    final correctIndex = options.indexOf(correctChapter);

    return QuizQuestion(
      question: '"${verse['text']}"',
      options: options.map((c) => 'Capítulo $c').toList(),
      correctIndex: correctIndex,
      fullVerse: verse['text'] as String,
      reference: 'Provérbios ${verse['chapter']}:${verse['verse']}',
    );
  }

  Future<void> saveScore({
    required int correct,
    required int total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_highScoreKey) ?? 0;
    if (correct > currentHigh) {
      await prefs.setInt(_highScoreKey, correct);
    }
    final totalCorrect = (prefs.getInt(_totalCorrectKey) ?? 0) + correct;
    final totalQuestions = (prefs.getInt(_totalQuestionsKey) ?? 0) + total;
    await prefs.setInt(_totalCorrectKey, totalCorrect);
    await prefs.setInt(_totalQuestionsKey, totalQuestions);
  }

  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'highScore': prefs.getInt(_highScoreKey) ?? 0,
      'totalCorrect': prefs.getInt(_totalCorrectKey) ?? 0,
      'totalQuestions': prefs.getInt(_totalQuestionsKey) ?? 0,
    };
  }

  Future<void> saveQuizAttempt({
    required int correct,
    required int total,
    required List<String> missedReferences,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = <QuizAttempt>[
      QuizAttempt(
        date: DateTime.now(),
        correct: correct,
        total: total,
        missedReferences: missedReferences,
      ),
      ...await getHistory(),
    ];
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    final json = history.map((a) => a.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(json));
  }

  Future<List<QuizAttempt>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
