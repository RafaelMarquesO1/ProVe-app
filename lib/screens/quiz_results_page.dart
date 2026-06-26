import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:prove/services/quiz_service.dart';
import 'package:prove/widgets/bounce_button.dart';
import 'package:prove/widgets/shareable_card.dart';
import 'package:prove/services/share_image_service.dart';

class QuizResultsPage extends StatefulWidget {
  const QuizResultsPage({super.key});

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Map<String, int> _stats = {};
  List<QuizAttempt> _history = [];
  bool _loaded = false;
  bool _showHistory = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
  }

  Future<void> _loadData() async {
    final quizService = QuizService();
    final stats = await quizService.getStats();
    final history = await quizService.getHistory();
    if (mounted) {
      setState(() {
        _stats = stats;
        _history = history;
        _loaded = true;
      });
      final extra = GoRouterState.of(context).extra as Map? ?? {};
      final correct = extra['correct'] as int? ?? 0;
      final total = extra['total'] as int? ?? 0;
      final percentage = total > 0 ? (correct / total) : 0.0;
      if (percentage >= 0.7) {
        _confettiController.play();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map? ?? {};
    final correct = extra['correct'] as int? ?? 0;
    final total = extra['total'] as int? ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = total > 0 ? (correct / total) : 0.0;

    String emoji;
    String title;
    Color scoreColor;

    if (percentage >= 0.9) {
      emoji = '\u{1F3C6}';
      title = 'Sábio!';
      scoreColor = Colors.amber;
    } else if (percentage >= 0.7) {
      emoji = '\u{1F31F}';
      title = 'Muito bem!';
      scoreColor = Colors.green;
    } else if (percentage >= 0.5) {
      emoji = '\u{1F4D6}';
      title = 'Continue lendo!';
      scoreColor = Colors.blue;
    } else {
      emoji = '\u{1F4AA}';
      title = 'Continue praticando!';
      scoreColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 72)),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scoreColor.withOpacity(0.12),
                            border: Border.all(
                              color: scoreColor.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$correct',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: scoreColor,
                                  ),
                                ),
                                Text(
                                  'de $total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(percentage * 100).round()}% de acertos',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_loaded) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events_rounded,
                                  color: Colors.amber, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Melhor pontuação',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_stats['highScore']} acertos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_stats['totalQuestions'] != null &&
                                  _stats['totalQuestions']! > 0)
                                Text(
                                  '${((_stats['totalCorrect']! / _stats['totalQuestions']!) * 100).round()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (_history.length > 1) ...[
                            const Divider(height: 24),
                            InkWell(
                              onTap: () =>
                                  setState(() => _showHistory = !_showHistory),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.history_rounded,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.5),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Histórico (${_history.length} tentativas)',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: _showHistory ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Icon(
                                        Icons.expand_more_rounded,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.5),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 160),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: min(_history.length - 1, 10),
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final attempt = _history[index + 1];
                                    final pct = attempt.total > 0
                                        ? (attempt.correct / attempt.total)
                                        : 0.0;
                                    final dateStr = DateFormat(
                                      'dd/MM/yy',
                                    ).format(attempt.date);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${attempt.correct}/${attempt.total}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: pct >= 0.7
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : pct >= 0.5
                                                      ? Colors.blue
                                                          .withOpacity(0.1)
                                                      : Colors.orange
                                                          .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${(pct * 100).round()}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: pct >= 0.7
                                                    ? Colors.green.shade700
                                                    : pct >= 0.5
                                                        ? Colors.blue.shade700
                                                        : Colors
                                                            .orange.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              crossFadeState: _showHistory
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final card = ShareableCard(
                          type: ShareCardType.quiz,
                          title: '$correct de $total',
                          subtitle:
                              '$emoji $title — ${(percentage * 100).round()}% de acertos',
                          body:
                              'Quiz de Provérbios • ${_stats['highScore'] ?? correct} acertos (recorde)',
                          footer: 'ProVê — Provérbios Diários',
                          icon: Icons.quiz_rounded,
                          accentColor: scoreColor,
                        );
                        ShareImageService.showSharePreview(
                          context: context,
                          card: card,
                          shareText:
                              'Fiz $correct de $total no Quiz de Provérbios! ${(percentage * 100).round()}% de acertos.',
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartilhar Resultado'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: BounceButton(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.pushReplacement('/quiz');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Tentar Novamente',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Voltar ao início',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Colors.amber,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                  Colors.red,
                ],
                numberOfParticles: 15,
                maxBlastForce: 12,
                minBlastForce: 4,
                gravity: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
