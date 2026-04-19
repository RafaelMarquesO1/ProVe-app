import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/bounce_button.dart';

class ReadingPlanPage extends StatefulWidget {
  final bool showConfetti;
  
  const ReadingPlanPage({
    super.key,
    this.showConfetti = false,
  });

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    if (widget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  final List<String> _motivationalQuotes = [
    "A persistência é o caminho do êxito!",
    "Um pequeno avanço a cada dia soma resultados incríveis.",
    "A sabedoria é construída um provérbio por vez.",
    "O hábito da leitura transforma a mente.",
    "Não quebre o ritmo, estamos torcendo por você!",
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Faça login para ver seu progresso.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Nenhum dado de usuário encontrado."));
        }

        final user = UserModel.fromFirestore(snapshot.data!);

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
                    blastDirection: pi / 2, // down
                    maxBlastForce: 5,
                    minBlastForce: 2,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    gravity: 0.1,
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
              final randomQuote = _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];
              AppAlerts.showSnackBar(
                context,
                message: randomQuote,
                type: AppAlertType.info,
              );
            },
            child: Text(
              'SEU PROGRESSO',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mantenha a chama da leitura acesa!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 24),
          
          // Destaque Principal (Ofensiva)
          BounceButton(
            onTap: () {
              AppAlerts.showSnackBar(
                context,
                message: 'Sua ofensiva aumentará caso você leia o provérbio de hoje! 🔥',
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
                    _showInfoDialog(context, 'Maior Ofensiva', 'Seu recorde histórico! A maior quantidade de dias seguidos que você manteve o ritmo sem falhar. Você já chegou a ${user.longestStreak} dias!');
                  },
                  child: _buildSecondaryStat(context, 'Maior Ofensiva', '${user.longestStreak} dias', Icons.emoji_events_rounded, Colors.amber),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BounceButton(
                  onTap: () {
                    _showInfoDialog(context, 'Total Lido', 'Número de dias totais já completados desde que você começou sua jornada! São ${user.completedDays.length} dias iluminados pela leitura.');
                  },
                  child: _buildSecondaryStat(context, 'Total Lido', '${user.completedDays.length} dias', Icons.menu_book_rounded, Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Nova Função: Conquistas
          Text(
            'CONQUISTAS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          _buildAchievementsList(context, user),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String description) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
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
    final unit = achievement['unit'] as String;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar conquista',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isUnlocked ? color.withOpacity(0.16) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? iconData : Icons.lock_rounded,
                      color: isUnlocked ? color : Colors.grey.shade400,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    achievement['title'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement['desc'] as String,
                    style: TextStyle(
                      color: isUnlocked ? color.withOpacity(0.9) : Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUnlocked
                        ? 'Conquista desbloqueada! Você já alcançou esse marco de Provérbios.'
                        : 'Progresso atual: $currentValue/$threshold $unit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: (currentValue / threshold).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUnlocked ? color : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: isUnlocked ? color : Colors.grey.shade500,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(isUnlocked ? 'Fantástico!' : 'Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
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
          )
        ],
      ),
      child: Column(
        children: [
          const GlowingFireIcon(),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: widget.showConfetti ? max(0, user.readingStreak - 1) : user.readingStreak,
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
            user.readingStreak > 0 ? 'Ofensiva atual 🔥' : 'Comece a ler hoje mesmo!',
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

  Widget _buildSecondaryStat(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
              begin: widget.showConfetti ? max(0, int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')) - 1) : int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')),
              end: int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')),
            ),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Text(
                '$val dias',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, List<DateTime> completedDays) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Segunda-feira
    final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua Jornada nesta Semana',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final isCompleted = completedDays.any((completedDay) =>
                  completedDay.year == day.year &&
                  completedDay.month == day.month &&
                  completedDay.day == day.day);

              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              final formattedDate = DateFormat('dd/MM').format(day);

              return BounceButton(
                onTap: () {
                  if (isCompleted) {
                    AppAlerts.showSnackBar(
                      context,
                      message: 'Na data $formattedDate você leu o provérbio! Parabéns! 🎉',
                      type: AppAlertType.success,
                    );
                  } else if (day.isAfter(today)) {
                    AppAlerts.showSnackBar(
                      context,
                      message: 'Aguarde! A data $formattedDate ainda não chegou.',
                      type: AppAlertType.warning,
                    );
                  } else if (isToday) {
                    AppAlerts.showSnackBar(
                      context,
                      message: 'A data $formattedDate é hoje! Não esqueça de ler.',
                      type: AppAlertType.info,
                    );
                  } else {
                    AppAlerts.showSnackBar(
                      context,
                      message: 'Você não contabilizou leitura na data $formattedDate.',
                      type: AppAlertType.warning,
                    );
                  }
                },
                child: Column(
                  children: [
                    Text(
                      weekDays[index].substring(0, 1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted ? Theme.of(context).colorScheme.primary : (isToday ? Colors.orange.shade50 : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: isToday && !isCompleted ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : Border.all(color: Colors.transparent, width: 2),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context, UserModel user) {
    final longestStreak = user.longestStreak;
    final totalReadDays = user.completedDays.length;

    final achievements = [
      {'title': 'Formiga Diligente', 'desc': '1 dia de ofensiva', 'threshold': 1, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.emoji_nature_rounded, 'color': const Color(0xFF8D6E63)},
      {'title': 'Temor do Senhor', 'desc': '3 dias de ofensiva', 'threshold': 3, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF5C6BC0)},
      {'title': 'Caminho Reto', 'desc': '7 dias de ofensiva', 'threshold': 7, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.alt_route_rounded, 'color': const Color(0xFF66BB6A)},
      {'title': 'Língua Mansa', 'desc': '14 dias de ofensiva', 'threshold': 14, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.record_voice_over_rounded, 'color': const Color(0xFF26A69A)},
      {'title': 'Ferro Afiado', 'desc': '21 dias de ofensiva', 'threshold': 21, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.handyman_rounded, 'color': const Color(0xFF78909C)},
      {'title': 'Torre Forte', 'desc': '60 dias de ofensiva', 'threshold': 60, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.castle_rounded, 'color': const Color(0xFFBDBDBD)},
      {'title': 'Coroa de Sábio', 'desc': '100 dias de ofensiva', 'threshold': 100, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.military_tech_rounded, 'color': const Color(0xFFFBC02D)},
      {'title': 'Muralha Inabalável', 'desc': '180 dias de ofensiva', 'threshold': 180, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.fort_rounded, 'color': const Color(0xFF7E57C2)},
      {'title': 'Guardião de Provérbios', 'desc': '265 dias de ofensiva', 'threshold': 265, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.shield_moon_rounded, 'color': const Color(0xFF3949AB)},
      {'title': 'Peregrino Fiel', 'desc': '365 dias de ofensiva', 'threshold': 365, 'metric': 'streak', 'unit': 'dias', 'icon': Icons.travel_explore_rounded, 'color': const Color(0xFF00695C)},
      {'title': 'Lâmpada para os Pés', 'desc': '30 leituras totais', 'threshold': 30, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.lightbulb_circle_rounded, 'color': const Color(0xFFFF7043)},
      {'title': 'Fonte de Vida', 'desc': '90 leituras totais', 'threshold': 90, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.waves_rounded, 'color': const Color(0xFF42A5F5)},
      {'title': 'Rubi Precioso', 'desc': '180 leituras totais', 'threshold': 180, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.diamond_rounded, 'color': const Color(0xFFD81B60)},
      {'title': 'Sábio Experiente', 'desc': '265 leituras totais', 'threshold': 265, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.psychology_alt_rounded, 'color': const Color(0xFF8E24AA)},
      {'title': 'Árvore da Vida', 'desc': '365 leituras totais', 'threshold': 365, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.eco_rounded, 'color': const Color(0xFF2E7D32)},
      {'title': 'Escriba da Sabedoria', 'desc': '500 leituras totais', 'threshold': 500, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF5D4037)},
      {'title': 'Aliança de Ouro', 'desc': '730 leituras totais (2 anos)', 'threshold': 730, 'metric': 'total', 'unit': 'leituras', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFFC107)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: achievements.map((a) {
          final metric = a['metric'] as String;
          final threshold = a['threshold'] as int;
          final currentValue = metric == 'total' ? totalReadDays : longestStreak;
          final isUnlocked = currentValue >= threshold;
          final color = a['color'] as Color;
          
          return BounceButton(
            onTap: () => _showAchievementDialog(
              context: context,
              achievement: a,
              isUnlocked: isUnlocked,
              currentValue: currentValue,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: isUnlocked ? 1.0 : 0.4,
              child: Container(
                width: 110,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUnlocked ? color.withOpacity(0.5) : Colors.transparent,
                    width: 2,
                  )
                ),
                child: Column(
                  children: [
                    Icon(
                      isUnlocked ? (a['icon'] as IconData) : Icons.lock_rounded, 
                      color: isUnlocked ? color : Colors.grey.shade400, 
                      size: 36
                    ),
                    const SizedBox(height: 12),
                    Text(
                      a['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black87 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['desc'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked ? color.withOpacity(0.8) : Colors.grey.shade500,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GlowingFireIcon extends StatefulWidget {
  const GlowingFireIcon({super.key});

  @override
  State<GlowingFireIcon> createState() => _GlowingFireIconState();
}

class _GlowingFireIconState extends State<GlowingFireIcon> with SingleTickerProviderStateMixin {
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
