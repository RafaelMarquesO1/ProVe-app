import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/user_model.dart';

class ReadingPlanPage extends StatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late final DocumentReference<Map<String, dynamic>> _userDocRef;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userDocRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    }
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: Text('Faça login para ver seu plano.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Exibe um estado "vazio" mas funcional se o usuário ainda não tiver dados
          return _buildEmptyState();
        }

        final user = UserModel.fromFirestore(snapshot.data!);

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PLANO DE LEITURA', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Acompanhe seu progresso e mantenha o hábito.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 24),
                _buildCalendar(context, user.completedDays.toSet()),
                const SizedBox(height: 24),
                // Passa o total de dias lidos para o card de progresso
                _buildProgressCards(context, user.readingStreak, user.completedDays.length),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Widget para o estado vazio
  Widget _buildEmptyState() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PLANO DE LEITURA', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text('Acompanhe seu progresso e mantenha o hábito.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 24),
            _buildCalendar(context, {}), // Calendário vazio
            const SizedBox(height: 24),
            _buildProgressCards(context, 0, 0), // Cards com valores zerados
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Set<DateTime> completedDays) {
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
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) => completedDays.where((d) => isSameDay(d, day)).toList(),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
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
              if (events.isNotEmpty) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: _buildEventsMarker(),
                );
              }
              return null;
            },
          ),
          headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            weekendTextStyle: TextStyle(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarker() {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
      width: 8.0,
      height: 8.0,
    );
  }

  // Atualiza a assinatura da função para receber o total de dias lidos
  Widget _buildProgressCards(BuildContext context, int streak, int totalDaysRead) {
    return Column(
      children: [
        _buildInfoCard(context, icon: Icons.local_fire_department, iconColor: Colors.orange, title: 'SEQUÊNCIA ATUAL', value: '$streak dias', subtitle: 'Continue assim!', color: const Color(0xFFFFF3E0)),
        const SizedBox(height: 16),
        // O card agora exibe o total de dias lidos
        _buildInfoCard(context, icon: Icons.check_circle, iconColor: Colors.green.shade800, title: 'DIAS LIDOS', value: '$totalDaysRead', subtitle: 'Total de dias de leitura', color: Colors.green.shade50),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String value, required String subtitle, required Color color}) {
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
                Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: iconColor)),
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
