import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';

class ReadingPlanPage extends StatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

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
          body: _buildBody(context, user),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MINHA OFENSIVA',
            textAlign: TextAlign.center,
            style: textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Suas estatísticas e progresso de leitura.',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          _buildStatsGrid(context, user),
          const SizedBox(height: 32),
          _buildWeeklyProgress(context, user.completedDays),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, UserModel user) {
    final stats = [
      {
        "icon": Icons.local_fire_department,
        "title": "Ofensiva Atual",
        "value": "${user.readingStreak} dias",
        "color": Colors.orange,
      },
      {
        "icon": Icons.star,
        "title": "Maior Ofensiva",
        "value": "${user.longestStreak} dias",
        "color": Colors.amber,
      },
      {
        "icon": Icons.check_circle,
        "title": "Total Lido",
        "value": "${user.completedDays.length} dias",
        "color": Colors.green,
      },
      {
        "icon": Icons.calendar_today,
        "title": "Membro Desde",
        "value": user.getMemberSince(),
        "color": Colors.blue,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return AnimatedStatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          isAnimated: stat['title'] == "Ofensiva Atual",
        );
      },
    );
  }

  Widget _buildWeeklyProgress(BuildContext context, List<DateTime> completedDays) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Column(
      children: [
        Text('Leituras na Semana', style: textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = weekStart.add(Duration(days: index));
            final isCompleted = completedDays.any((completedDay) =>
                completedDay.year == day.year &&
                completedDay.month == day.month &&
                completedDay.day == day.day);

            return Column(
              children: [
                Text(weekDays[index]),
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCompleted ? Colors.green : Colors.grey[300],
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAnimated;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isAnimated = false,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.isAnimated)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final breathingValue = sin(_controller.value * 2 * pi);
                final scale = 1.0 + (breathingValue * 0.05);
                final glowOpacity = (breathingValue + 1) / 2;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.5 * glowOpacity),
                          blurRadius: 15 * glowOpacity,
                          spreadRadius: 5 * glowOpacity,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(widget.icon, size: 36, color: widget.color),
            )
          else
            Icon(widget.icon, size: 36, color: widget.color),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              widget.title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: HSLColor.fromColor(widget.color)
                    .withLightness((HSLColor.fromColor(widget.color).lightness - 0.2)
                        .clamp(0.0, 1.0))
                    .toColor(),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
