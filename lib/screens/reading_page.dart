import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/services/progress_service.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final ProgressService _progressService = ProgressService();
  late Future<Map<String, dynamic>> _readingData;

  @override
  void initState() {
    super.initState();
    // Inicia a busca pelos dados da leitura
    _readingData = _loadInitialData();
  }

  // Carrega os dados iniciais
  Future<Map<String, dynamic>> _loadInitialData() async {
    final chapterData = await _progressService.getChapterForToday();
    final content = await _loadChapterContent(chapterData['chapter']);
    return {
      ...chapterData,
      'content': content,
    };
  }

  // Recarrega os dados após marcar como lido
  void _reloadData() {
    setState(() {
      _readingData = _loadInitialData();
    });
  }

  Future<List<String>> _loadChapterContent(int chapter) async {
    final jsonString = await rootBundle.loadString('assets/proverbios.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final chapterObject = jsonData[chapter - 1] as Map<String, dynamic>;
    final versesMap = chapterObject[chapter.toString()] as Map<String, dynamic>;
    return versesMap.entries.map((e) => '${e.key} ${e.value}').toList();
  }

  Future<void> _markAsRead() async {
    try {
      await _progressService.markChapterAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leitura de hoje concluída! Parabéns!')),
      );
      // Após o sucesso, recarrega os dados para atualizar a UI
      _reloadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a leitura: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _readingData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Nenhum dado disponível.'));
            }

            final data = snapshot.data!;
            final int chapter = data['chapter'];
            final bool canRead = data['canRead'];
            final List<String> content = data['content'];

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                          onPressed: () => context.go('/home'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'PROVÉRBIOS $chapter',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge?.copyWith(color: const Color(0xFFD98F2B)),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final line = content[index];
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
                          childCount: content.length,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canRead)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _markAsRead,
                      child: const Text('Marcar como Lido'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
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
