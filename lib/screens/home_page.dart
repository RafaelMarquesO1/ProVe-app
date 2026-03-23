import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:share_plus/share_plus.dart';
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

  // Lista curada de provérbios que trazem ensinamentos profundos
  static const List<String> _curatedVerses = [
    '1:7', '2:6', '3:5', '3:6', '3:27', '4:23', '6:6', '8:17', '9:10', '10:12',
    '10:19', '12:1', '12:18', '14:1', '14:12', '15:1', '15:33', '16:3', '16:9',
    '16:24', '17:17', '18:10', '18:24', '19:17', '21:3', '22:1', '22:6', '23:26',
    '24:16', '27:17', '31:30', '16:18', '20:1', '28:13', '29:11'
  ];

  Future<void> _loadVerseOfTheDay() async {
    final jsonString = await rootBundle.loadString('assets/proverbiosBibliaLivre.json');
    final proverbs = jsonDecode(jsonString) as List;

    // Seleciona um provérbio da nossa lista curada
    final randomRef = _curatedVerses[Random().nextInt(_curatedVerses.length)];
    final parts = randomRef.split(':');
    final chapterNum = parts[0];
    final verseNum = parts[1];

    // Encontra o capítulo no JSON
    final chapterData = proverbs.firstWhere(
      (element) => element.containsKey(chapterNum),
      orElse: () => null,
    );

    if (chapterData != null) {
      final verseText = chapterData[chapterNum][verseNum];
      setState(() {
        _verseOfTheDay = {
          'text': verseText,
          'reference': 'Provérbios $chapterNum:$verseNum',
        };
      });
    }
  }

  void _shareVerse() {
    if (_verseOfTheDay.isNotEmpty) {
      final text = _verseOfTheDay['text']!;
      final reference = _verseOfTheDay['reference']!;
      SharePlus.instance.share(ShareParams(text: '"$text" - $reference\n\nCompartilhado pelo app ProVê.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para começar.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).snapshots(),
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

    String firstName = user.name.isNotEmpty ? user.name.split(' ')[0] : 'Leitor';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Saudação Personalizada
            Text(
              'Olá, $firstName!',
              style: textTheme.displayLarge?.copyWith(fontSize: 32),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),
            Text(
              'O que a sabedoria tem para você hoje?',
              style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 32),

            // 2. Ação Principal (Ler Agora)
            _buildMainActionCard(context, user),
            const SizedBox(height: 24),

            // 3. Versículo de Inspiração
            _buildVerseOfTheDayCard(context, textTheme, colorScheme),
            const SizedBox(height: 24),

            // 4. Calendário
            _buildCalendarCard(context, textTheme, colorScheme, user.completedDays),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionCard(BuildContext context, UserModel user) {
    // Verifica se o usuário já leu hoje
    final today = DateTime.now();
    final isCompletedToday = user.completedDays.any((d) =>
        d.year == today.year && d.month == today.month && d.day == today.day);

    final gradientColors = isCompletedToday
        ? [const Color(0xFF81C784), const Color(0xFF388E3C)] // Verde sucesso
        : [Theme.of(context).colorScheme.primary, const Color(0xFFD65108)]; // Laranja vibrante

    final shadowColor = isCompletedToday ? const Color(0xFF388E3C) : const Color(0xFFD65108);

    return BounceButton(
      onTap: () => context.go('/reading'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompletedToday ? Icons.check_circle_rounded : Icons.menu_book_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    isCompletedToday ? 'Leitura Concluída!' : 'Ler Provérbio de Hoje',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompletedToday ? 'Você já fortaleceu sua mente hoje. Toque para rever.' : 'Toque aqui para fazer sua leitura diária.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote_rounded, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Inspiração do Dia',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: Colors.grey.shade500, size: 22),
                onPressed: _shareVerse,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _verseOfTheDay['text'] ?? 'Buscando sabedoria...',
            style: textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic, 
              height: 1.6, 
              fontSize: 16, 
              color: Colors.black87
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _verseOfTheDay['reference'] ?? '',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme, List<DateTime> completedDays) {
    final today = DateTime.now();
    final completedDaysSet = completedDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    final highlightColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
            'Calendário do Mês',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
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
              weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400),
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                final dayOnly = DateTime(day.year, day.month, day.day);
                final isCompleted = completedDaysSet.contains(dayOnly);
                final isToday = isSameDay(day, today);

                if (isCompleted) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: highlightColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
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

                if (isToday) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: highlightColor, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Reutilizando o mesmo botão com o efeito de contração/mola criado na tela de Ofensiva.
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
