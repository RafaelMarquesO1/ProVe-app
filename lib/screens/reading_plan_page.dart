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
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data!.exists ? UserModel.fromFirestore(snapshot.data!) : UserModel.empty();
        
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Ofensiva Atual', '${user.readingStreak} dias', Icons.local_fire_department, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(context, 'Maior Ofensiva', '${user.longestStreak} dias', Icons.star, Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Total Lido', '${user.completedDays.length} dias', Icons.check_circle, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(context, 'Membro Desde', user.getMemberSince(), Icons.calendar_today, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
