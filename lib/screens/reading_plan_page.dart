import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReadingPlanPage extends StatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  // Variáveis para controlar o calendário
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Dados de exemplo (substitua com a lógica real do app)
  final Set<DateTime> _completedDays = {
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 3)),
    DateTime.now().subtract(const Duration(days: 4)),
    DateTime.now().subtract(const Duration(days: 8)),
  };

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
          ],
        ),
      ),
    );
  }

  // Widget para o calendário
  Widget _buildCalendar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'pt_BR', // Tradução para Português.
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
          // Estilização do calendário
          calendarBuilders: CalendarBuilders(
            // Marcador para dias com leitura completa
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

  // Widget para os cartões de progresso
  Widget _buildProgressCards(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildInfoCard(
          context,
          icon: Icons.local_fire_department,
          iconColor: Colors.orange,
          title: 'SEQUÊNCIA ATUAL',
          value: '3 dias',
          subtitle: 'Continue assim!',
          color: const Color(0xFFFFF3E0), // Laranja claro
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          context,
          icon: Icons.library_books,
          iconColor: Colors.blue.shade800,
          title: 'CAPÍTULOS LIDOS',
          value: '12 / 31',
          subtitle: 'Neste mês',
          color: Colors.blue.shade50, // Azul claro
        ),
      ],
    );
  }

  // Widget genérico para os cartões de informação
  Widget _buildInfoCard(
    BuildContext context,
    {
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
