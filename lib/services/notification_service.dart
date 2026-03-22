import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'prove_daily_reminder';
  static const String _channelName = 'Lembretes Diários';
  static const String _channelDesc =
      'Canal para lembretes diários de leitura de ProVê.';
  
  // Usaremos IDs de 0 a 30 para os próximos 31 dias de notificações
  static const int _baseNotifId = 1000;

  static final Map<int, String> _chapterInspirations = {
    1: "O convite da sabedoria está à sua porta. Vamos ouvir?",
    2: "A sabedoria livra dos maus caminhos. Venha descobrir como.",
    3: "Confie no Senhor de todo o coração. Capítulo 3 te espera!",
    4: "Guarde o seu coração, pois dele brota a vida.",
    5: "Atenção aos seus passos e às suas escolhas hoje.",
    6: "Fuja da preguiça e do mal. A sabedoria te guia.",
    7: "Guarde os mandamentos como a menina dos seus olhos.",
    8: "A sabedoria clama nas ruas. Você está ouvindo?",
    9: "O banquete da sabedoria está preparado. Aceita o convite?",
    10: "A boca do justo é fonte de vida. Leia o capítulo 10.",
    11: "A integridade dos justos os guiará no dia de hoje.",
    12: "Quem ama a disciplina ama o conhecimento. Vamos aprender?",
    13: "O que guarda a sua boca preserva a sua vida.",
    14: "A mulher sábia edifica a sua casa. Sabedoria para o seu lar.",
    15: "A resposta branda desvia o furor. Aprenda a falar com sabedoria.",
    16: "O Senhor dirige os nossos passos. Confie no caminho.",
    17: "Melhor é um bocado seco com paz do que fartura com briga.",
    18: "O nome do Senhor é uma torre forte. Corra para Ele.",
    19: "A discrição do homem o torna paciente. Seja sábio hoje.",
    20: "O propósito no coração é como águas profundas.",
    21: "O Senhor pesa os corações. Busque a justiça e o juízo.",
    22: "Mais vale o bom nome do que as muitas riquezas.",
    23: "Dá-me, filho meu, o teu coração. Um chamado à entrega.",
    24: "Pela sabedoria se edifica a casa. Construa seu dia sobre ela.",
    25: "Como maçãs de ouro em salvas de prata é a palavra dita a seu tempo.",
    26: "Fuja da tolice e abrace a prudência no capítulo 26.",
    27: "Como o ferro com o ferro se afia, assim o homem ao seu amigo.",
    28: "O que confia no Senhor prosperará. Leia e medite.",
    29: "Onde não há visão, o povo se corrompe. Busque direção.",
    30: "As palavras de Agur: Equilíbrio e sabedoria para hoje.",
    31: "O valor de uma vida virtuosa. Inspire-se no capítulo 31.",
  };

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    _initialized = true;
  }

  List<int> _getChaptersForDate(DateTime date) {
    int day = date.day;
    int lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;

    if (day < lastDayOfMonth) {
      if (day > 31) return [31]; 
      return [day];
    } else {
      return List.generate(31 - day + 1, (index) => day + index);
    }
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (!_initialized) await init();

    await cancelAllNotifications();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Agendamos para os próximos 30 dias
    for (int i = 0; i < 30; i++) {
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute).add(Duration(days: i));
      
      if (scheduledDate.isBefore(now)) continue;

      final chapters = _getChaptersForDate(scheduledDate);
      String title = 'ProVê 📖 Provérbio ${chapters.join(' e ')}';
      String body = chapters.length > 1 
          ? "Dia de sabedoria extra! Leia os capítulos ${chapters.join(', ')} e complete o mês."
          : (_chapterInspirations[chapters.first] ?? 'Sua leitura diária de Provérbios está aguardando.');

      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _plugin.zonedSchedule(
        id: _baseNotifId + i,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
