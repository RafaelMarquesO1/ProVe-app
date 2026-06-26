import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:prove/models/quiz_question.dart';
import 'package:prove/services/quiz_service.dart';
import 'package:prove/widgets/bounce_button.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late Future<List<QuizQuestion>> _questionsFuture;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  bool _loading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _questionsFuture = _quizService.generateQuestions(count: 10);
    _questionsFuture.then((questions) {
      if (mounted) {
        setState(() {
          _questions = questions;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _answer(int index) {
    if (_answered) return;
    HapticFeedback.mediumImpact();
    final isCorrect = index == _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
  }

  void _next() {
    if (_currentIndex + 1 < _questions.length) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    await _quizService.saveScore(
      correct: _correctCount,
      total: _questions.length,
    );
    if (mounted) {
      context.pushReplacement('/quiz/resultado', extra: {
        'correct': _correctCount,
        'total': _questions.length,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz de Provérbios',
          style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? _buildLoading(theme)
          : _questions.isEmpty
              ? Center(
                  child: Text(
                    'Não foi possível gerar perguntas.',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                )
              : _buildQuiz(theme),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Preparando perguntas...',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(ThemeData theme) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            color: theme.colorScheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(
            '${_currentIndex + 1} de ${_questions.length}',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          // Versículo/Questão
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _answered ? 'Complete o versículo:' : 'Escolha a continuação correta:',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedAnswer == index;
                final isCorrect = question.correctIndex == index;
                Color? bgColor;
                Color? borderColor;

                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green.withOpacity(0.12);
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    bgColor = Colors.red.withOpacity(0.12);
                    borderColor = Colors.red;
                  }
                }

                return BounceButton(
                  onTap: () => _answer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: bgColor ?? theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor ??
                            (isSelected
                                ? theme.colorScheme.primary.withOpacity(0.3)
                                : theme.dividerColor),
                        width: borderColor != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (_answered && isCorrect)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 22),
                        if (_answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel_rounded,
                              color: Colors.red, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_answered) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.reference,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: BounceButton(
                onTap: _next,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _currentIndex + 1 < _questions.length
                          ? 'Próxima Pergunta'
                          : 'Ver Resultado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
