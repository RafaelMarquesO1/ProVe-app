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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!.exists
            ? UserModel.fromFirestore(snapshot.data!)
            : UserModel.empty();

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
        childAspectRatio: 1.1, // Aumenta a altura relativa
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          context,
          stat['title'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16), // Reduz o padding vertical
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8), // Reduz o espaçamento
          Expanded(
            child: Text(
              title,
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
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.2).clamp(0.0, 1.0)).toColor(),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
