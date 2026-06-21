import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:prove/providers/reading_settings_provider.dart';
import 'package:prove/services/progress_service.dart';
import 'package:prove/utils/theme_colors.dart';
import 'package:prove/services/user_data_service.dart';
import 'package:prove/widgets/bounce_button.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prove/widgets/app_alerts.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  static const String _bibleVersion =
      'Versão bíblica utilizada: Bíblia Livre (Português).';

  final ProgressService _progressService = ProgressService();
  final UserDataService _userDataService = UserDataService.instance;
  late Future<Map<String, dynamic>> _readingData;
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _flutterTts = FlutterTts();
  final ReadingSettingsProvider _settings = ReadingSettingsProvider.instance;

  bool _isReading = false;
  bool _showPlayer = false;
  bool _showFab = false;
  bool _isHeartAnimating = false;
  int _currentlySpeakingVerse = -1;
  Completer<void>? _speechCompleter;
  bool _isPlayingTransition = false;
  bool _ignoreTtsCallbacks = false;

  // Guardamos os offsets de caractere para cada versículo na string completa
  List<int> _verseStartOffsets = [];
  List<int> _currentSpokenVerseIndexes = [];
  // Chaves para identificar a posição de cada versículo na tela
  final List<GlobalKey> _verseKeys = [];

  // Controle de Seleção e Favoritos
  final List<Map<String, dynamic>> _selectedVerses = [];
  final Set<String> _favoriteVerses = {};
  StreamSubscription? _favoritesSubscription;

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
    _readingData = _loadInitialData().then((data) {
      _listenToFavorites(data['chapters']);
      return data;
    });
    _initTts();
  }

  void _listenToFavorites(List<int> chapters) {
    // Escuta favoritos em tempo real para os capítulos carregados
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _userDataService.getFavoritesStream().listen((
      snapshot,
    ) {
      if (!mounted) return;
      final newFavorites = <String>{};
      for (final data in snapshot) {
        final chapter = data['chapter'] ?? '';
        final verseNumber = data['verse_number'] ?? '';

        // Verifica se o favorito pertence a um dos capítulos abertos
        if (chapters.contains(int.tryParse(chapter))) {
          newFavorites.add('${chapter}_$verseNumber');
        }
      }
      setState(() {
        _favoriteVerses.clear();
        _favoriteVerses.addAll(newFavorites);
      });
    });
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
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
      if (_ignoreTtsCallbacks || _isPlayingTransition) return;
      if (mounted) {
        setState(() {
          _isReading = false;
          _currentlySpeakingVerse = -1;
          _showPlayer = false;
        });
      }
    });

    _flutterTts.setCancelHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
      if (_ignoreTtsCallbacks || _isPlayingTransition) return;
      if (mounted) {
        setState(() {
          _isReading = false;
          // Retemos o _currentlySpeakingVerse e _showPlayer para o usuário poder continuar
        });
      }
    });

    // Sincronização de progresso para a leitura conjunta
    _flutterTts.setProgressHandler((
      String text,
      int start,
      int end,
      String word,
    ) {
      if (!mounted || _verseStartOffsets.isEmpty) return;

      // Encontra a qual versículo o offset atual pertence
      int localIndex = -1;
      for (int i = 0; i < _verseStartOffsets.length; i++) {
        if (start >= _verseStartOffsets[i]) {
          localIndex = i;
        } else {
          break;
        }
      }

      if (localIndex != -1 && localIndex < _currentSpokenVerseIndexes.length) {
        int globalVerseIndex = _currentSpokenVerseIndexes[localIndex];
        if (globalVerseIndex != _currentlySpeakingVerse) {
          if (mounted) {
            setState(() {
              _currentlySpeakingVerse = globalVerseIndex;
            });
          }

          // Rola automaticamente para o versículo atual com precisão usando a chave do widget
          if (_scrollController.hasClients && globalVerseIndex < _verseKeys.length) {
            final keyContext = _verseKeys[globalVerseIndex].currentContext;
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
      }
    });
  }

  Future<void> _applyTtsSettings() async {
    if (!mounted) return;

    try {
      // 1. Configurações Iniciais do Motor
      if (!kIsWeb && Platform.isAndroid) {
        final dynamic engines = await _flutterTts.getEngines;
        if (engines is List && engines.contains("com.google.android.tts")) {
          await _flutterTts.setEngine("com.google.android.tts");
        }
      }

      final bool isMale = _settings.voiceType == VoiceType.masculina;

      // 2. Seleção de Voz (O motor pode resetar rate/pitch ao trocar de voz)
      final dynamic voicesResult = await _flutterTts.getVoices;
      if (voicesResult is List) {
        final voices = voicesResult
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();

        var ptVoices = voices.where((v) {
          final locale = (v['locale'] as String?)?.toLowerCase() ?? '';
          return locale == 'pt-br' || locale == 'pt_br';
        }).toList();

        if (ptVoices.isNotEmpty) {
          var filteredVoices = ptVoices.where((v) {
            final name = (v['name'] as String?)?.toLowerCase() ?? '';
            final genderField = v['gender']?.toString().toLowerCase() ?? '';

            if (isMale) {
              if (name.contains('female')) return false;
              if (name.contains('male')) return true;
              if (name.contains('pbc-local') ||
                  name.contains('ptd-local') ||
                  name.contains('ptl-local')) {
                return true;
              }
              if (name.contains('-b-') ||
                  name.endsWith('-b') ||
                  name.contains('-d-') ||
                  name.endsWith('-d')) {
                return true;
              }
              if (genderField == 'male' ||
                  genderField == '1' ||
                  genderField == 'man') {
                return true;
              }
            } else {
              if (name.contains('male') ||
                  name.contains('ptd-local') ||
                  name.contains('pbc-local')) {
                return false;
              }
              if (name.contains('female')) return true;
              if (name.contains('pba-local') ||
                  name.contains('ptc-local') ||
                  name.contains('pts-local') ||
                  name.contains('ptr-local')) {
                return true;
              }
              if (name.contains('-a-') ||
                  name.endsWith('-a') ||
                  name.contains('-c-') ||
                  name.endsWith('-c') ||
                  name.contains('-e-') ||
                  name.endsWith('-e')) {
                return true;
              }
              if (genderField == 'female' ||
                  genderField == '2' ||
                  genderField == 'woman') {
                return true;
              }
            }
            return false;
          }).toList();

          if (filteredVoices.isEmpty) {
            filteredVoices = ptVoices.where((v) {
              final name = (v['name'] as String?)?.toLowerCase() ?? '';
              if (isMale) {
                return !name.contains('female') && !name.contains('pba');
              }
              return !name.contains('male') && !name.contains('ptd');
            }).toList();
          }

          if (filteredVoices.isNotEmpty) {
            filteredVoices.sort((a, b) {
              final nameA = (a['name'] as String?)?.toLowerCase() ?? '';
              final nameB = (b['name'] as String?)?.toLowerCase() ?? '';
              int score(String name) {
                if (name.contains('neural2')) return 1000;
                if (name.contains('wavenet')) return 500;
                return 0;
              }

              return score(nameB).compareTo(score(nameA));
            });

            final selectedVoice = !isMale && filteredVoices.length > 1
                ? filteredVoices.last
                : filteredVoices.first;
            await _flutterTts.setVoice({
              'name': selectedVoice['name'] as String,
              'locale': selectedVoice['locale'] as String,
            });
          }
        }
      }

      // 3. Aplicação de Rate e Pitch (Sempre após a voz para garantir persistência)
      double rate = _settings.speechRate;
      if (Platform.isIOS) {
        rate = rate * 0.5; // No iOS, 0.5 é a velocidade normal (1.0x)
      } else if (Platform.isAndroid) {
        // No Android, a escala varia entre motores, mas o Google TTS costuma usar 0.5 a 1.0 como faixa ideal
        // Mantemos a proporção direta mas garantimos que 1.0 seja uma velocidade natural
        rate = rate * 0.5;
      }
      await _flutterTts.setSpeechRate(rate);

      if (isMale) {
        await _flutterTts.setPitch(0.85);
      } else {
        await _flutterTts.setPitch(1.05);
      }
    } catch (e) {
      debugPrint("Erro ao aplicar configurações de TTS: $e");
    }
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    final chapterData = await _progressService.getChapterForToday();
    final chapters = List<int>.from(chapterData['chapters']);
    final content = await _loadChaptersContent(chapters);
    return {...chapterData, 'content': content};
  }

  Future<List<String>> _loadChaptersContent(List<int> chapters) async {
    final List<String> allLines = [];
    final jsonString = await rootBundle.loadString(
      'assets/proverbiosBibliaLivre.json',
    );
    final jsonData = json.decode(jsonString) as List<dynamic>;

    for (int chapter in chapters) {
      if (chapters.length > 1) {
        allLines.add('HEAD Capítulo $chapter');
      }
      final chapterObject = jsonData[chapter - 1] as Map<String, dynamic>;
      final versesMap =
          chapterObject[chapter.toString()] as Map<String, dynamic>;

      final verses = versesMap.entries
          .map((e) => '${e.key} ${e.value}')
          .toList();
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
      await _closePlayer();
      await _progressService.markChapterAsRead();

      if (!mounted) return;

      // Mostra a Animação de Parabéns por Concluir a Leitura!
      AppAlerts.showCustomDialog(
        context: context,
        title: 'Leitura concluída',
        message:
            'Você finalizou a leitura de hoje. Progresso registrado.',
        confirmText: 'Ver progresso',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green.shade700,
        onConfirm: () {
          context.go('/home', extra: {'index': 1, 'showConfetti': true});
        },
      );
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Erro ao salvar a leitura: $e',
          type: AppAlertType.error,
        );
      }
    }
  }

  Future<void> _toggleReading(List<String> content) async {
    if (_isPlayingTransition) return;
    if (_isReading) {
      await _pauseReading();
    } else {
      int startIndex = _currentlySpeakingVerse != -1 ? _currentlySpeakingVerse : 0;
      await _startReadingFrom(startIndex, content);
    }
  }

  Future<void> _pauseReading() async {
    if (_isPlayingTransition) return;
    _isPlayingTransition = true;
    _ignoreTtsCallbacks = true;
    try {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      _isPlayingTransition = false;
      _ignoreTtsCallbacks = false;
    }
  }

  Future<void> _nextVerse(List<String> content) async {
    if (_isPlayingTransition) return;
    if (_currentlySpeakingVerse != -1 && _currentlySpeakingVerse + 1 < content.length) {
      await _startReadingFrom(_currentlySpeakingVerse + 1, content);
    }
  }

  Future<void> _previousVerse(List<String> content) async {
    if (_isPlayingTransition) return;
    if (_currentlySpeakingVerse > 0) {
      await _startReadingFrom(_currentlySpeakingVerse - 1, content);
    } else {
      await _startReadingFrom(0, content);
    }
  }

  Future<void> _closePlayer() async {
    if (_isPlayingTransition) return;
    _isPlayingTransition = true;
    _ignoreTtsCallbacks = true;
    try {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isReading = false;
          _showPlayer = false;
          _currentlySpeakingVerse = -1;
        });
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      _isPlayingTransition = false;
      _ignoreTtsCallbacks = false;
    }
  }

  Future<void> _startReadingFrom(int startIndex, List<String> content) async {
    if (_isPlayingTransition) return;
    _isPlayingTransition = true;
    _ignoreTtsCallbacks = true;
    try {
      await _flutterTts.stop();

      if (!mounted) return;
      if (startIndex < 0 || startIndex >= content.length) return;

      final StringBuffer fullTextBuffer = StringBuffer();
      _verseStartOffsets = [];
      _currentSpokenVerseIndexes = [];

      // Certifique-se de que temos as keys para não perder o estado de rolagem
      if (_verseKeys.length != content.length) {
        _verseKeys.clear();
        for (int k = 0; k < content.length; k++) {
          _verseKeys.add(GlobalKey());
        }
      }

      for (int i = startIndex; i < content.length; i++) {
        String line = content[i];

        if (line.startsWith('HEAD ')) {
          _verseStartOffsets.add(fullTextBuffer.length);
          _currentSpokenVerseIndexes.add(i);
          fullTextBuffer.write("${line.replaceFirst('HEAD ', '')}. ");
          continue;
        }

        String cleanedText = line;
        final parts = cleanedText.split(' ');
        if (parts.length > 1 && int.tryParse(parts.first) != null) {
          cleanedText = parts.sublist(1).join(' ');
        }

        _verseStartOffsets.add(fullTextBuffer.length);
        _currentSpokenVerseIndexes.add(i);
        fullTextBuffer.write(cleanedText);
        fullTextBuffer.write(" "); 
      }

      setState(() {
        _isReading = true;
        _showPlayer = true;
        _currentlySpeakingVerse = startIndex;
      });

      await _applyTtsSettings();

      _speechCompleter = Completer<void>();
      await _flutterTts.speak(fullTextBuffer.toString());
    } catch (e) {
      debugPrint("Erro ao iniciar reprodução: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      _isPlayingTransition = false;
      _ignoreTtsCallbacks = false;
    }
    
    if (_speechCompleter != null) {
      try {
        await _speechCompleter!.future;
      } catch (_) {}
    }
  }

  // _showVerseOptions (antigo long-press) removido. Agora usamos a barra flutuante.

  void _handleVerseTap(Map<String, dynamic> verseData) {
    HapticFeedback.selectionClick();
    setState(() {
      bool exists = _selectedVerses.any((v) => v['key'] == verseData['key']);
      if (exists) {
        _selectedVerses.removeWhere((v) => v['key'] == verseData['key']);
      } else {
        _selectedVerses.add(verseData);
      }
    });
  }

  void _handleVerseLongPress(Map<String, dynamic> verseData) {
    HapticFeedback.selectionClick();
    setState(() {
      bool exists = _selectedVerses.any((v) => v['key'] == verseData['key']);
      if (exists) {
        _selectedVerses.removeWhere((v) => v['key'] == verseData['key']);
      } else {
        _selectedVerses.add(verseData);
      }
    });
  }

  Widget _buildSelectionActionBar(ThemeData theme) {
    if (_selectedVerses.isEmpty) return const SizedBox.shrink();

    final String shareText = _selectedVerses
        .map(
          (v) =>
              '"${v['text']}"\n— Provérbios ${v['chapter']}:${v['verseNumber']}',
        )
        .join('\n\n');

    final bool allFavorited = _selectedVerses.every(
      (v) => _favoriteVerses.contains('${v['chapter']}_${v['verseNumber']}'),
    );

    return Positioned(
      bottom: 20 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_selectedVerses.length),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 80 * (1 - value)),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Pill contador
                  Container(
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedVerses.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  // Ações
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionIconButton(
                          icon: Icons.copy_rounded,
                          label: 'Copiar',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shareText));
                            setState(() => _selectedVerses.clear());
                            AppAlerts.showSnackBar(
                              context,
                              message: 'Copiado para a área de transferência',
                              type: AppAlertType.success,
                            );
                          },
                        ),
                        _buildActionIconButton(
                          icon: Icons.share_rounded,
                          label: 'Enviar',
                          onTap: () {
                            Share.share(shareText);
                            setState(() => _selectedVerses.clear());
                          },
                        ),
                        _buildActionIconButton(
                          icon: allFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: allFavorited ? 'Salvo' : 'Favoritar',
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            for (var v in _selectedVerses) {
                              await _userDataService.toggleFavorite(
                                chapter: v['chapter'],
                                verseNumber: v['verseNumber'],
                                verseText: v['text'],
                              );
                            }
                            if (!allFavorited) {
                              setState(() {
                                _selectedVerses.clear();
                                _isHeartAnimating = true;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 900),
                                () {
                                  if (mounted) setState(() => _isHeartAnimating = false);
                                },
                              );
                            } else {
                              setState(() => _selectedVerses.clear());
                            }
                          },
                        ),
                        _buildActionIconButton(
                          icon: Icons.edit_note_rounded,
                          label: 'Anotar',
                          onTap: () {
                            context.push('/reading/nova-nota', extra: shareText);
                            setState(() => _selectedVerses.clear());
                          },
                        ),
                      ],
                    ),
                  ),
                  // Divisor
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  // Fechar
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    onPressed: () => setState(() => _selectedVerses.clear()),
                    tooltip: 'Limpar seleção',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(ThemeData theme, List<String> content, Color effectiveBg) {
    if (!_showPlayer || _selectedVerses.isNotEmpty) return const SizedBox.shrink();

    // 1. Identificar dados do versículo atual de forma dinâmica
    final int currentIdx = _currentlySpeakingVerse != -1 ? _currentlySpeakingVerse : 0;
    String displayTitle = "Provérbios";
    String displayVerseText = "...";

    if (content.isNotEmpty && currentIdx < content.length) {
      final line = content[currentIdx];
      if (line.startsWith('HEAD ')) {
        displayTitle = line.replaceFirst('HEAD ', '');
        displayVerseText = "Iniciando capítulo...";
      } else {
        final parts = line.split(' ');
        final verseNumber = parts.first;
        final verseText = parts.sublist(1).join(' ');

        // Se houver mais de um capítulo carregado, descobre a qual capítulo pertence este versículo
        String chapterLabel = "";
        for (int i = currentIdx; i >= 0; i--) {
          if (content[i].startsWith('HEAD ')) {
            chapterLabel = content[i]
                .replaceFirst('HEAD ', '')
                .replaceFirst('Capítulo ', '')
                .trim();
            break;
          }
        }

        // Se não encontrou HEAD (ex: capítulo único), tenta deduzir a partir do estado da tela
        if (chapterLabel.isEmpty) {
          // Busca o título original que pode estar no formato "3" ou "3 - 4"
          // Se for "3 - 4" (múltiplos capítulos mas não achou o HEAD por algum motivo), usa como fallback
          // Mas normalmente "3" é ideal.
          // Para obter o capítulo atual, se for capítulo único, usamos a primeira parte do chapterTitle
          // Por exemplo, se chapterTitle for "3", chapterLabel vira "3".
          // Se for "3 - 4", usamos "3 - 4".
          // Vamos extrair a primeira parte de chapters se disponível.
          // Para simplificar, o fallback é o próprio chapterTitle.
          // Mas como estamos dentro de build, podemos obter o chapterTitle se quisermos,
          // ou simplesmente usar um valor genérico.
          // Como chapterTitle é definido na linha 845, e estamos fora do escopo do build local,
          // nós podemos recriar a lógica ou passar chapterTitle/chapters como parâmetro,
          // ou simplesmente deduzir a partir da lista content ou manter uma referência limpa.
          // Na verdade, no build() da página, chapterTitle é definido como:
          // chapters.length > 1 ? '${chapters.first} - ${chapters.last}' : chapters.first.toString()
          // Mas no initState ou no State da classe, não guardamos chapters diretamente.
          // Porém, temos acesso aos dados através da própria lista content que é passada.
          // Vamos fazer uma busca simples no content para ver quais capítulos estão lá:
          // Se houver HEAD lines, extraímos delas. Se não, sabemos que é apenas um capítulo.
          // Para simplificar e manter super robusto, vamos obter a lista de capítulos a partir de content:
          final chaptersInContent = content
              .where((l) => l.startsWith('HEAD '))
              .map((l) => l.replaceFirst('HEAD Capítulo ', '').trim())
              .toList();
          
          if (chaptersInContent.isNotEmpty) {
            chapterLabel = chaptersInContent.first;
          } else {
            // Se não houver HEAD, assumimos que é o capítulo ativo obtido dos dados de progresso.
            // Mas para evitar queries assíncronas no build, usamos um fallback amigável "Provérbios"
            chapterLabel = "";
          }
        }

        displayTitle = chapterLabel.isNotEmpty 
            ? "Provérbios $chapterLabel:$verseNumber"
            : "Provérbios $verseNumber";
        displayVerseText = verseText;
      }
    }

    // 2. Definir cores baseadas no tema e no fundo customizado do leitor
    final bool isDark = effectiveBg.computeLuminance() < 0.5;
    final Color cardBgColor = isDark 
        ? Colors.black.withValues(alpha: 0.82) 
        : Colors.white.withValues(alpha: 0.90);
    final Color playerBorderColor = isDark 
        ? Colors.white.withValues(alpha: 0.08) 
        : Colors.black.withValues(alpha: 0.08);
    final Color playerTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.95) 
        : Colors.black87;
    final Color playerSubTextColor = isDark 
        ? Colors.white.withValues(alpha: 0.6) 
        : Colors.black54;

    // Calcular o progresso
    double progress = 0.0;
    if (content.isNotEmpty) {
      progress = (currentIdx + 1) / content.length;
    }

    return Positioned(
      bottom: 20 + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - value)),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: playerBorderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Linha Superior: Álbum/Ícone + Info + Fechar
                  Row(
                    children: [
                      // Ícone de Capa estilizado com gradiente
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              const Color(0xFFD65108),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isReading ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Informações do versículo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTitle,
                              style: TextStyle(
                                color: playerTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayVerseText,
                              style: TextStyle(
                                color: playerSubTextColor,
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Botão Fechar
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: playerSubTextColor, size: 20),
                        onPressed: _closePlayer,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Fechar Player',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 2. Barra de Progresso Fina
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      minHeight: 3.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 3. Linha Inferior: Ajustes + Controles + Contador
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão de Ajustes de Leitura
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: playerSubTextColor, size: 20),
                        onPressed: () => context.push('/settings/reading'),
                        tooltip: 'Ajustes de Voz',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Controles de Reprodução
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous_rounded, color: playerTextColor, size: 26),
                            onPressed: () => _previousVerse(content),
                            tooltip: 'Versículo Anterior',
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          BounceButton(
                            onTap: () => _toggleReading(content),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isReading ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded, color: playerTextColor, size: 26),
                            onPressed: () => _nextVerse(content),
                            tooltip: 'Próximo Versículo',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      // Contador de Progresso (centralização através de largura fixa)
                      Container(
                        width: 28,
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${currentIdx + 1}/${content.length}",
                          style: TextStyle(
                            color: playerSubTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BounceButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingShimmer(
    BuildContext context,
    Color textColor,
    Color subtleTextColor,
  ) {
    final theme = Theme.of(context);
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
            child: Column(
              children: [
                Text(
                  'PROVÉRBIOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    color: subtleTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '...',
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
          delegate: SliverChildBuilderDelegate((context, index) {
            final widthFactor = 0.6 + (index % 4) * 0.1;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: _ShimmerLine(widthFactor: widthFactor),
            );
          }, childCount: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, child) {
        final bool isAppDark = Theme.of(context).brightness == Brightness.dark;
        // Se o tema escuro do app estiver ativo e o usuário não escolheu um fundo
        // escuro manualmente, força o fundo escuro
        final bool userChoseDark =
            _settings.backgroundColor.computeLuminance() < 0.5;
        final Color effectiveBg = isAppDark && !userChoseDark
            ? const Color(0xFF121212)
            : _settings.backgroundColor;

        final bool isDarkBackground = effectiveBg.computeLuminance() < 0.5;
        final textColor = isDarkBackground
            ? Colors.white.withOpacity(0.9)
            : Colors.black87;
        final subtleTextColor = isDarkBackground
            ? Colors.white54
            : Colors.grey.shade600;

        return Scaffold(
          backgroundColor: effectiveBg,
          body: FutureBuilder<Map<String, dynamic>>(
            future: _readingData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SafeArea(
                  child: _buildReadingShimmer(
                    context,
                    textColor,
                    subtleTextColor,
                  ),
                );
              }

              if (snapshot.hasError) {
                return SafeArea(
                  child: Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return SafeArea(
                  child: Center(
                    child: Text(
                      'Nenhum dado disponível.',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                );
              }

              final data = snapshot.data!;
              final List<int> chapters = List<int>.from(data['chapters']);
              final bool canRead = data['canRead'];
              final List<String> content = data['content'];

              String chapterTitle = chapters.length > 1
                  ? '${chapters.first} - ${chapters.last}'
                  : chapters.first.toString();

              return Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverAppBar(
                                backgroundColor: effectiveBg
                                    .withOpacity(0.95),
                                pinned: true,
                                elevation: 0,
                                leading: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      context.go('/home');
                                    }
                                  },
                                ),
                                actions: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.bookmarks_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    tooltip: 'Minha Biblioteca',
                                    onPressed: () => context.push('/library'),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.tune_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    tooltip: 'Ajustes de Leitura',
                                    onPressed: () =>
                                        context.push('/settings/reading'),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _isReading
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 32,
                                    ),
                                    tooltip: _isReading ? 'Pausar' : 'Ouvir Capítulo',
                                    onPressed: () => _toggleReading(content),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    48,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'PROVÉRBIOS',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          letterSpacing: 4,
                                          fontWeight: FontWeight.bold,
                                          color: subtleTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        chapterTitle,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.displayLarge
                                            ?.copyWith(
                                              fontSize: chapters.length > 1
                                                  ? 48
                                                  : 64,
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
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final line = content[index];
                                  final isSpeaking =
                                      index == _currentlySpeakingVerse;

                                  if (line.startsWith('HEAD ')) {
                                    final title = line.replaceFirst(
                                      'HEAD ',
                                      '',
                                    );
                                    return Container(
                                      key: index < _verseKeys.length
                                          ? _verseKeys[index]
                                          : null,
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        40,
                                        24,
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final parts = line.split(' ');
                                  final verseNumber = parts.first;
                                  final verseText = parts.sublist(1).join(' ');

                                  // Determina o capítulo real do versículo (suporte a múltiplos capítulos)
                                  String realChapter = chapterTitle;
                                  for (int i = index; i >= 0; i--) {
                                    if (content[i].startsWith('HEAD ')) {
                                      realChapter = content[i]
                                          .replaceFirst('HEAD Capítulo ', '')
                                          .trim();
                                      break;
                                    }
                                  }

                                  final verseKey = '${realChapter}_$verseNumber';
                                  final isSelected = _selectedVerses.any(
                                    (v) => v['key'] == verseKey,
                                  );
                                  final isFavorited = _favoriteVerses.contains(
                                    '${realChapter}_$verseNumber',
                                  );

                                  return GestureDetector(
                                    onTap: () => _handleVerseTap({
                                      'key': verseKey,
                                      'chapter': realChapter,
                                      'verseNumber': verseNumber,
                                      'text': verseText,
                                    }),
                                    onLongPress: () => _handleVerseLongPress({
                                      'key': verseKey,
                                      'chapter': realChapter,
                                      'verseNumber': verseNumber,
                                      'text': verseText,
                                    }),
                                    onDoubleTap: () async {
                                      HapticFeedback.lightImpact();
                                      await _userDataService.toggleFavorite(
                                        chapter: realChapter,
                                        verseNumber: verseNumber,
                                        verseText: verseText,
                                      );
                                      if (mounted) {
                                        setState(
                                          () => _isHeartAnimating = true,
                                        );
                                        Future.delayed(
                                          const Duration(milliseconds: 800),
                                          () {
                                            if (mounted) {
                                              setState(
                                                () => _isHeartAnimating = false,
                                              );
                                            }
                                          },
                                        );
                                      }
                                    },
                                    child: AnimatedContainer(
                                      key: index < _verseKeys.length
                                          ? _verseKeys[index]
                                          : null,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                        vertical: 12.0,
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary.withOpacity(0.12)
                                            : isSpeaking
                                                ? theme.colorScheme.primary.withOpacity(0.15)
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: isSelected
                                            ? Border.all(
                                                color: theme.colorScheme.primary.withOpacity(0.35),
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: RichText(
                                        textAlign: TextAlign.justify,
                                        text: TextSpan(
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontSize: _settings.fontSize,
                                                height: 1.6,
                                                color: textColor,
                                                decoration: isSelected
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                                decorationColor: theme
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                              ),
                                          children: [
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.top,
                                              child: Transform.translate(
                                                offset: const Offset(0, 2),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 6.0,
                                                      ),
                                                  child: Text(
                                                    verseNumber,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize:
                                                          _settings.fontSize *
                                                          0.6,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextSpan(text: verseText),
                                            if (isFavorited)
                                              WidgetSpan(
                                                alignment:
                                                    PlaceholderAlignment.middle,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 5.0,
                                                      ),
                                                  child: Icon(
                                                    Icons.favorite_rounded,
                                                    size:
                                                        _settings.fontSize *
                                                        0.72,
                                                    color: Colors.pink.shade300,
                                                  ),
                                                ),
                                              ),

                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }, childCount: content.length),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 32),
                              ),
                              if (canRead)
                                SliverToBoxAdapter(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 32.0,
                                    ),
                                    child: BounceButton(
                                      onTap: _markAsRead,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              const Color(0xFFD65108),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFD65108,
                                              ).withOpacity(0.4),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Concluir Leitura',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    8,
                                    24,
                                    4,
                                  ),
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
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 48),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Heart Animation Overlay
                  if (_isHeartAnimating)
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1.5),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return AnimatedOpacity(
                            opacity: _isHeartAnimating ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Transform.scale(
                              scale: scale,
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.pink,
                                size: 120,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Selection Action Bar (Floating)
                  _buildSelectionActionBar(theme),
                  // Reading Player Bar (Floating)
                  _buildPlayer(theme, content, effectiveBg),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  final double widthFactor;
  const _ShimmerLine({required this.widthFactor});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widget.widthFactor,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: ThemeColors.getShimmerColors(context),
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + 2 * _controller.value, 0),
                end: Alignment(1.0 + 2 * _controller.value, 0),
              ),
            ),
          ),
        );
      },
    );
  }
}
