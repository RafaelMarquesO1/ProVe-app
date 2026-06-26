import 'dart:async';

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
  bool _timedOut = false;
  int _correctCount = 0;
  final List<String> _missedReferences = [];
  bool _loading = true;
  late AnimationController _pulseController;

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _timerEnabled = true;
  late AnimationController _timerAnimController;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _timerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _timerAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _timerAnimController, curve: Curves.linear),
    );
    _questionsFuture = _quizService.generateQuestions(count: 10);
    _questionsFuture.then((questions) {
      if (mounted) {
        setState(() {
          _questions = questions;
          _loading = false;
        });
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _timerAnimController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_timerEnabled) return;
    _secondsRemaining = 30;
    _timerAnimController.reset();
    _timerAnimController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_answered) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _answered = true;
      _timedOut = true;
      _missedReferences.add(_questions[_currentIndex].reference);
    });
  }

  void _toggleTimer() {
    setState(() {
      _timerEnabled = !_timerEnabled;
      if (_timerEnabled) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timerAnimController.stop();
      }
    });
  }

  void _answer(int index) {
    if (_answered) return;
    _timer?.cancel();
    _timerAnimController.stop();
    HapticFeedback.mediumImpact();
    final isCorrect = index == _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _timedOut = false;
      if (isCorrect) {
        _correctCount++;
        _pulseController.repeat(reverse: true);
      } else {
        _missedReferences.add(_questions[_currentIndex].reference);
      }
    });
  }

  void _next() {
    _pulseController.reset();
    if (_currentIndex + 1 < _questions.length) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _timedOut = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _quizService.saveScore(correct: _correctCount, total: _questions.length);
    _quizService.saveQuizAttempt(
      correct: _correctCount,
      total: _questions.length,
      missedReferences: _missedReferences,
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleTimer,
            icon: Icon(
              _timerEnabled ? Icons.timer_rounded : Icons.timer_off_rounded,
            ),
            tooltip: _timerEnabled ? 'Desativar timer' : 'Ativar timer',
          ),
        ],
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
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final question = _questions[_currentIndex];
    final timerRatio = _secondsRemaining / 30;
    final timerColor = timerRatio > 0.5
        ? Colors.green
        : timerRatio > 0.25
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          if (_timerEnabled && !_answered)
            AnimatedBuilder(
              animation: _timerAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: _timerAnimation.value,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          color: timerColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$_secondsRemaining s',
                        style: TextStyle(
                          fontSize: 11,
                          color: timerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentIndex + 1} de ${_questions.length}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_correctCount)}/${_currentIndex + (_answered ? 1 : 0)}',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuestionCard(theme, question),
                      const SizedBox(height: 20),
                      if (!_answered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            question.question.contains('"')
                                ? 'Qual a continuação correta?'
                                : 'De qual capítulo é este versículo?',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ...question.options.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildOption(
                                theme, entry.value, entry.key, question,
                              ),
                            ),
                          ),
                      if (_timedOut)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_off_rounded,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Tempo esgotado!',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_answered) _buildAnswerFeedback(theme, question),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_answered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                width: double.infinity,
                child: BounceButton(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
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
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, QuizQuestion question) {
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.08),
            colorScheme.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    ThemeData theme,
    String optionText,
    int index,
    QuizQuestion question,
  ) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = question.correctIndex == index;
    Color? bgColor;
    Color? borderColor;
    Color? labelColor;
    Color circleBg;
    Color circleBorder;
    Color circleText;

    if (_answered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.12);
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.withOpacity(0.12);
        borderColor = Colors.red;
      }
    }

    if (_answered && isCorrect) {
      labelColor = Colors.green.shade700;
      circleBg = Colors.green;
      circleBorder = Colors.green;
      circleText = Colors.white;
    } else if (_answered && isSelected && !isCorrect) {
      labelColor = Colors.red.shade700;
      circleBg = Colors.red;
      circleBorder = Colors.red;
      circleText = Colors.white;
    } else {
      labelColor = theme.colorScheme.onSurface;
      circleBg = Colors.transparent;
      circleBorder = theme.colorScheme.onSurface.withOpacity(0.3);
      circleText = theme.colorScheme.onSurface;
    }

    final optionContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: Border.all(color: circleBorder),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: circleText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 15,
                color: labelColor,
                height: 1.3,
                fontWeight:
                    _answered && (isCorrect || (isSelected && !isCorrect))
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
              child: Text(optionText),
            ),
          ),
          if (_answered && isCorrect)
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          if (_answered && isSelected && !isCorrect)
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
        ],
      ),
    );

    if (_answered) {
      return optionContent;
    }

    return BounceButton(
      onTap: () => _answer(index),
      child: optionContent,
    );
  }

  Widget _buildAnswerFeedback(ThemeData theme, QuizQuestion question) {
    final isCorrect =
        _selectedAnswer == question.correctIndex;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.06)
            : theme.colorScheme.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: isCorrect ? 1 + _pulseController.value * 0.15 : 1,
                child: child,
              );
            },
            child: Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: isCorrect ? Colors.green : theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correto!' : question.reference,
                  style: TextStyle(
                    color: isCorrect ? Colors.green.shade700 : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (!isCorrect && question.fullVerse.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      question.fullVerse,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
