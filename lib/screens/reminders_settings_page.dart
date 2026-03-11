import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:myapp/services/notification_service.dart'; // Temporariamente desativado
import 'package:shared_preferences/shared_preferences.dart';

class RemindersSettingsPage extends StatefulWidget {
  const RemindersSettingsPage({super.key});

  @override
  State<RemindersSettingsPage> createState() => _RemindersSettingsPageState();
}

class _RemindersSettingsPageState extends State<RemindersSettingsPage> {
  bool _areRemindersEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0); // Horário padrão
  // final NotificationService _notificationService = NotificationService(); // Temporariamente desativado

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _areRemindersEnabled = prefs.getBool('remindersEnabled') ?? false;
      final hour = prefs.getInt('reminderHour') ?? 8;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', _areRemindersEnabled);
    await prefs.setInt('reminderHour', _selectedTime.hour);
    await prefs.setInt('reminderMinute', _selectedTime.minute);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateNotification();
    }
  }

  void _updateNotification() {
    _saveSettings();
    // Lógica de notificação temporariamente desativada
    /*
    if (_areRemindersEnabled) {
      _notificationService.scheduleDailyProverbReminder(_selectedTime);
    } else {
      _notificationService.cancelAllNotifications();
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lembretes', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Ativar Lembretes Diários', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                value: _areRemindersEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _areRemindersEnabled = value;
                  });
                  _updateNotification();
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                title: const Text('Horário do Lembrete'),
                trailing: Text(
                  _selectedTime.format(context),
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                onTap: _pickTime,
                enabled: _areRemindersEnabled,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
