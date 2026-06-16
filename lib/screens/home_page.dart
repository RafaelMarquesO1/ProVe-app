import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:prove/models/user_model.dart';
import 'package:prove/widgets/bounce_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:prove/services/progress_service.dart';
import 'package:prove/utils/theme_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ProgressService _progressService = ProgressService();
  Map<String, String> _verseOfTheDay = {};
  DateTime _selectedCalendarDay = DateTime.now();
  DateTime _focusedCalendarDay = DateTime.now();
  bool _isVerseLoadError = false;
  bool _showAnnualView = false;
  late final AnimationController _shimmerController;
  late final Stream<UserModel?> _userStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userStream = _progressService.userStream;
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
    '1:7',
    '2:6',
    '3:5',
    '3:6',
    '3:27',
    '4:23',
    '6:6',
    '8:17',
    '9:10',
    '10:12',
    '10:19',
    '12:1',
    '12:18',
    '14:1',
    '14:12',
    '15:1',
    '15:33',
    '16:3',
    '16:9',
    '16:24',
    '17:17',
    '18:10',
    '18:24',
    '19:17',
    '21:3',
    '22:1',
    '22:6',
    '23:26',
    '24:16',
    '27:17',
    '31:30',
    '16:18',
    '20:1',
    '28:13',
    '29:11',
  ];

  Future<void> _loadVerseOfTheDay() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/proverbiosBibliaLivre.json',
      );
      final proverbs = jsonDecode(jsonString) as List;

      final now = DateTime.now();
      // Usamos o dia do ano para garantir que o versículo seja o mesmo para todos no mesmo dia
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final index = (dayOfYear + now.year) % _curatedVerses.length;

      final randomRef = _curatedVerses[index];
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
    super.build(context);
    return StreamBuilder<UserModel?>(
      stream: _userStream,
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
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildContent(
            context,
            UserModel.empty(),
            showConnectionWarning: true,
          );
        }

        return _buildContent(context, snapshot.data!);
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

    String firstName = user.name.isNotEmpty
        ? user.name.split(' ')[0]
        : 'Leitor';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showConnectionWarning) ...[
              _buildConnectionWarning(context),
              const SizedBox(height: 24),
            ],
            // 1. Saudação Personalizada
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(firstName),
                  style: textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'O que a sabedoria tem para você hoje?',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Ação Principal (Ler Agora)
            _buildMainActionCard(context, user),
            const SizedBox(height: 24),

            // 3. Versículo de Inspiração
            _buildVerseOfTheDayCard(context, textTheme, colorScheme),
            const SizedBox(height: 24),

            // 4. Calendário
            _buildCalendarCard(
              context,
              textTheme,
              colorScheme,
              user.completedDays,
              firstName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionCard(BuildContext context, UserModel user) {
    // Verifica se o usuário já leu hoje
    final today = DateTime.now();
    final isCompletedToday = user.completedDays.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );

    final gradientColors = isCompletedToday
        ? [const Color(0xFF81C784), const Color(0xFF388E3C)] // Verde sucesso
        : [
            Theme.of(context).colorScheme.primary,
            const Color(0xFFD65108),
          ]; // Laranja vibrante

    final shadowColor = isCompletedToday
        ? const Color(0xFF388E3C)
        : const Color(0xFFD65108);

    return Semantics(
      button: true,
      label: isCompletedToday
          ? 'Abrir leitura já concluída hoje'
          : 'Abrir leitura diária de Provérbios',
      child: BounceButton(
        onTap: () => context.push('/reading'),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(
                0,
                4 * (1 - (2 * value - 1).abs()),
              ), // Efeito de flutuação suave
              child: child,
            );
          },
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
                ),
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
                    isCompletedToday
                        ? Icons.check_circle_rounded
                        : Icons.menu_book_rounded,
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
                        isCompletedToday
                            ? 'Leitura Concluída!'
                            : 'Ler Provérbio de Hoje',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompletedToday
                            ? 'Você já fortaleceu sua mente hoje. Toque para rever.'
                            : 'Toque aqui para fazer sua leitura diária.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseOfTheDayCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        if (_verseOfTheDay.isNotEmpty) {
          Clipboard.setData(
            ClipboardData(
              text:
                  '"${_verseOfTheDay['text']}" - ${_verseOfTheDay['reference']}',
            ),
          );
          HapticFeedback.mediumImpact();
          AppAlerts.showSnackBar(
            context,
            message: 'Versículo copiado com sucesso!',
            type: AppAlertType.success,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.format_quote_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Inspiração do Dia',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                      onPressed: _shareVerse,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _isVerseLoadError
                  ? 'Não foi possível carregar o versículo agora.'
                  : (_verseOfTheDay['text'] ?? 'Buscando sabedoria...'),
              style: textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
                fontSize: 17,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _verseOfTheDay['reference'] ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Toque para copiar',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<DateTime> completedDays,
    String firstName,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarHeader(context, textTheme, colorScheme),
          const SizedBox(height: 20),
          _buildCalendarViewToggle(context, colorScheme),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: _showAnnualView
                ? _buildAnnualCalendarView(
                    context,
                    textTheme,
                    colorScheme,
                    completedDays,
                    firstName,
                  )
                : _buildMonthlyCalendarView(
                    context,
                    textTheme,
                    colorScheme,
                    completedDays,
                    firstName,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu Desempenho',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarViewToggle(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeColors.getLightBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: BounceButton(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showAnnualView = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showAnnualView
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Mensal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: !_showAnnualView
                          ? colorScheme.onPrimary
                          : ThemeColors.getSecondaryTextColor(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: BounceButton(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showAnnualView = true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showAnnualView
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Anual',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _showAnnualView
                          ? colorScheme.onPrimary
                          : ThemeColors.getSecondaryTextColor(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendarView(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<DateTime> completedDays,
    String firstName,
  ) {
    // Cálculo preciso das estatísticas do mês
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final completedDaysSet = completedDays
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final highlightColor = colorScheme.primary;

    // Estatísticas baseadas no mês focado no calendário
    final focusedYear = _focusedCalendarDay.year;
    final focusedMonth = _focusedCalendarDay.month;
    final lastDayOfFocusedMonth = DateTime(focusedYear, focusedMonth + 1, 0);
    final daysInMonth = lastDayOfFocusedMonth.day;
    final daysInMonthList = List.generate(
      daysInMonth,
      (i) => DateTime(focusedYear, focusedMonth, i + 1),
    );

    final completedThisMonth = completedDaysSet
        .where((d) => d.year == focusedYear && d.month == focusedMonth)
        .length;
    final lostThisMonth = daysInMonthList
        .where(
          (d) => d.isBefore(todayMidnight) && !completedDaysSet.contains(d),
        )
        .length;
    final remainingThisMonth = daysInMonthList
        .where(
          (d) =>
              (d.isAfter(todayMidnight) || isSameDay(d, todayMidnight)) &&
              !completedDaysSet.contains(d),
        )
        .length;
    final monthPercent = daysInMonth > 0 ? ((completedThisMonth / daysInMonth) * 100).round() : 0;

    return Column(
      key: ValueKey('monthly_${_focusedCalendarDay.month}'),
      children: [
        // Percentage Badge
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
                color: (monthPercent >= 80
                        ? const Color(0xFF2E7D32)
                        : colorScheme.primary)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$monthPercent%',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime.utc(now.year, 1, 1),
          lastDay: DateTime.utc(now.year, 12, 31),
          focusedDay: _focusedCalendarDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedCalendarDay),
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedCalendarDay = focusedDay;
            });
          },
          onDaySelected: (selectedDay, focusedDay) {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedCalendarDay = selectedDay;
              _focusedCalendarDay = focusedDay;
            });

            final dayOnly = DateTime(
              selectedDay.year,
              selectedDay.month,
              selectedDay.day,
            );
            final isCompleted = completedDaysSet.contains(dayOnly);
            final isToday = isSameDay(selectedDay, now);
            final isFuture = dayOnly.isAfter(todayMidnight);

            final chapters = _progressService.getChaptersForDate(selectedDay);
            final String chaptersText = chapters.length > 1
                ? 'Capítulos ${chapters.join(' e ')}'
                : 'Capítulo ${chapters.first}';

            String statusTitle = '';
            String statusDesc = '';
            IconData statusIcon = Icons.info_outline;
            Color statusColor = Colors.blue;

            if (isCompleted) {
              statusTitle = 'Concluído';
              statusDesc =
                  'Capítulo(s) ${chapters.length > 1 ? 'de ${chapters.first} a ${chapters.last}' : chapters.first} lido(s) em ${selectedDay.day}/${selectedDay.month}.';
              statusIcon = Icons.check_circle_rounded;
              statusColor = const Color(0xFF388E3C);
            } else if (isFuture) {
              statusTitle = 'Por vir';
              statusDesc =
                  'Capítulo(s) ${chapters.length > 1 ? 'de ${chapters.first} a ${chapters.last}' : chapters.first} agendado(s) para ${selectedDay.day}/${selectedDay.month}.';
              statusIcon = Icons.event_note_rounded;
              statusColor = Colors.blueGrey;
            } else if (isToday) {
              statusTitle = 'Hoje';
              statusDesc =
                  'Leitura de hoje: capítulo(s) ${chapters.length > 1 ? 'de ${chapters.first} a ${chapters.last}' : chapters.first}. Comece agora?';
              statusIcon = Icons.local_fire_department_rounded;
              statusColor = colorScheme.primary;
            } else {
              statusTitle = 'Não realizado';
              statusDesc =
                  'Capítulo(s) ${chapters.length > 1 ? 'de ${chapters.first} a ${chapters.last}' : chapters.first} não foram lidos em ${selectedDay.day}/${selectedDay.month}.';
              statusIcon = Icons.block_flipped;
              statusColor = Colors.red.shade300;
            }

            AppAlerts.showCustomDialog(
              context: context,
              title: statusTitle,
              message: statusDesc,
              icon: statusIcon,
              iconColor: statusColor,
              confirmText: isToday && !isCompleted ? 'LER AGORA' : 'FECHAR',
              cancelText: isToday && !isCompleted ? 'MAIS TARDE' : null,
              onConfirm: () {
                if (isToday && !isCompleted) {
                  context.push('/reading');
                }
              },
            );
          },
          onDayLongPressed: (selectedDay, focusedDay) {
            HapticFeedback.heavyImpact();
            final chapters = _progressService.getChaptersForDate(selectedDay);
            final String chaptersText = chapters.length > 1
                ? 'Capítulos ${chapters.join(' e ')}'
                : 'Capítulo ${chapters.first}';

            AppAlerts.showSnackBar(
              context,
              message: 'Pressione para ler o $chaptersText',
              type: AppAlertType.info,
            );
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: colorScheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
            ),
            headerPadding: const EdgeInsets.only(bottom: 16),
          ),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekHeight: 32,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
            weekendStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            prioritizedBuilder: (context, day, focusedDay) {
              final dayOnly = DateTime(day.year, day.month, day.day);
              final isCompleted = completedDaysSet.contains(dayOnly);
              final isToday = isSameDay(day, now);
              final isFuture = dayOnly.isAfter(todayMidnight);
              final isOutside = day.month != focusedDay.month;
              final isSelected = isSameDay(day, _selectedCalendarDay);

              if (isOutside) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Colors.grey.shade200,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: GestureDetector(
                    onTapDown: (_) =>
                        HapticFeedback.selectionClick(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted
                            ? null
                            : (isToday
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : (isSelected
                                        ? colorScheme.primary.withOpacity(0.05)
                                        : Colors.transparent)),
                        border: isFuture
                            ? Border.all(
                                color: ThemeColors.getDividerColor(context),
                                width: 1,
                              )
                            : null,
                        boxShadow: isCompleted || isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(
                                Icons.check_rounded,
                                color: colorScheme.onPrimary,
                                size: 18,
                              )
                            : Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isToday || isSelected
                                      ? colorScheme.primary
                                      : (!isFuture && !isCompleted
                                            ? Colors.red.shade200
                                            : colorScheme.onSurface),
                                  fontWeight: isToday ||
                                          isCompleted ||
                                          isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  decoration: !isFuture &&
                                          !isToday &&
                                          !isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.red.shade100,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Centro de Controle de Progresso
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: monthPercent >= 100
                ? Border.all(color: Colors.amber.shade300, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: monthPercent >= 100
                    ? Colors.amber.withOpacity(0.15)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: monthPercent.toDouble(),
                    ),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: value / 100,
                              strokeWidth: 8,
                              backgroundColor: colorScheme.primary
                                  .withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${value.round()}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Text(
                                'META',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(
                          '${_focusedCalendarDay.month}_$monthPercent',
                        ),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMotivationalTitle(
                              monthPercent,
                              lostThisMonth,
                              firstName,
                              todayMidnight,
                              daysInMonthList.first,
                            ),
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(
                              begin: 0,
                              end: _getMotivationalDescription(
                                monthPercent,
                                lostThisMonth,
                                firstName,
                                todayMidnight,
                                daysInMonthList.first,
                              ).length,
                            ),
                            duration: const Duration(seconds: 2),
                            builder: (context, length, child) {
                              final fullText = _getMotivationalDescription(
                                monthPercent,
                                lostThisMonth,
                                firstName,
                                todayMidnight,
                                daysInMonthList.first,
                              );
                              return Text(
                                fullText.substring(0, length),
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                  height: 1.3,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: ThemeColors.getLightBackground(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Lidos',
                        value: '$completedThisMonth',
                        color: colorScheme.primary,
                        onTap: () {
                          AppAlerts.showCustomDialog(
                            context: context,
                            title: 'Leituras Concluídas',
                            message:
                                'Você já completou $completedThisMonth capítulos este mês. Cada um deles contribuiu para sua sabedoria!',
                            icon: Icons.auto_awesome_rounded,
                            iconColor: colorScheme.primary,
                            confirmText: 'CONTINUAR',
                            onConfirm: () {},
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: ThemeColors.getDividerColor(context),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Perdidos',
                        value: '$lostThisMonth',
                        color: Colors.red.shade300,
                        onTap: () {
                          AppAlerts.showCustomDialog(
                            context: context,
                            title: 'Dias Perdidos',
                            message: lostThisMonth > 0
                                ? 'Não desanime por esses $lostThisMonth dias! A sabedoria é uma jornada de persistência, não de perfeição.'
                                : 'Incrível! Você não perdeu nenhum dia este mês. Mantenha essa disciplina!',
                            icon: Icons.refresh_rounded,
                            iconColor: Colors.red.shade300,
                            confirmText: 'ENTENDI',
                            onConfirm: () {},
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: ThemeColors.getDividerColor(context),
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Restantes',
                        value: '$remainingThisMonth',
                        color: Colors.amber.shade700,
                        onTap: () {
                          final nextChapters = _progressService
                              .getChaptersForDate(now);
                          AppAlerts.showCustomDialog(
                            context: context,
                            title: 'Próximos Passos',
                            message:
                                'Ainda restam $remainingThisMonth dias de leitura. O próximo foco é o capítulo ${nextChapters.isNotEmpty ? nextChapters.first : ''}!',
                            icon: Icons.trending_up_rounded,
                            iconColor: Colors.amber.shade700,
                            confirmText: 'LER AGORA',
                            onConfirm: () => context.push('/reading'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Lido', colorScheme.primary, isIcon: true),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                    'Hoje',
                    colorScheme.primary,
                    isToday: true,
                  ),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                    'Perdido',
                    Colors.red.shade300,
                    isLost: true,
                  ),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                    'Futuro',
                    Colors.grey.shade200,
                    isFuture: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnualCalendarView(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    List<DateTime> completedDays,
    String firstName,
  ) {
    final now = DateTime.now();
    final completedDaysSet = completedDays
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    // Estatísticas do ano inteiro
    final allDaysInYear = List.generate(
      DateTime(now.year, 12, 31).difference(DateTime(now.year, 1, 1)).inDays + 1,
      (i) => DateTime(now.year, 1, 1).add(Duration(days: i)),
    );

    final completedThisYear = completedDaysSet.where((d) => d.year == now.year).length;
    final yearPercent = allDaysInYear.isNotEmpty ? ((completedThisYear / allDaysInYear.length) * 100).round() : 0;

    return Column(
      key: const ValueKey('annual'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: yearPercent >= 80
                  ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
                  : [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$yearPercent%',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visão Anual de $firstName',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$completedThisYear de ${allDaysInYear.length} dias completados',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Progresso consistente em sua jornada de leitura ao longo do ano.',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month - 1];
  }

  Color _getHeatmapColor(int percent, ColorScheme colorScheme) {
    if (percent >= 90) {
      return const Color(0xFF1B5E20);
    } else if (percent >= 70) {
      return const Color(0xFF2E7D32);
    } else if (percent >= 50) {
      return const Color(0xFF558B2F);
    } else if (percent >= 30) {
      return const Color(0xFFF57F17);
    } else if (percent > 0) {
      return const Color(0xFFE65100);
    } else {
      return Colors.grey.shade400;
    }
  }

  String _getMotivationalTitle(
    int percent,
    int lost,
    String name,
    DateTime today,
    DateTime monthStart,
  ) {
    if (monthStart.isAfter(today)) {
      return 'Próximo mês em breve';
    }
    if (percent >= 100) {
      return 'Mês completo';
    }
    if (lost > 0) {
      if (lost <= 3) return 'Poucos deslizes';
      if (lost <= 10) return 'Recupere o ritmo';
      return 'Novo recomeço';
    }
    if (percent > 0) return 'No caminho certo';
    return 'Comece hoje';
  }

  String _getMotivationalDescription(
    int percent,
    int lost,
    String name,
    DateTime today,
    DateTime monthStart,
  ) {
    if (monthStart.isAfter(today)) {
      return 'Aproveite o tempo para planejar sua rotina de leitura.';
    }
    if (percent >= 100) {
      return 'Todos os dias deste mês foram preenchidos com dedicação.';
    }
    if (lost > 0) {
      if (lost <= 3) {
        return 'Apenas $lost dia(s) não preenchido(s). Mantenha a disciplina.';
      }
      if (lost <= 10) {
        return '$lost dias ainda podem ser retomados. Volte ao ritmo.';
      }
      return 'Com $lost dias perdidos, agora é tempo de recomeçar com força.';
    }
    if (percent > 0) {
      return 'Sem dias perdidos até agora. Mantenha a consistência.';
    }
    return 'Cada dia lido é um passo em direção ao conhecimento.';
  }

  Widget _buildCalendarStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color, {
    bool isIcon = false,
    bool isToday = false,
    bool isLost = false,
    bool isFuture = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isIcon
                ? color
                : (isToday ? color.withOpacity(0.1) : Colors.transparent),
            border: isToday
                ? Border.all(color: color, width: 1.5)
                : (isLost || isFuture
                      ? Border.all(color: color, width: 1.2)
                      : null),
          ),
          child: isIcon
              ? const Icon(Icons.check, color: Colors.white, size: 8)
              : (isLost
                    ? Center(
                        child: Container(width: 6, height: 1.2, color: color),
                      )
                    : null),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Conexão instável. Alguns dados podem estar desatualizados.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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

class _StatItem extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: widget.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
