
import 'package:flutter/material.dart';

class RemindersSettingsPage extends StatefulWidget {
  const RemindersSettingsPage({super.key});

  @override
  State<RemindersSettingsPage> createState() => _RemindersSettingsPageState();
}

class _RemindersSettingsPageState extends State<RemindersSettingsPage> {
  bool _notificationsEnabled = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0); // Horário padrão

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lembretes de Leitura', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Ativar notificações', style: TextStyle(fontSize: 16)),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications_active_outlined),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            title: const Text('Horário do lembrete', style: TextStyle(fontSize: 16)),
            subtitle: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14)),
            leading: const Icon(Icons.access_time_outlined),
            onTap: () => _selectTime(context),
            enabled: _notificationsEnabled,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Lógica para salvar as configurações
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações salvas!')),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
