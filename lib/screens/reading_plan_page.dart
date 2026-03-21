import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

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
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(randomQuote),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
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
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Sua ofensiva aumentará caso você leia o provérbio de hoje! 🔥'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ));
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                  ScaffoldMessenger.of(context).clearSnackBars();
                  if (isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Na data $formattedDate você leu o provérbio! Parabéns! 🎉'), behavior: SnackBarBehavior.floating));
                  } else if (day.isAfter(today)) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aguarde! A data $formattedDate ainda não chegou.'), behavior: SnackBarBehavior.floating));
                  } else if (isToday) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('A data $formattedDate é hoje! Não esqueça de ler.'), behavior: SnackBarBehavior.floating));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Você não contabilizou leitura na data $formattedDate.'), behavior: SnackBarBehavior.floating));
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
    
    final achievements = [
      {'title': 'Semente', 'desc': '1 Dia', 'threshold': 1, 'icon': Icons.eco_rounded, 'color': const Color(0xFF81C784)},
      {'title': 'Constante', 'desc': '7 Dias', 'threshold': 7, 'icon': Icons.trending_up_rounded, 'color': const Color(0xFF64B5F6)},
      {'title': 'Dedicação', 'desc': '30 Dias', 'threshold': 30, 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFFFB74D)},
      {'title': 'Sábio', 'desc': '100 Dias', 'threshold': 100, 'icon': Icons.diamond_rounded, 'color': const Color(0xFFBA68C8)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: achievements.map((a) {
          final isUnlocked = longestStreak >= (a['threshold'] as int);
          final color = a['color'] as Color;
          
          return BounceButton(
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isUnlocked ? color.withOpacity(0.15) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isUnlocked ? (a['icon'] as IconData) : Icons.lock_rounded, 
                            color: isUnlocked ? color : Colors.grey.shade400, 
                            size: 64
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          a['title'] as String,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUnlocked 
                            ? 'Parabéns! Você desbloqueou esta insígnia incrível por bater um recorde de ${a['threshold']} dias seguidos de ofensiva!'
                            : 'Insígnia bloqueada. Mantenha seu ritmo diário e atinja uma ofensiva de ${a['threshold']} dias seguidos para abri-la!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUnlocked ? color : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Fantástico!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
