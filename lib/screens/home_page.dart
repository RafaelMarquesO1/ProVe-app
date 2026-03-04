import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final chapter = DateTime.now().day; // Capítulo do dia

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SABEDORIA DIÁRIA',
              textAlign: TextAlign.center,
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Um provérbio por dia para um ano de sabedoria.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildVerseOfTheDayCard(context, textTheme, colorScheme),
            const SizedBox(height: 24),

            _buildRemindersCard(context, textTheme, colorScheme),
            const SizedBox(height: 24),

            _buildStreakCard(context, textTheme, colorScheme),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () => context.go('/reading'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('LER O PROVÉRBIO DE HOJE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERSÍCULO DO DIA',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            '"O que adquire sabedoria ama a sua alma; o que conserva o entendimento acha o bem."',
            style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Provérbios 19:8',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.go('/settings/reminders'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEMBRETE DIÁRIO',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('Toque para configurar', style: textTheme.bodyMedium),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    // Dados de exemplo para a sequência
    final List<bool> streakDays = [true, true, false, true, true, true, false];
    final List<String> weekDays = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Fundo verde claro
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEQUÊNCIA DE LEITURA',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('5 dias', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Mantenha o ritmo!', style: textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  Text(weekDays[index], style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Icon(
                    streakDays[index] ? Icons.check_circle : Icons.circle_outlined,
                    color: streakDays[index] ? Colors.green : Colors.grey[300],
                    size: 28,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}