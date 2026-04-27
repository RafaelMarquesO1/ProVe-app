
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/widgets/app_alerts.dart';

class NotePage extends StatefulWidget {
  final String selectedText;

  const NotePage({super.key, required this.selectedText});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController _noteController = TextEditingController();
  final DatabaseService _dbService = DatabaseService.instance;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      AppAlerts.showSnackBar(
        context,
        message: 'A anotação não pode estar vazia.',
        type: AppAlertType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String reference = 'Múltiplos versículos';
      String verseText = widget.selectedText;
      
      if (!widget.selectedText.contains('\n\n')) {
        final parts = widget.selectedText.split('\n— ');
        verseText = parts.first.replaceAll('"', ''); 
        reference = parts.length > 1 ? parts.last : 'Referência desconhecida';
      }

      String finalContent = 'Trecho: "$verseText"\n\nAnotação: ${_noteController.text.trim()}';

      await _dbService.createNote(
        title: reference,
        content: finalContent,
      );

      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Anotação salva com sucesso!',
          type: AppAlertType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Erro ao salvar anotação. Tente novamente.',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CRIAR ANOTAÇÃO',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Trecho Selecionado:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.selectedText,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Sua anotação aqui...',
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
