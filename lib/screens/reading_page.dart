import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Future<Map<String, dynamic>> _chapterData;

  @override
  void initState() {
    super.initState();
    _chapterData = _loadChapterData();
  }

  Future<Map<String, dynamic>> _loadChapterData() async {
    final prefs = await SharedPreferences.getInstance();
    int chapterToShow = prefs.getInt('lastChapter') ?? 1;
    final lastReadDateString = prefs.getString('lastReadDate');

    if (lastReadDateString != null) {
      final lastReadDate = DateTime.parse(lastReadDateString);
      final today = DateTime.now();
      if (today.day > lastReadDate.day || today.month > lastReadDate.month || today.year > lastReadDate.year) {
        if (chapterToShow < 31) {
          chapterToShow++;
        }
      }
    } else {
      chapterToShow = 1;
    }

    await prefs.setInt('lastChapter', chapterToShow);
    await prefs.setString('lastReadDate', DateTime.now().toIso8601String());

    final content = await _loadChapterContent(chapterToShow);
    return {'chapter': chapterToShow, 'content': content};
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

            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar capítulo.'));
            }

            final chapter = snapshot.data!['chapter'];
            final verses = snapshot.data!['content'];

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
