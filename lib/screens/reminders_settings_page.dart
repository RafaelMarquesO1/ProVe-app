import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemindersSettingsPage extends StatefulWidget {
  final int returnIndex;

  const RemindersSettingsPage({super.key, this.returnIndex = 0});

  @override
  State<RemindersSettingsPage> createState() => _RemindersSettingsPageState();
}

class _RemindersSettingsPageState extends State<RemindersSettingsPage> {
  bool _areRemindersEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _areRemindersEnabled = prefs.getBool('remindersEnabled') ?? false;
      final hour = prefs.getInt('reminderHour') ?? 8;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindersEnabled', _areRemindersEnabled);
    await prefs.setInt('reminderHour', _selectedTime.hour);
    await prefs.setInt('reminderMinute', _selectedTime.minute);
  }

  Future<void> _toggleReminders(bool value) async {
    // Captura o contexto antes de operações async
    final timeStr = _selectedTime.format(context);
    setState(() {
      _areRemindersEnabled = value;
      _isSaving = true;
    });

    await _saveSettings();

    try {
      if (value) {
        await _notificationService.scheduleDailyReminder(_selectedTime);
        if (!mounted) return;
        _showSnackBar('✅ Lembrete ativado para $timeStr', isSuccess: true);
      } else {
        await _notificationService.cancelAllNotifications();
        if (!mounted) return;
        _showSnackBar('🔕 Lembretes desativados.', isSuccess: false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao configurar notificação: $e', isError: true);
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _isSaving = true;
      });
      await _saveSettings();

      if (_areRemindersEnabled) {
        try {
          await _notificationService.scheduleDailyReminder(_selectedTime);
          if (mounted) {
            _showSnackBar(
              '✅ Horário atualizado para ${picked.format(context)}',
              isSuccess: true,
            );
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar('Erro ao atualizar notificação: $e', isError: true);
          }
        }
      }

      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg,
      {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade700
            : isSuccess
                ? Colors.green.shade700
                : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lembretes',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home', extra: {'index': widget.returnIndex});
            }
          },
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LEMBRETES',
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure notificações diárias',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  // Header info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _areRemindersEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _areRemindersEnabled
                              ? 'Lembrete Ativo!'
                              : 'Lembretes Desativados',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _areRemindersEnabled
                              ? 'Você receberá um aviso diário às ${_selectedTime.format(context)}'
                              : 'Ative para não esquecer de ler o provérbio do dia',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card principal de configuração
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle principal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: SwitchListTile(
                            title: Text(
                              'Ativar Lembretes Diários',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Receba um aviso diário para ler seu Provérbio',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            value: _areRemindersEnabled,
                            onChanged: _isSaving ? null : _toggleReminders,
                            activeThumbColor: colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),

                        Divider(height: 1, color: Colors.grey.shade200),

                        // Seletor de horário
                        AnimatedOpacity(
                          opacity: _areRemindersEnabled ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 300),
                          child: ListTile(
                            enabled: _areRemindersEnabled && !_isSaving,
                            onTap:
                                _areRemindersEnabled && !_isSaving
                                    ? _pickTime
                                    : null,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: colorScheme.primary,
                              ),
                            ),
                            title: const Text('Horário do Lembrete'),
                            subtitle: Text(
                              'Toque para alterar',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade500),
                            ),
                            trailing: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    _selectedTime.format(context),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Aviso informativo
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.primary.withAlpha(40)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'O lembrete será enviado todos os dias no horário configurado. Certifique-se de que as notificações do ProVê estejam permitidas nas configurações do seu dispositivo.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
