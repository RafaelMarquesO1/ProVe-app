import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/bounce_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> _verseOfTheDay = {};
  bool _isVerseLoadError = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadVerseOfTheDay();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // Lista curada de provérbios que trazem ensinamentos profundos
  static const List<String> _curatedVerses = [
    '1:7', '2:6', '3:5', '3:6', '3:27', '4:23', '6:6', '8:17', '9:10', '10:12',
    '10:19', '12:1', '12:18', '14:1', '14:12', '15:1', '15:33', '16:3', '16:9',
    '16:24', '17:17', '18:10', '18:24', '19:17', '21:3', '22:1', '22:6', '23:26',
    '24:16', '27:17', '31:30', '16:18', '20:1', '28:13', '29:11'
  ];

  Future<void> _loadVerseOfTheDay() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/proverbiosBibliaLivre.json');
      final proverbs = jsonDecode(jsonString) as List;

      final randomRef = _curatedVerses[Random().nextInt(_curatedVerses.length)];
      final parts = randomRef.split(':');
      final chapterNum = parts[0];
      final verseNum = parts[1];

      final chapterData = proverbs.firstWhere(
        (element) => element.containsKey(chapterNum),
        orElse: () => null,
      );

      if (!mounted) return;

      if (chapterData != null) {
        final verseText = chapterData[chapterNum][verseNum];
        setState(() {
          _isVerseLoadError = false;
          _verseOfTheDay = {
            'text': verseText,
            'reference': 'Provérbios $chapterNum:$verseNum',
          };
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerseLoadError = true);
    }
  }

  void _shareVerse() {
    if (_verseOfTheDay.isNotEmpty) {
      final text = _verseOfTheDay['text']!;
      final reference = _verseOfTheDay['reference']!;
      Share.share('"$text" - $reference\n\nCompartilhado pelo app ProVê.');
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
          return _buildLoadingState(context);
        }
        if (snapshot.hasError) {
          return _buildContent(
            context,
            UserModel.empty(),
            showConnectionWarning: true,
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildContent(
            context,
            UserModel.empty(),
            showConnectionWarning: true,
          );
        }

        final user = UserModel.fromFirestore(snapshot.data!);
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserModel user, {
    bool showConnectionWarning = false,
  }) {
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
            if (showConnectionWarning) ...[
              _buildConnectionWarning(context),
              const SizedBox(height: 24),
            ],
            // 1. Saudação Personalizada
            Text(
              _getGreeting(firstName),
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

    return Semantics(
      button: true,
      label: isCompletedToday
          ? 'Abrir leitura já concluída hoje'
          : 'Abrir leitura diária de Provérbios',
      child: BounceButton(
        onTap: () => context.push('/reading'),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade500, size: 22),
                    onPressed: _loadVerseOfTheDay,
                    tooltip: 'Novo versículo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.share_rounded, color: Colors.grey.shade500, size: 22),
                    onPressed: _shareVerse,
                    tooltip: 'Compartilhar versículo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isVerseLoadError
                ? 'Não foi possível carregar o versículo de hoje agora. Tente novamente mais tarde.'
                : (_verseOfTheDay['text'] ?? 'Buscando sabedoria...'),
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

    // Calcular % de conclusão do mês
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final completedThisMonth = completedDaysSet.where((d) => d.year == today.year && d.month == today.month).length;
    final monthPercent = ((completedThisMonth / daysInMonth) * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu Desempenho',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(
                      '$completedThisMonth de $daysInMonth dias lidos',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: monthPercent >= 80 
                        ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                        : [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (monthPercent >= 80 ? const Color(0xFF2E7D32) : colorScheme.primary).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  '$monthPercent%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(today.year, 1, 1),
            lastDay: DateTime.utc(today.year, 12, 31),
            focusedDay: today,
            selectedDayPredicate: (day) => isSameDay(day, today),
            onDaySelected: (selectedDay, focusedDay) {
              final dayOnly = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              final isCompleted = completedDaysSet.contains(dayOnly);
              final isFuture = selectedDay.isAfter(today);
              final isToday = isSameDay(selectedDay, today);
              
              String statusTitle = '';
              String statusDesc = '';
              IconData statusIcon = Icons.info_outline;
              Color statusColor = Colors.blue;

              if (isCompleted) {
                statusTitle = 'Leitura Concluída';
                statusDesc = 'No dia ${selectedDay.day}/${selectedDay.month} você concluiu a leitura do capítulo ${selectedDay.day}. Excelente hábito!';
                statusIcon = Icons.check_circle_rounded;
                statusColor = const Color(0xFF388E3C);
              } else if (isFuture) {
                statusTitle = 'Futura Leitura';
                statusDesc = 'Prepare o seu coração! No dia ${selectedDay.day}/${selectedDay.month} você lerá o capítulo ${selectedDay.day}.';
                statusIcon = Icons.event_note_rounded;
                statusColor = Colors.blueGrey;
              } else if (isToday) {
                statusTitle = 'Hoje é o Dia!';
                statusDesc = 'Você ainda não registrou a leitura de hoje (Capítulo ${selectedDay.day}). Que tal ler agora?';
                statusIcon = Icons.local_fire_department_rounded;
                statusColor = colorScheme.primary;
              } else {
                statusTitle = 'Leitura Pendente';
                statusDesc = 'Infelizmente você não registrou a leitura no dia ${selectedDay.day}/${selectedDay.month}. Mas não desanime, o importante é continuar hoje!';
                statusIcon = Icons.history_rounded;
                statusColor = Colors.orange;
              }

              AppAlerts.showCustomDialog(
                context: context,
                title: statusTitle,
                message: statusDesc,
                icon: statusIcon,
                iconColor: statusColor,
                confirmText: isCompleted || isFuture ? 'FECHAR' : 'LER AGORA',
                cancelText: isCompleted || isFuture ? null : 'MAIS TARDE',
                onConfirm: () {
                  if (!isCompleted && !isFuture) {
                    context.push('/reading');
                  }
                },
              );
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900, color: Colors.black87),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
              headerPadding: const EdgeInsets.only(bottom: 16),
            ),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekHeight: 32,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400, fontSize: 12),
              weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary.withOpacity(0.4), fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                final dayOnly = DateTime(day.year, day.month, day.day);
                final isCompleted = completedDaysSet.contains(dayOnly);
                final isToday = isSameDay(day, today);
                final isOutside = day.month != focusedDay.month;

                if (isCompleted) {
                  return Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  );
                }

                if (isToday) {
                  return Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        border: Border.all(color: colorScheme.primary, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                if (isOutside) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
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

  Widget _buildConnectionWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Conexão instável. Alguns dados podem estar desatualizados.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Bom dia, $name!';
    } else if (hour >= 12 && hour < 18) {
      return 'Boa tarde, $name!';
    } else {
      return 'Boa noite, $name!';
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _shimmerLine(width: 170, height: 30),
                const SizedBox(height: 12),
                _shimmerLine(width: 240, height: 16),
                const SizedBox(height: 32),
                _shimmerBox(height: 132),
                const SizedBox(height: 24),
                _shimmerBox(height: 190),
                const SizedBox(height: 24),
                _shimmerBox(height: 340),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerLine({required double width, required double height}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
            end: Alignment(1.0 + 2 * _shimmerController.value, 0),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.0 + 2 * _shimmerController.value, 0),
          end: Alignment(1.0 + 2 * _shimmerController.value, 0),
        ),
      ),
    );
  }
}
