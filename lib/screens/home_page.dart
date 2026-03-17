import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> _verseOfTheDay = {};

  @override
  void initState() {
    super.initState();
    _loadVerseOfTheDay();
  }

  Future<void> _loadVerseOfTheDay() async {
    final jsonString = await rootBundle.loadString('assets/proverbios.json');
    final proverbs = jsonDecode(jsonString) as List;

    // Seleciona um capítulo aleatório
    final randomChapterIndex = Random().nextInt(proverbs.length);
    final chapterData = proverbs[randomChapterIndex];
    final chapterNumberString = chapterData.keys.first;
    final chapterContent = chapterData[chapterNumberString] as Map<String, dynamic>;

    // Seleciona um versículo aleatório do capítulo
    final verseKeys = chapterContent.keys.toList();
    final randomVerseKey = verseKeys[Random().nextInt(verseKeys.length)];
    final verseText = chapterContent[randomVerseKey];

    setState(() {
      _verseOfTheDay = {
        'text': verseText,
        'reference': 'Provérbios $chapterNumberString:$randomVerseKey',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para começar.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildContent(context, UserModel.empty()); 
        }

        final user = UserModel.fromFirestore(snapshot.data!);
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
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
            _buildCalendarCard(context, textTheme, colorScheme, user.readingStreak, user.completedDays),
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
            _verseOfTheDay['text'] ?? 'Carregando versículo...',
            style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            _verseOfTheDay['reference'] ?? '',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme, int streak, List<DateTime> completedDays) {
    final today = DateTime.now();
    final completedDaysSet = completedDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    const highlightColor = Color(0xFFD98F2B); // Laranja para dias completos

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), 
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: highlightColor, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streak dias de ofensiva', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Seu progresso de leitura:', style: textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(today.year, 1, 1),
            lastDay: DateTime.utc(today.year, 12, 31),
            focusedDay: today,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                // Normaliza o dia para ignorar a hora na comparação
                final dayOnly = DateTime(day.year, day.month, day.day);
                final isCompleted = completedDaysSet.contains(dayOnly);
                final isToday = isSameDay(day, today);

                // 1. Dia completo e lido
                if (isCompleted) {
                  return Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: highlightColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                // 2. Dia de hoje (ainda não lido)
                if (isToday) {
                  return Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.primary, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                // 3. Outros dias (retorna null para usar o builder padrão)
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
