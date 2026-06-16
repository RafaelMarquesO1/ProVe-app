import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/bounce_button.dart';
import 'package:myapp/utils/theme_colors.dart';
import 'package:myapp/services/local_auth_service.dart';
import 'package:myapp/services/progress_service.dart';

class ReadingPlanPage extends StatefulWidget {
  final bool showConfetti;

  const ReadingPlanPage({super.key, this.showConfetti = false});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage>
    with AutomaticKeepAliveClientMixin {
  final ProgressService _progressService = ProgressService();
  late final Stream<UserModel?> _userStream;
  late ConfettiController _confettiController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userStream = _progressService.userStream;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    if (widget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void didUpdateWidget(ReadingPlanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showConfetti && !oldWidget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  final List<String> _motivationalQuotes = [
    "Pequenos passos levam a grandes avanços.",
    "A consistência é a chave do progresso.",
    "Leia um pouco a cada dia, vença muito com o tempo.",
    "Dedicação e disciplina constroem sabedoria.",
    "Mantenha o ritmo e veja os resultados.",
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      initialData: LocalAuthService.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingShimmer(context);
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text("Nenhum dado de usuário encontrado."),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              _buildBody(context, user),
              if (widget.showConfetti)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: pi / 2, // para baixo
                    maxBlastForce: 15,
                    minBlastForce: 5,
                    emissionFrequency: 0.1,
                    numberOfParticles: 40, // Dobro de partículas
                    gravity: 0.2,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.amber,
                    ], // Cores mais vibrantes
                    shouldLoop: false,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BounceButton(
            onTap: () {
              final randomQuote =
                  _motivationalQuotes[Random().nextInt(
                    _motivationalQuotes.length,
                  )];
              AppAlerts.showSnackBar(
                context,
                message: randomQuote,
                type: AppAlertType.info,
              );
            },
            child: Text(
              'Progresso',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 32),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe sua jornada de leitura',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),

          // Destaque Principal (Ofensiva)
          BounceButton(
            onTap: () {
              AppAlerts.showSnackBar(
                context,
                message:
                    'Leia hoje para manter sua sequência!',
                type: AppAlertType.success,
              );
            },
            child: _buildMainStreakHero(context, user),
          ),
          const SizedBox(height: 24),

          // Progresso Semanal
          _buildWeeklyProgressCard(context, user.completedDays),
          const SizedBox(height: 24),

          // Secundários
          Row(
            children: [
              Expanded(
                child: BounceButton(
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Maior Sequência',
                      'Seu recorde histórico. O máximo de dias seguidos que você leu foi ${user.longestStreak} dias.',
                      Icons.emoji_events_rounded,
                    );
                  },
                  child: _buildSecondaryStat(
                    context,
                    'Maior Ofensiva',
                    '${user.longestStreak} dias',
                    Icons.emoji_events_rounded,
                    Colors.amber,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BounceButton(
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Total Lido',
                      'Capítulos completados desde o início: ${user.completedDays.length} dias.',
                      Icons.menu_book_rounded,
                    );
                  },
                  child: _buildSecondaryStat(
                    context,
                    'Total Lido',
                    '${user.completedDays.length} dias',
                    Icons.menu_book_rounded,
                    Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Conquistas
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFC107),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'CONQUISTAS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAchievementsList(context, user),
        ],
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
  ) {
    AppAlerts.showCustomDialog(
      context: context,
      title: title,
      message: desc,
      confirmText: 'Entendi',
      icon: icon,
      onConfirm: () {},
    );
  }

  Future<void> _showAchievementDialog({
    required BuildContext context,
    required Map<String, dynamic> achievement,
    required bool isUnlocked,
    required int currentValue,
  }) async {
    final color = achievement['color'] as Color;
    final iconData = achievement['icon'] as IconData;
    final threshold = achievement['threshold'] as int;
    final rarity = achievement['rarity'] as String? ?? 'comum';
    final quote = achievement['quote'] as String? ?? '';
    final ref = achievement['ref'] as String? ?? '';

    Color rarityColor;
    String rarityLabel;
    switch (rarity) {
      case 'lendario':
        rarityColor = const Color(0xFFFFC107);
        rarityLabel = 'LENDÁRIO';
        break;
      case 'epico':
        rarityColor = const Color(0xFFAB47BC);
        rarityLabel = 'ÉPICO';
        break;
      case 'raro':
        rarityColor = const Color(0xFF42A5F5);
        rarityLabel = 'RARO';
        break;
      default:
        rarityColor = const Color(0xFF78909C);
        rarityLabel = 'COMUM';
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar conquista',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, animation, __, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: isUnlocked
                            ? color.withOpacity(0.25)
                            : Colors.black.withOpacity(0.15),
                        blurRadius: 50,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rarity Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: rarityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: rarityColor,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rarityLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: rarityColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Badge Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? color.withOpacity(0.1)
                                  : ThemeColors.getLightBackground(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            isUnlocked ? iconData : Icons.lock_rounded,
                            color: isUnlocked
                                ? color
                                : ThemeColors.getDisabledColor(context),
                            size: 56,
                          ),
                          if (isUnlocked)
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, val, child) {
                                return Transform.rotate(
                                  angle: val * 2 * pi,
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: color.withOpacity(0.35),
                                    size: 130,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        achievement['title'] as String,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Desc pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? color.withOpacity(0.1)
                              : ThemeColors.getLightBackground(context),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          achievement['desc'] as String,
                          style: TextStyle(
                            color: isUnlocked
                                ? color
                                : ThemeColors.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Biblical Quote
                      if (quote.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? color.withOpacity(0.06)
                                : ThemeColors.getLightBackground(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnlocked
                                  ? color.withOpacity(0.18)
                                  : ThemeColors.getDividerColor(context),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: isUnlocked
                                    ? color.withOpacity(0.5)
                                    : ThemeColors.getDisabledColor(context),
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                quote,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: ThemeColors.getSecondaryTextColor(
                                    context,
                                  ),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ref,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isUnlocked
                                      ? color
                                      : ThemeColors.getTertiaryTextColor(
                                          context,
                                        ),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Progress Section
                      if (!isUnlocked) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROGRESSO ATUAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: ThemeColors.getTertiaryTextColor(
                                  context,
                                ),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '$currentValue / $threshold',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: (currentValue / threshold)
                                .clamp(0, 1)
                                .toDouble(),
                            minHeight: 8,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Continue lendo regularmente para desbloquear.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeColors.getSecondaryTextColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'DESBLOQUEADO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.green,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Você conquistou este marco.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ThemeColors.getSecondaryTextColor(context),
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: BounceButton(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? color
                                  : Theme.of(
                                      context,
                                    ).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isUnlocked
                                          ? color
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                isUnlocked ? 'Ótimo!' : 'OK',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsList(BuildContext context, UserModel user) {
    final longestStreak = user.longestStreak;
    final totalReadDays = user.completedDays.length;
    final currentChapter = user.currentChapter;

    final List<Map<String, dynamic>> achievements = [
      // ===== OFENSIVA (streak) =====
      {
        'title': 'Formiga Diligente',
        'desc': '1 dia de ofensiva',
        'threshold': 1,
        'metric': 'streak',
        'rarity': 'comum',
        'icon': Icons.emoji_nature_rounded,
        'color': Color(0xFF8D6E63),
        'quote': '"Vai ter com a formiga, ó preguiçoso, observa os seus caminhos e sê sábio."',
        'ref': 'Provérbios 6:6',
      },
      {
        'title': 'Temor do Senhor',
        'desc': '3 dias de ofensiva',
        'threshold': 3,
        'metric': 'streak',
        'rarity': 'comum',
        'icon': Icons.auto_awesome_rounded,
        'color': Color(0xFF5C6BC0),
        'quote': '"O temor do Senhor é o princípio da sabedoria."',
        'ref': 'Provérbios 9:10',
      },
      {
        'title': 'Caminho Reto',
        'desc': '7 dias de ofensiva',
        'threshold': 7,
        'metric': 'streak',
        'rarity': 'raro',
        'icon': Icons.alt_route_rounded,
        'color': Color(0xFF66BB6A),
        'quote': '"Confia no Senhor de todo o teu coração... e ele endireitará as tuas veredas."',
        'ref': 'Provérbios 3:5-6',
      },
      {
        'title': 'Língua Mansa',
        'desc': '14 dias de ofensiva',
        'threshold': 14,
        'metric': 'streak',
        'rarity': 'raro',
        'icon': Icons.record_voice_over_rounded,
        'color': Color(0xFF26A69A),
        'quote': '"A língua mansa é árvore da vida."',
        'ref': 'Provérbios 15:4',
      },
      {
        'title': 'Ferro Afiado',
        'desc': '21 dias de ofensiva',
        'threshold': 21,
        'metric': 'streak',
        'rarity': 'raro',
        'icon': Icons.handyman_rounded,
        'color': Color(0xFF78909C),
        'quote': '"O ferro com ferro se afia; assim o homem afia o rosto do seu amigo."',
        'ref': 'Provérbios 27:17',
      },
      {
        'title': 'Torre Forte',
        'desc': '60 dias de ofensiva',
        'threshold': 60,
        'metric': 'streak',
        'rarity': 'epico',
        'icon': Icons.castle_rounded,
        'color': Color(0xFF78909C),
        'quote': '"O nome do Senhor é uma torre forte; o justo corre para ela e está em segurança."',
        'ref': 'Provérbios 18:10',
      },
      {
        'title': 'Coroa de Sábio',
        'desc': '100 dias de ofensiva',
        'threshold': 100,
        'metric': 'streak',
        'rarity': 'epico',
        'icon': Icons.military_tech_rounded,
        'color': Color(0xFFFBC02D),
        'quote': '"Os filhos dos filhos são a coroa dos velhos, e a glória dos filhos são seus pais."',
        'ref': 'Provérbios 17:6',
      },
      {
        'title': 'Muralha Inabalável',
        'desc': '180 dias de ofensiva',
        'threshold': 180,
        'metric': 'streak',
        'rarity': 'epico',
        'icon': Icons.fort_rounded,
        'color': Color(0xFF7E57C2),
        'quote': '"O homem forte é como alto muro na sua segurança."',
        'ref': 'Provérbios 18:11',
      },
      {
        'title': 'Guardião de Provérbios',
        'desc': '265 dias de ofensiva',
        'threshold': 265,
        'metric': 'streak',
        'rarity': 'lendario',
        'icon': Icons.shield_moon_rounded,
        'color': Color(0xFF3949AB),
        'quote': '"Guarda os meus mandamentos e viverás, e a minha lei como a menina dos teus olhos."',
        'ref': 'Provérbios 7:2',
      },
      {
        'title': 'Peregrino Fiel',
        'desc': '365 dias de ofensiva',
        'threshold': 365,
        'metric': 'streak',
        'rarity': 'lendario',
        'icon': Icons.travel_explore_rounded,
        'color': Color(0xFF00695C),
        'quote': '"O caminho do justo é como a brilhante luz que aumenta mais e mais até ser dia perfeito."',
        'ref': 'Provérbios 4:18',
      },
      // ===== LEITURAS TOTAIS (total) =====
      {
        'title': 'Lâmpada para os Pés',
        'desc': '30 leituras totais',
        'threshold': 30,
        'metric': 'total',
        'rarity': 'comum',
        'icon': Icons.lightbulb_circle_rounded,
        'color': Color(0xFFFF7043),
        'quote': '"O mandamento é lâmpada, e a lei é luz; as repreensões da instrução são o caminho da vida."',
        'ref': 'Provérbios 6:23',
      },
      {
        'title': 'Fonte de Vida',
        'desc': '90 leituras totais',
        'threshold': 90,
        'metric': 'total',
        'rarity': 'raro',
        'icon': Icons.waves_rounded,
        'color': Color(0xFF42A5F5),
        'quote': '"O entendimento do homem é fonte de vida para ele."',
        'ref': 'Provérbios 16:22',
      },
      {
        'title': 'Rubi Precioso',
        'desc': '180 leituras totais',
        'threshold': 180,
        'metric': 'total',
        'rarity': 'epico',
        'icon': Icons.diamond_rounded,
        'color': Color(0xFFD81B60),
        'quote': '"A sabedoria é melhor do que os rubis; e tudo o que se pode desejar não é comparável a ela."',
        'ref': 'Provérbios 8:11',
      },
      {
        'title': 'Sábio Experiente',
        'desc': '265 leituras totais',
        'threshold': 265,
        'metric': 'total',
        'rarity': 'epico',
        'icon': Icons.psychology_alt_rounded,
        'color': Color(0xFF8E24AA),
        'quote': '"O caminho do sábio tende para o alto, para que se desvie do abismo."',
        'ref': 'Provérbios 15:24',
      },
      {
        'title': 'Árvore da Vida',
        'desc': '365 leituras totais',
        'threshold': 365,
        'metric': 'total',
        'rarity': 'lendario',
        'icon': Icons.eco_rounded,
        'color': Color(0xFF2E7D32),
        'quote': '"A esperança que se retarda enferma o coração; mas o desejo cumprido é árvore da vida."',
        'ref': 'Provérbios 13:12',
      },
      {
        'title': 'Escriba da Sabedoria',
        'desc': '500 leituras totais',
        'threshold': 500,
        'metric': 'total',
        'rarity': 'lendario',
        'icon': Icons.menu_book_rounded,
        'color': Color(0xFF5D4037),
        'quote': '"Recebe as minhas palavras, e atesora os meus mandamentos contigo."',
        'ref': 'Provérbios 2:1',
      },
      {
        'title': 'Aliança de Ouro',
        'desc': '730 leituras totais',
        'threshold': 730,
        'metric': 'total',
        'rarity': 'lendario',
        'icon': Icons.workspace_premium_rounded,
        'color': Color(0xFFFFC107),
        'quote': '"A sabedoria vale mais do que o ouro fino; e o entendimento mais do que a prata."',
        'ref': 'Provérbios 16:16',
      },
      // ===== CAPÍTULOS (chapter) =====
      {
        'title': 'Primeiro Passo',
        'desc': 'Completar o capítulo 1',
        'threshold': 1,
        'metric': 'chapter',
        'rarity': 'comum',
        'icon': Icons.flag_rounded,
        'color': Color(0xFF66BB6A),
        'quote': '"O começo da sabedoria é este: adquire a sabedoria, e com tudo que tens adquirido, adquire o entendimento."',
        'ref': 'Provérbios 4:7',
      },
      {
        'title': 'Meio Caminho',
        'desc': 'Chegar ao capítulo 15',
        'threshold': 15,
        'metric': 'chapter',
        'rarity': 'raro',
        'icon': Icons.directions_rounded,
        'color': Color(0xFF29B6F6),
        'quote': '"O coração do prudente adquire o conhecimento, e o ouvido dos sábios busca o conhecimento."',
        'ref': 'Provérbios 18:15',
      },
      {
        'title': 'Missão Cumprida',
        'desc': 'Completar todos os 31 capítulos',
        'threshold': 31,
        'metric': 'chapter',
        'rarity': 'epico',
        'icon': Icons.verified_rounded,
        'color': Color(0xFFFF8F00),
        'quote': '"Bem-aventurado o homem que me ouve, vigiando às minhas portas dia a dia."',
        'ref': 'Provérbios 8:34',
      },
    ];

    final streakAchievements =
        achievements.where((a) => a['metric'] == 'streak').toList();
    final totalAchievements =
        achievements.where((a) => a['metric'] == 'total').toList();
    final chapterAchievements =
        achievements.where((a) => a['metric'] == 'chapter').toList();

    final totalUnlocked = achievements.where((a) {
      final metric = a['metric'] as String;
      final threshold = a['threshold'] as int;
      final val = metric == 'streak'
          ? longestStreak
          : metric == 'total'
              ? totalReadDays
              : currentChapter;
      return val >= threshold;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAchievementsOverallHeader(
          context,
          totalUnlocked,
          achievements.length,
        ),
        const SizedBox(height: 24),
        _buildAchievementCategory(
          context: context,
          categoryTitle: 'Ofensiva',
          categoryEmoji: '🔥',
          achievements: streakAchievements,
          currentValue: longestStreak,
          startDelay: 0,
        ),
        const SizedBox(height: 20),
        _buildAchievementCategory(
          context: context,
          categoryTitle: 'Leituras Totais',
          categoryEmoji: '📖',
          achievements: totalAchievements,
          currentValue: totalReadDays,
          startDelay: streakAchievements.length * 60,
        ),
        const SizedBox(height: 20),
        _buildAchievementCategory(
          context: context,
          categoryTitle: 'Capítulos',
          categoryEmoji: '✝️',
          achievements: chapterAchievements,
          currentValue: currentChapter,
          startDelay: (streakAchievements.length + totalAchievements.length) * 60,
        ),
      ],
    );
  }

  Widget _buildAchievementsOverallHeader(
    BuildContext context,
    int unlocked,
    int total,
  ) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.07),
            const Color(0xFFFFC107).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFC107),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: unlocked),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 6),
                      child: Text(
                        'de $total conquistadas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return LinearProgressIndicator(
                        value: val,
                        minHeight: 6,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFC107),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCategory({
    required BuildContext context,
    required String categoryTitle,
    required String categoryEmoji,
    required List<Map<String, dynamic>> achievements,
    required int currentValue,
    required int startDelay,
  }) {
    final unlockedCount = achievements
        .where((a) => currentValue >= (a['threshold'] as int))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(categoryEmoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              categoryTitle.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: ThemeColors.getSecondaryTextColor(context),
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$unlockedCount/${achievements.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: achievements.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              final threshold = a['threshold'] as int;
              final isUnlocked = currentValue >= threshold;
              final progress = (currentValue / threshold).clamp(0.0, 1.0);

              return _AchievementCard(
                achievement: a,
                isUnlocked: isUnlocked,
                progress: progress,
                currentValue: currentValue,
                animDelay: startDelay + i * 70,
                onTap: () => _showAchievementDialog(
                  context: context,
                  achievement: a,
                  isUnlocked: isUnlocked,
                  currentValue: currentValue,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStreakHero(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE09F3E), Color(0xFFD65108)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD65108).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const GlowingFireIcon(),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: widget.showConfetti
                  ? max(0, user.readingStreak - 1)
                  : user.readingStreak,
              end: user.readingStreak,
            ),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                '$val DIAS',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            user.readingStreak > 0
                ? 'Sequência atual'
                : 'Comece a ler hoje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(
              // If we are celebrating, animate from N-1 to N
              begin: widget.showConfetti
                  ? max(
                      0,
                      int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')) - 1,
                    )
                  : int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')),
              end: int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')),
            ),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                '$val dias',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ThemeColors.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(
    BuildContext context,
    List<DateTime> completedDays,
  ) {
    final today = DateTime.now();
    final weekStart = today.subtract(
      Duration(days: today.weekday - 1),
    ); // Segunda-feira
    final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    // Calcular progresso semanal
    int completedThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (completedDays.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
      )) {
        completedThisWeek++;
      }
    }
    final double weekPercent = (completedThisWeek / 7).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jornada Semanal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedThisWeek de 7 dias concluídos',
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    '${(weekPercent * 100).round()}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progresso visual
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: weekPercent,
              minHeight: 8,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final isCompleted = completedDays.any(
                (completedDay) =>
                    completedDay.year == day.year &&
                    completedDay.month == day.month &&
                    completedDay.day == day.day,
              );

              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final formattedDate = DateFormat('dd/MM').format(day);
              final primaryColor = Theme.of(context).colorScheme.primary;

              return Expanded(
                child: BounceButton(
                  onTap: () {
                    String message = '';
                    AppAlertType type = AppAlertType.info;

                    if (isCompleted) {
                      message =
                          'Dia $formattedDate concluído com sucesso.';
                      type = AppAlertType.success;
                    } else if (day.isAfter(today)) {
                      message =
                          'Dia $formattedDate ainda não chegou.';
                    } else if (isToday) {
                      message = 'Hoje é dia de leitura.';
                      type = AppAlertType.warning;
                    } else {
                      message =
                          'Dia $formattedDate foi perdido.';
                      type = AppAlertType.error;
                    }

                    AppAlerts.showSnackBar(
                      context,
                      message: message,
                      type: type,
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        weekDays[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: isToday
                              ? primaryColor
                              : ThemeColors.getTertiaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? primaryColor
                              : (isToday
                                    ? primaryColor.withOpacity(0.08)
                                    : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? primaryColor
                                : (isToday
                                      ? primaryColor
                                      : ThemeColors.getDividerColor(context)),
                            width: 2,
                          ),
                          boxShadow: isCompleted
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted
                              ? Icons.check_rounded
                              : (isToday ? Icons.timer_outlined : null),
                          color: isCompleted
                              ? Colors.white
                              : (isToday ? primaryColor : Colors.transparent),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isToday)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShimmerRect(width: 200, height: 30),
            const SizedBox(height: 12),
            _ShimmerRect(width: 260, height: 16),
            const SizedBox(height: 24),
            _ShimmerRect(height: 160, borderRadius: 24),
            const SizedBox(height: 24),
            _ShimmerRect(height: 100, borderRadius: 20),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _ShimmerRect(height: 110, borderRadius: 20)),
                const SizedBox(width: 16),
                Expanded(child: _ShimmerRect(height: 110, borderRadius: 20)),
              ],
            ),
            const SizedBox(height: 32),
            _ShimmerRect(width: 140, height: 20),
            const SizedBox(height: 16),
            _ShimmerRect(height: 80, borderRadius: 16),
            const SizedBox(height: 12),
            _ShimmerRect(height: 80, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

class GlowingFireIcon extends StatefulWidget {
  const GlowingFireIcon({super.key});

  @override
  State<GlowingFireIcon> createState() => _GlowingFireIconState();
}

class _GlowingFireIconState extends State<GlowingFireIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
      builder: (context, child) {
        final breathingValue = sin(_controller.value * 2 * pi);
        final scale = 1.0 + (breathingValue * 0.05);
        final glowOpacity = (breathingValue + 1) / 2;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3 * glowOpacity),
                  blurRadius: 20 * glowOpacity,
                  spreadRadius: 5 * glowOpacity,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerRect extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerRect({this.width, required this.height, this.borderRadius = 8});

  @override
  State<_ShimmerRect> createState() => _ShimmerRectState();
}

class _ShimmerRectState extends State<_ShimmerRect>
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
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
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

// ─── Achievement Card Widget ──────────────────────────────────────────────────

class _AchievementCard extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;
  final double progress;
  final int currentValue;
  final int animDelay;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.progress,
    required this.currentValue,
    required this.animDelay,
    required this.onTap,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(Duration(milliseconds: widget.animDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'lendario':
        return const Color(0xFFFFC107);
      case 'epico':
        return const Color(0xFFAB47BC);
      case 'raro':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity) {
      case 'lendario':
        return 'LENDÁRIO';
      case 'epico':
        return 'ÉPICO';
      case 'raro':
        return 'RARO';
      default:
        return 'COMUM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final color = a['color'] as Color;
    final icon = a['icon'] as IconData;
    final rarity = a['rarity'] as String? ?? 'comum';
    final rarityColor = _rarityColor(rarity);
    final rarityLabel = _rarityLabel(rarity);
    final isLegendary = rarity == 'lendario';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: BounceButton(
          onTap: widget.onTap,
          child: Container(
            width: 150,
            margin: const EdgeInsets.only(right: 14, bottom: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isUnlocked
                    ? color.withOpacity(0.35)
                    : ThemeColors.getDividerColor(context),
                width: widget.isUnlocked ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isUnlocked
                      ? color.withOpacity(isLegendary ? 0.25 : 0.16)
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.04)),
                  blurRadius: widget.isUnlocked ? 18 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    rarityLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: rarityColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Icon with check badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: widget.isUnlocked
                            ? color.withOpacity(0.12)
                            : ThemeColors.getLightBackground(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isUnlocked ? icon : Icons.lock_rounded,
                        color: widget.isUnlocked
                            ? color
                            : ThemeColors.getDisabledColor(context),
                        size: 30,
                      ),
                    ),
                    if (widget.isUnlocked)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isLegendary
                                ? rarityColor
                                : const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  a['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: widget.isUnlocked
                        ? Theme.of(context).colorScheme.onSurface
                        : ThemeColors.getTertiaryTextColor(context),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Progress or completed
                if (!widget.isUnlocked)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      minHeight: 4,
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.5),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, color: rarityColor, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        'CONCLUÍDO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
