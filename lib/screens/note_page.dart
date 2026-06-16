import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prove/services/user_data_service.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:google_fonts/google_fonts.dart';

class NotePage extends StatefulWidget {
  final String selectedText;

  const NotePage({super.key, required this.selectedText});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController _noteController = TextEditingController();
  final UserDataService _userDataService = UserDataService.instance;
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
        if (parts.length > 1) {
          verseText = parts.first.replaceAll('"', ''); 
          reference = parts.last;
        }
      } else {
        // Handle multiple verses if needed, or just use the whole text
        verseText = widget.selectedText;
      }

      await _userDataService.saveNote(
        reference: reference,
        verseText: verseText,
        noteText: _noteController.text.trim(),
      );

      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Sua reflexão foi salva na biblioteca!',
          type: AppAlertType.success,
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Erro ao salvar a anotacao local.',
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
          'NOVA ANOTAÇÃO',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 32),
            _buildNoteInput(theme),
            const SizedBox(height: 40),
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_quote_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'TRECHO SELECIONADO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Text(
            widget.selectedText,
            style: GoogleFonts.lato(
              fontSize: 15,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'SUA REFLEXÃO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 8,
          style: GoogleFonts.lato(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'O que o Espírito Santo te falou através desse versículo?',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.45),
              fontSize: 14,
            ),
            fillColor: theme.cardColor,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveNote,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : const Text(
                'SALVAR REFLEXÃO',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
      ),
    );
  }
}
