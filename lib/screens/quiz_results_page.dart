import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  bool _loaded = false;

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
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await QuizService().getStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
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
      emoji = '🏆';
      title = 'Sábio!';
      scoreColor = Colors.amber;
    } else if (percentage >= 0.7) {
      emoji = '🌟';
      title = 'Muito bem!';
      scoreColor = Colors.green;
    } else if (percentage >= 0.5) {
      emoji = '📖';
      title = 'Continue lendo!';
      scoreColor = Colors.blue;
    } else {
      emoji = '💪';
      title = 'Continue praticando!';
      scoreColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
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
                  child: Row(
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
                                color: colorScheme.onSurface.withOpacity(0.6),
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
                      subtitle: '$emoji $title — ${(percentage * 100).round()}% de acertos',
                      body: 'Quiz de Provérbios • ${_stats['highScore'] ?? correct} acertos (recorde)',
                      footer: 'ProVê — Provérbios Diários',
                      icon: Icons.quiz_rounded,
                      accentColor: scoreColor,
                    );
                    ShareImageService.showSharePreview(
                      context: context,
                      card: card,
                      shareText: 'Fiz $correct de $total no Quiz de Provérbios! ${(percentage * 100).round()}% de acertos.',
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
      ),
    );
  }
}
