import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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
  bool _showFab = false;
  int _currentlySpeakingVerse = -1;
  Completer<void>? _speechCompleter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showFab) {
        setState(() => _showFab = true);
      } else if (_scrollController.offset <= 200 && _showFab) {
        setState(() => _showFab = false);
      }
    });
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

    // Caso o áudio pare ou sofra interrupção externa
    _flutterTts.setCancelHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
      if (mounted) {
        setState(() {
          _isReading = false;
          _currentlySpeakingVerse = -1;
        });
      }
    });
  }

  Future<void> _applyTtsSettings() async {
    if (!mounted) return;

    // Normalização no Android
    double rate = _settings.speechRate;
    if (!kIsWeb && Platform.isAndroid) {
      rate = rate / 2.0;
    }
    await _flutterTts.setSpeechRate(rate);

    try {
      final dynamic voicesResult = await _flutterTts.getVoices;
      if (voicesResult is List) {
        final voices = voicesResult.map((v) => Map<String, String>.from(v as Map)).toList();
        
        var ptVoices = voices.where((v) => v['locale']?.toLowerCase() == 'pt-br').toList();
        if (ptVoices.isEmpty) return;

        final selectedVoice = ptVoices.first;
        await _flutterTts.setVoice({'name': selectedVoice['name']!, 'locale': selectedVoice['locale']!});
      }
    } catch (e) {
      debugPrint("Erro ao encontrar configurações de voz: $e");
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

      if (!mounted) return;

      // Mostra a Animação de Parabéns por Concluir a Leitura!
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87, // Fundo escuro para foco total
        builder: (dialogContext) {
          return Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF388E3C).withOpacity(0.5), blurRadius: 30, spreadRadius: 10),
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Leitura Concluída!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, decoration: TextDecoration.none),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sua ofensiva aumentou. A sabedoria divina te fortaleceu hoje!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          );
        },
      );

      // Aguarda a animação
      await Future.delayed(const Duration(milliseconds: 2800));
      
      if (mounted) {
        // Fecha o dialog de parabéns usando rootNavigator para evitar conflitos com GoRouter
        Navigator.of(context, rootNavigator: true).pop(); 
      }

      // Aguarda um pequeno momento para o Navigator destravar
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // Redireciona pra Aba do Meio (Ofensiva) com Confetes
        context.go('/home', extra: {'index': 1, 'showConfetti': true});
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a leitura: $e')),
      );
    }
  }

  Future<void> _toggleReading(List<String> content) async {
    if (_isReading) {
      await _flutterTts.stop();
      if (!mounted) return;
      setState(() {
        _isReading = false;
        _currentlySpeakingVerse = -1;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isReading = true;
      });

      await _applyTtsSettings();

      for (int i = 0; i < content.length; i++) {
        if (!_isReading || !mounted) break;
        
        setState(() {
          _currentlySpeakingVerse = i;
        });

        // Tenta rolar suavemente para o versículo atual para acompanhar a leitura
        final double scrollTarget = i * (_settings.fontSize * 3);
        if (_scrollController.hasClients && i > 2) {
          _scrollController.animateTo(
            scrollTarget, 
            duration: const Duration(milliseconds: 500), 
            curve: Curves.ease
          );
        }

        _speechCompleter = Completer<void>();
        await _flutterTts.speak(content[i]);
        await _speechCompleter!.future;
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
        final bool isDarkBackground = _settings.backgroundColor.computeLuminance() < 0.5;
        final textColor = isDarkBackground ? Colors.white.withOpacity(0.9) : Colors.black87;
        final subtleTextColor = isDarkBackground ? Colors.white54 : Colors.grey.shade600;

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
                  return Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: textColor)));
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('Nenhum dado disponível.', style: TextStyle(color: textColor)));
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
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: _settings.backgroundColor.withOpacity(0.95),
                            pinned: true,
                            elevation: 0,
                            leading: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.primary),
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                            ),
                            actions: [
                              IconButton(
                                icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                                tooltip: 'Ajustes de Leitura',
                                onPressed: () => context.push('/settings/reading'),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isReading ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 32,
                                ),
                                tooltip: 'Ouvir Capítulo',
                                onPressed: () => _toggleReading(content),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                              child: Column(
                                children: [
                                  Text(
                                    'PROVÉRBIOS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16, 
                                      letterSpacing: 4, 
                                      fontWeight: FontWeight.bold, 
                                      color: subtleTextColor
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$chapter',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: 64,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final line = content[index];
                                final parts = line.split(' ');
                                final verseNumber = parts.first;
                                final verseText = parts.sublist(1).join(' ');
                                final isSpeaking = index == _currentlySpeakingVerse;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: isSpeaking ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.justify,
                                    text: TextSpan(
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: _settings.fontSize,
                                        height: 1.6,
                                        color: textColor,
                                      ),
                                      children: [
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.top,
                                          child: Transform.translate(
                                            offset: const Offset(0, 2),
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 6.0),
                                              child: Text(
                                                verseNumber,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900, 
                                                  fontSize: _settings.fontSize * 0.6,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
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
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          if (canRead)
                            SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                                child: BounceButton(
                                  onTap: _markAsRead,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [theme.colorScheme.primary, const Color(0xFFD65108)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD65108).withOpacity(0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Concluir Leitura',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 48)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: AnimatedOpacity(
            opacity: _showFab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton(
              onPressed: () {
                if (_showFab && _scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  );
                }
              },
              backgroundColor: theme.colorScheme.primary,
              elevation: 4,
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceButton({super.key, required this.child, required this.onTap});

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (mounted) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (mounted) {
      _controller.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
