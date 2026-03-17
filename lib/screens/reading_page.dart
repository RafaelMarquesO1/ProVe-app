import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/reading_settings_provider.dart';
import 'package:myapp/services/progress_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final ProgressService _progressService = ProgressService();
  late Future<Map<String, dynamic>> _readingData;
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final ReadingSettingsProvider _settings = ReadingSettingsProvider.instance;

  bool _isReading = false;
  int _currentlySpeakingVerse = -1;
  Completer<void>? _speechCompleter;

  @override
  void initState() {
    super.initState();
    _readingData = _loadInitialData();
    _initTts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    
    _flutterTts.setCompletionHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
    });
  }

  Future<void> _applyTtsSettings() async {
    if (!mounted) return;

    await _flutterTts.setSpeechRate(_settings.speechRate);

    try {
      final dynamic voicesResult = await _flutterTts.getVoices;
      if (voicesResult is List) {
        final voices = voicesResult.map((v) => Map<String, String>.from(v as Map)).toList();
        
        final preferredVoices = voices.where((v) => 
            v['locale'] == 'pt-BR' && 
            v['gender'] == _settings.voiceGender
        ).toList();

        Map<String, String>? voiceToSet;
        if (preferredVoices.isNotEmpty) {
          voiceToSet = preferredVoices.first;
        } else {
          final fallbackVoices = voices.where((v) => v['locale'] == 'pt-BR').toList();
          if (fallbackVoices.isNotEmpty) {
            voiceToSet = fallbackVoices.first;
          }
        }

        if (voiceToSet != null) {
          await _flutterTts.setVoice({'name': voiceToSet['name']!, 'locale': voiceToSet['locale']!});
        }
      }
    } catch (e) {
      print("Error setting voice: $e");
    }
  }


  Future<Map<String, dynamic>> _loadInitialData() async {
    final chapterData = await _progressService.getChapterForToday();
    final content = await _loadChapterContent(chapterData['chapter']);
    return {
      ...chapterData,
      'content': content,
    };
  }

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
      _reloadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a leitura: $e')),
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    );
  }

  Future<void> _toggleReading(List<String> content) async {
    if (_isReading) {
      await _flutterTts.stop();
      setState(() {
        _isReading = false;
        _currentlySpeakingVerse = -1;
      });
    } else {
      setState(() {
        _isReading = true;
      });

      await _applyTtsSettings();

      for (int i = 0; i < content.length; i++) {
        if (!_isReading || !mounted) break;
        setState(() {
          _currentlySpeakingVerse = i;
        });

        _speechCompleter = Completer<void>();
        await _flutterTts.speak(content[i]);
        await _speechCompleter!.future; // Wait for the verse to finish
      }

      if (mounted) {
        setState(() {
          _isReading = false;
          _currentlySpeakingVerse = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _settings.backgroundColor,
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
                        controller: _scrollController,
                        slivers: [
                          SliverAppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                              onPressed: () => context.go('/home'),
                            ),
                            actions: [
                              IconButton(
                                icon: Icon(
                                  _isReading ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () => _toggleReading(content),
                              ),
                            ],
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
                                final isSpeaking = index == _currentlySpeakingVerse;

                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                                  child: RichText(
                                    textAlign: TextAlign.justify,
                                    text: TextSpan(
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: _settings.fontSize,
                                        height: 1.5,
                                        color: _settings.backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white70,
                                        backgroundColor: isSpeaking ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent,
                                      ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward),
            backgroundColor: const Color(0xFFD98F2B),
          ),
        );
      },
    );
  }
}
