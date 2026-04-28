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
          return _buildLoadingShimmer(context);
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
                    _showInfoDialog(context, 'Maior Ofensiva', 'Seu recorde histórico! A maior quantidade de dias seguidos que você manteve o ritmo sem falhar. Você já chegou a ${user.longestStreak} dias!', Icons.emoji_events_rounded);
                  },
                  child: _buildSecondaryStat(context, 'Maior Ofensiva', '${user.longestStreak} dias', Icons.emoji_events_rounded, Colors.amber),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BounceButton(
                  onTap: () {
                    _showInfoDialog(context, 'Total Lido', 'Número de dias totais já completados desde que você começou sua jornada! São ${user.completedDays.length} dias iluminados pela leitura.', Icons.menu_book_rounded);
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

  void _showInfoDialog(BuildContext context, String title, String desc, IconData icon) {
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
    final unit = achievement['unit'] as String;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar conquista',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, animation, __, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isUnlocked ? color.withOpacity(0.12) : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: isUnlocked ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ] : null,
                        ),
                        child: Icon(
                          isUnlocked ? iconData : Icons.lock_rounded,
                          color: isUnlocked ? color : Colors.grey.shade400,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        achievement['title'] as String,
                        style: const TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['desc'] as String,
                        style: TextStyle(
                          color: isUnlocked ? color : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isUnlocked
                            ? 'Conquista desbloqueada! Você já alcançou esse marco de sabedoria.'
                            : 'Falta pouco! Continue sua jornada diária.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progresso',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '$currentValue/$threshold',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (currentValue / threshold).clamp(0, 1).toDouble(),
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUnlocked ? color : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isUnlocked ? color : Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            isUnlocked ? 'GLÓRIA A DEUS!' : 'CONTINUAR JORNADA',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
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
    
    // Calcular progresso semanal
    int completedThisWeek = 0;
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (completedDays.any((d) => d.year == day.year && d.month == day.month && d.day == day.day)) {
        completedThisWeek++;
      }
    }
    final double weekPercent = (completedThisWeek / 7).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedThisWeek de 7 dias concluídos',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
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
              final primaryColor = Theme.of(context).colorScheme.primary;

              return Expanded(
                child: BounceButton(
                  onTap: () {
                    String message = '';
                    AppAlertType type = AppAlertType.info;
                    
                    if (isCompleted) {
                      message = 'Dia $formattedDate concluído! Sabedoria garantida. 🎉';
                      type = AppAlertType.success;
                    } else if (day.isAfter(today)) {
                      message = 'Prepare-se! O dia $formattedDate ainda chegará.';
                    } else if (isToday) {
                      message = 'Hoje é dia de ler! Não perca sua ofensiva. 🔥';
                      type = AppAlertType.warning;
                    } else {
                      message = 'Ops! Você perdeu a leitura no dia $formattedDate.';
                      type = AppAlertType.error;
                    }
                    
                    AppAlerts.showSnackBar(context, message: message, type: type);
                  },
                  child: Column(
                    children: [
                      Text(
                        weekDays[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isToday ? primaryColor : Colors.grey.shade400,
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
                              : (isToday ? primaryColor.withOpacity(0.08) : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted 
                                ? primaryColor 
                                : (isToday ? primaryColor : Colors.grey.shade200),
                            width: 2,
                          ),
                          boxShadow: isCompleted ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ] : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : (isToday ? Icons.timer_outlined : null),
                          color: isCompleted ? Colors.white : (isToday ? primaryColor : Colors.transparent),
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

class _ShimmerRect extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerRect({this.width, required this.height, this.borderRadius = 8});

  @override
  State<_ShimmerRect> createState() => _ShimmerRectState();
}

class _ShimmerRectState extends State<_ShimmerRect> with SingleTickerProviderStateMixin {
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
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200,
                ],
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
