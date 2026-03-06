import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Future<Map<String, dynamic>> _chapterData;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _chapterData = _prepareChapterForReading();
    } else {
      _chapterData = Future.value({'error': 'Usuário não autenticado'});
    }
  }

  Future<Map<String, dynamic>> _prepareChapterForReading() async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    final userSnapshot = await userDocRef.get();

    if (!userSnapshot.exists) {
      developer.log('DEBUG: Usuário não encontrado no Firestore', name: 'reading_page');
      throw Exception("Usuário não encontrado no Firestore");
    }

    final user = UserModel.fromFirestore(userSnapshot);
    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);

    developer.log('--- INÍCIO DA DEPURAÇÃO ---', name: 'reading_page');
    developer.log('Horário de Agora (UTC): $todayUtc', name: 'reading_page');
    developer.log('Dias completos no DB: ${user.completedDays}', name: 'reading_page');

    final bool hasReadToday = user.completedDays.any((d) => isSameDay(d, todayUtc));

    developer.log('O usuário já leu hoje? $hasReadToday', name: 'reading_page');
    developer.log('Capítulo atual salvo no DB: ${user.currentChapter}', name: 'reading_page');

    int chapterToShow;

    if (hasReadToday) {
      developer.log('LÓGICA: Usuário JÁ LEU hoje.', name: 'reading_page');
      chapterToShow = (user.currentChapter == 1) ? 31 : user.currentChapter - 1;
      developer.log('DECISÃO: Mostrar capítulo (já lido) número $chapterToShow', name: 'reading_page');
    } else {
      developer.log('LÓGICA: Usuário AINDA NÃO LEU hoje.', name: 'reading_page');
      chapterToShow = user.currentChapter;
      developer.log('DECISÃO: Mostrar capítulo número $chapterToShow e salvar progresso.', name: 'reading_page');
      await _commitDailyReading(userDocRef, user, todayUtc, chapterToShow);
    }
    developer.log('--- FIM DA DEPURAÇÃO ---', name: 'reading_page');

    final content = await _loadChapterContent(chapterToShow);
    return {'chapter': chapterToShow, 'content': content};
  }

  Future<void> _commitDailyReading(DocumentReference userDocRef, UserModel user, DateTime todayUtc, int chapterRead) async {
    int newStreak = 1;
    if (user.lastReadDate != null) {
      final lastReadUtc = DateTime.utc(user.lastReadDate!.year, user.lastReadDate!.month, user.lastReadDate!.day);
      final difference = todayUtc.difference(lastReadUtc).inDays;
      if (difference == 1) {
        newStreak = user.readingStreak + 1;
      }
    }
    int nextChapter = (chapterRead % 31) + 1;
    
    developer.log('AÇÃO: Salvando no DB. Próximo capítulo será: $nextChapter', name: 'reading_page');

    await userDocRef.update({
      'lastReadDate': Timestamp.fromDate(todayUtc),
      'readingStreak': newStreak,
      'completedDays': FieldValue.arrayUnion([Timestamp.fromDate(todayUtc)]),
      'currentChapter': nextChapter,
    });
  }

  Future<List<String>> _loadChapterContent(int chapter) async {
    try {
      final jsonString = await rootBundle.loadString('assets/proverbios.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> chapterObject = jsonData[chapter - 1];
      final Map<String, dynamic> versesMap = chapterObject[chapter.toString()];
      final List<String> verses = [];
      versesMap.forEach((verseNumber, verseText) {
        verses.add('$verseNumber $verseText');
      });
      return verses;
    } catch (e) {
      return ['Capítulo não encontrado.'];
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _chapterData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
              String error = snapshot.error?.toString() ?? snapshot.data?['error'] ?? 'Erro desconhecido';
              return Center(child: Text('Erro ao carregar capítulo: $error'));
            }

            final chapter = snapshot.data!['chapter'];
            final verses = snapshot.data!['content'] as List<String>;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => context.go('/home'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'PROVÉRBIOS $chapter',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: const Color(0xFFD98F2B),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final line = verses[index];
                      final parts = line.split(' ');
                      final verseNumber = parts.first;
                      final verseText = parts.sublist(1).join(' ');

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                        child: RichText(
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: '$verseNumber ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: verseText),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: verses.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
