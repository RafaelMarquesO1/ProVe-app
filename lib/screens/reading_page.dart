import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/reading_settings_provider.dart';
import 'package:myapp/services/progress_service.dart';
import 'package:myapp/widgets/bounce_button.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  static const String _bibleVersion =
      'Versão bíblica utilizada: Bíblia Livre (Português).';

  final ProgressService _progressService = ProgressService();
  late Future<Map<String, dynamic>> _readingData;
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final ReadingSettingsProvider _settings = ReadingSettingsProvider.instance;

  bool _isReading = false;
  bool _showFab = false;
  int _currentlySpeakingVerse = -1;
  Completer<void>? _speechCompleter;
  
  // Guardamos os offsets de caractere para cada versículo na string completa
  List<int> _verseStartOffsets = [];
  // Chaves para identificar a posição de cada versículo na tela
  final List<GlobalKey> _verseKeys = [];

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

    // Sincronização de progresso para a leitura conjunta
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (!mounted || _verseStartOffsets.isEmpty) return;

      // Encontra a qual versículo o offset atual pertence
      int verseIndex = -1;
      for (int i = 0; i < _verseStartOffsets.length; i++) {
        if (start >= _verseStartOffsets[i]) {
          verseIndex = i;
        } else {
          break;
        }
      }

      if (verseIndex != -1 && verseIndex != _currentlySpeakingVerse) {
        if (mounted) {
          setState(() {
            _currentlySpeakingVerse = verseIndex;
          });
        }

        // Rola automaticamente para o versículo atual com precisão usando a chave do widget
        if (_scrollController.hasClients && verseIndex < _verseKeys.length) {
          final keyContext = _verseKeys[verseIndex].currentContext;
          if (keyContext != null) {
            Scrollable.ensureVisible(
              keyContext,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.2, // Mantém o versículo um pouco abaixo do topo
            );
          }
        }
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

    // Ajuste de pitch baseado no gênero (ajuda na naturalidade)
    final bool isMale = _settings.voiceType == VoiceType.masculina;
    if (isMale) {
      await _flutterTts.setPitch(0.75); // Tom mais profundo para masculino
    } else {
      await _flutterTts.setPitch(1.15); // Tom mais leve para feminino
    }

    try {
      // No Android, tenta usar o motor do Google para vozes mais naturais (Neural2, Wavenet)
      if (!kIsWeb && Platform.isAndroid) {
        final dynamic engines = await _flutterTts.getEngines;
        if (engines is List && engines.contains("com.google.android.tts")) {
          await _flutterTts.setEngine("com.google.android.tts");
        }
      }

      final dynamic voicesResult = await _flutterTts.getVoices;
      if (voicesResult is List) {
        final voices = voicesResult.map((v) => Map<String, dynamic>.from(v as Map)).toList();
        
        // Filtra por PT-BR
        var ptVoices = voices.where((v) {
          final locale = (v['locale'] as String?)?.toLowerCase() ?? '';
          return locale == 'pt-br' || locale == 'pt_br';
        }).toList();

        if (ptVoices.isEmpty) return;

        // Heurística de gênero aprimorada e restritiva
        var filteredVoices = ptVoices.where((v) {
          final name = (v['name'] as String?)?.toLowerCase() ?? '';
          final genderField = v['gender']?.toString().toLowerCase() ?? '';
          
          if (isMale) {
            // Filtros Masculinos (Incluindo apenas padrões sabidamente masculinos)
            if (name.contains('female')) return false; // Exclusão imediata
            if (name.contains('male')) return true;
            if (name.contains('pbc-local') || name.contains('ptd-local') || name.contains('ptl-local')) return true;
            if (name.contains('-b-') || name.endsWith('-b') || name.contains('-d-') || name.endsWith('-d')) return true;
            if (genderField == 'male' || genderField == '1' || genderField == 'man') return true;
          } else {
            // Filtros Femininos (Exclui padrões masculinos identificados pelo usuário)
            if (name.contains('male') || name.contains('ptd-local') || name.contains('pbc-local')) return false;
            if (name.contains('female')) return true;
            if (name.contains('pba-local') || name.contains('ptc-local') || name.contains('pts-local') || name.contains('ptr-local')) return true;
            if (name.contains('-a-') || name.endsWith('-a') || name.contains('-c-') || name.endsWith('-c') || name.contains('-e-') || name.endsWith('-e')) return true;
            if (genderField == 'female' || genderField == '2' || genderField == 'woman') return true;
          }
          return false;
        }).toList();

        // Se a busca refinada falhar, usa a lista ptVoices excluindo explicitamente o oposto
        if (filteredVoices.isEmpty) {
          filteredVoices = ptVoices.where((v) {
            final name = (v['name'] as String?)?.toLowerCase() ?? '';
            if (isMale) {
              return !name.contains('female') && !name.contains('pba') && !name.contains('ptc');
            } else {
              return !name.contains('male') && !name.contains('ptd') && !name.contains('pbc');
            }
          }).toList();
        }

        // Se ainda assim estiver vazio (caso improvável), usa ptVoices
        if (filteredVoices.isEmpty) {
          filteredVoices = ptVoices;
        }

        // Sistema de pontuação para priorizar vozes de alta qualidade (Neural2 > Wavenet > High Quality > Standard)
        filteredVoices.sort((a, b) {
          final nameA = (a['name'] as String?)?.toLowerCase() ?? '';
          final nameB = (b['name'] as String?)?.toLowerCase() ?? '';
          final qualityA = a['quality']?.toString().toLowerCase() ?? '';
          final qualityB = b['quality']?.toString().toLowerCase() ?? '';
          
          int score(String name, String quality) {
            int s = 0;
            if (name.contains('neural2')) s += 1000; // Prioridade absoluta
            if (name.contains('wavenet')) s += 500;
            if (name.contains('enhanced') || quality.contains('high')) s += 250;
            
            // Heurística para trocar a voz feminina por uma alternativa (ex: C em vez de A)
            if (!isMale) {
              if (name.contains('-c-') || name.endsWith('-c')) s += 100;
              if (name.contains('-e-') || name.endsWith('-e')) s += 80;
              if (name.contains('-a-') || name.endsWith('-a')) s += 10; // A é a padrão, damos nota menor
            }
            
            return s;
          }
          
          return score(nameB, qualityB).compareTo(score(nameA, qualityA));
        });

        if (filteredVoices.isNotEmpty) {
          // No caso da voz feminina, se houver mais de uma opção de alta qualidade, 
          // pegamos a última da lista para garantir uma troca perceptível em relação à padrão.
          final selectedVoice = !isMale && filteredVoices.length > 1 
              ? filteredVoices.last 
              : filteredVoices.first;
              
          await _flutterTts.setVoice({
            'name': selectedVoice['name'] as String, 
            'locale': selectedVoice['locale'] as String
          });
          debugPrint("Voz selecionada: ${selectedVoice['name']}");
        }
      }
    } catch (e) {
      debugPrint("Erro ao encontrar configurações de voz: $e");
    }
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final chapterData = await _progressService.getChapterForToday();
    final chapters = List<int>.from(chapterData['chapters']);
    final content = await _loadChaptersContent(chapters);
    return {
      ...chapterData,
      'content': content,
    };
  }

  Future<List<String>> _loadChaptersContent(List<int> chapters) async {
    final List<String> allLines = [];
    final jsonString = await rootBundle.loadString('assets/proverbiosBibliaLivre.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;

    for (int chapter in chapters) {
      if (chapters.length > 1) {
        allLines.add('HEAD Capítulo $chapter');
      }
      final chapterObject = jsonData[chapter - 1] as Map<String, dynamic>;
      final versesMap = chapterObject[chapter.toString()] as Map<String, dynamic>;
      
      final verses = versesMap.entries.map((e) => '${e.key} ${e.value}').toList();
      allLines.addAll(verses);
    }
    
    // Inicializa as chaves para rolagem automática
    _verseKeys.clear();
    for (int i = 0; i < allLines.length; i++) {
      _verseKeys.add(GlobalKey());
    }
    
    return allLines;
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
      
      // Prepara a string conjunta para uma leitura mais natural
      final StringBuffer fullTextBuffer = StringBuffer();
      _verseStartOffsets = [];
      _verseKeys.clear();
      for (int k = 0; k < content.length; k++) {
        _verseKeys.add(GlobalKey());
      }

      for (int i = 0; i < content.length; i++) {
        String line = content[i];
        
        // Se for um cabeçalho, registramos o offset mas não lemos ou lemos como título
        if (line.startsWith('HEAD ')) {
          _verseStartOffsets.add(fullTextBuffer.length);
          fullTextBuffer.write(line.replaceFirst('HEAD ', '') + ". ");
          continue;
        }

        // Remove o número inicial do versículo para o buffer de texto
        String cleanedText = line;
        final parts = cleanedText.split(' ');
        if (parts.length > 1 && int.tryParse(parts.first) != null) {
          cleanedText = parts.sublist(1).join(' ');
        }
        
        // Registra o offset de início deste versículo no texto concatenado
        _verseStartOffsets.add(fullTextBuffer.length);
        fullTextBuffer.write(cleanedText);
        fullTextBuffer.write(" "); // Pequena pausa natural entre versículos pela pontuação
      }

      setState(() {
        _isReading = true;
      });

      await _applyTtsSettings();

      _speechCompleter = Completer<void>();
      await _flutterTts.speak(fullTextBuffer.toString());
      await _speechCompleter!.future;

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
                final List<int> chapters = List<int>.from(data['chapters']);
                final bool canRead = data['canRead'];
                final List<String> content = data['content'];

                String chapterTitle = chapters.length > 1 
                  ? '${chapters.first} - ${chapters.last}' 
                  : chapters.first.toString();

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
                                    chapterTitle,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontSize: chapters.length > 1 ? 48 : 64,
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
                                final isSpeaking = index == _currentlySpeakingVerse;
                                
                                if (line.startsWith('HEAD ')) {
                                  final title = line.replaceFirst('HEAD ', '');
                                  return Container(
                                    key: index < _verseKeys.length ? _verseKeys[index] : null,
                                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 40,
                                          height: 2,
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final parts = line.split(' ');
                                final verseNumber = parts.first;
                                final verseText = parts.sublist(1).join(' ');

                                return AnimatedContainer(
                                  key: index < _verseKeys.length ? _verseKeys[index] : null,
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
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                              child: Text(
                                _bibleVersion,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subtleTextColor,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
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
