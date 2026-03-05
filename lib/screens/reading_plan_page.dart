import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/progress_service.dart'; // Importe o serviço

class ReadingPlanPage extends StatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  final ProgressService _progressService = ProgressService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _completedDays = {};
  int _lastReadChapter = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final lastReadDate = await _progressService.getLastReadDate();
    final lastReadChapter = await _progressService.getLastReadChapter();
    final streak = await _progressService.getStreak();
    final completedDays = await _getCompletedDays();

    if (mounted) {
      setState(() {
        _selectedDay = lastReadDate;
        _lastReadChapter = lastReadChapter;
        _streak = streak;
        _completedDays = completedDays;
      });
    }
  }

  Future<Set<DateTime>> _getCompletedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final completedDays = <DateTime>{};
    for (String key in keys) {
      if (key.startsWith('read_')) {
        final dateString = key.substring(5);
        completedDays.add(DateTime.parse(dateString));
      }
    }
    return completedDays;
  }

  Future<void> _markTodayAsRead() async {
    final today = DateTime.now();
    final nextChapter = _lastReadChapter + 1;

    await _progressService.markAsRead(today, nextChapter);

    // Salvar o dia concluído para o calendário
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('read_${today.toIso8601String()}', true);

    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PLANO DE LEITURA',
              textAlign: TextAlign.center,
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe seu progresso e mantenha o hábito.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _buildCalendar(context),
            const SizedBox(height: 24),
            _buildProgressCards(context, textTheme, colorScheme),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _markTodayAsRead,
              child: const Text('Marcar Leitura de Hoje'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (_completedDays.any((d) => isSameDay(d, date))) {
                return Positioned(
                  bottom: 1,
                  child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                );
              }
              return null;
            },
          ),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCards(
      BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildInfoCard(
          context,
          icon: Icons.local_fire_department,
          iconColor: Colors.orange,
          title: 'SEQUÊNCIA ATUAL',
          value: '$_streak dias',
          subtitle: 'Continue assim!',
          color: const Color(0xFFFFF3E0),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          icon: Icons.library_books,
          iconColor: Colors.blue.shade800,
          title: 'CAPÍTULO ATUAL',
          value: '${_lastReadChapter + 1}',
          subtitle: 'Próximo capítulo para ler',
          color: Colors.blue.shade50,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: iconColor),
                ),
                const SizedBox(height: 4),
                Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
