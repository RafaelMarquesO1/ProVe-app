import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prove/services/user_data_service.dart';
import 'package:prove/utils/theme_colors.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:google_fonts/google_fonts.dart';

const _moods = [
  ('🙏', 'Oração'),
  ('💡', 'Revelação'),
  ('❤️', 'Gratidão'),
  ('🤔', 'Reflexão'),
  ('😔', 'Lamento'),
  ('✨', 'Promessa'),
];

class NotePage extends StatefulWidget {
  final String selectedText;

  const NotePage({super.key, required this.selectedText});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _noteController = TextEditingController();
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();
  final _userDataService = UserDataService.instance;

  bool _isSaving = false;
  bool _isFocused = false;
  String? _selectedMood;
  File? _attachedImage;

  late final String _reference;
  late final String _verseText;
  late final List<String> _verseKeys;
  late final List<({String ref, String text})> _verseBlocks;

  @override
  void initState() {
    super.initState();
    _parseSelectedText();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  // Blocos individuais de versículo para exibição separada
  void _parseSelectedText() {
    // Múltiplos versículos: separados por \n\n
    if (widget.selectedText.contains('\n\n')) {
      final blocks = widget.selectedText.split('\n\n').where((b) => b.trim().isNotEmpty).toList();
      final refs = <String>[];
      final keys = <String>[];
      final blocks2 = <({String ref, String text})>[];
      for (final block in blocks) {
        final parts = block.split('\n— ');
        if (parts.length > 1) {
          final text = parts.first.replaceAll('"', '').trim();
          final ref = parts.last.trim();
          refs.add(ref);
          blocks2.add((ref: ref, text: text));
          final m = RegExp(r'(\d+):(\d+)').firstMatch(ref);
          if (m != null) keys.add('${m.group(1)}_${m.group(2)}');
        }
      }
      if (refs.isNotEmpty) {
        _verseBlocks = blocks2;
        _verseText = blocks2.map((b) => b.text).join('\n');
        _reference = refs.join(', ');
        _verseKeys = keys;
        return;
      }
    }
    // Versículo único
    final parts = widget.selectedText.split('\n— ');
    if (parts.length > 1) {
      final text = parts.first.replaceAll('"', '').trim();
      _verseText = text;
      _reference = parts.last.trim();
      _verseBlocks = [(ref: _reference, text: text)];
      final m = RegExp(r'(\d+):(\d+)').firstMatch(_reference);
      _verseKeys = m != null ? ['${m.group(1)}_${m.group(2)}'] : [];
      return;
    }
    _verseText = widget.selectedText;
    _reference = 'Múltiplos versículos';
    _verseBlocks = [(ref: _reference, text: _verseText)];
    _verseKeys = [];
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _attachedImage = File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ANEXAR IMAGEM',
                style: GoogleFonts.oswald(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeria',
                      primary: primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _imageSourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Câmera',
                      primary: primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceTile({
    required IconData icon,
    required String label,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lato(fontWeight: FontWeight.w600, color: primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      AppAlerts.showSnackBar(
        context,
        message: 'Escreva sua reflexão antes de salvar.',
        type: AppAlertType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _userDataService.saveNote(
        reference: _reference,
        verseText: _verseText,
        noteText: _noteController.text.trim(),
        mood: _selectedMood,
        imagePath: _attachedImage?.path,
        verseKeys: _verseKeys.isNotEmpty ? _verseKeys : null,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      );

      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Reflexão salva na biblioteca!',
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
          message: 'Erro ao salvar a anotação.',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _pop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  void _confirmDiscard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Descartar anotação?',
                style: GoogleFonts.oswald(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sua reflexão será perdida.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: ThemeColors.getTertiaryTextColor(context),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Descartar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final charCount = _noteController.text.length;
    final hasContent = _noteController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => hasContent ? _confirmDiscard() : _pop(),
        ),
        title: Text(
          'NOVA ANOTAÇÃO',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          AnimatedOpacity(
            opacity: hasContent ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _isSaving || !hasContent ? null : _saveNote,
              child: Text(
                'SALVAR',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVerseCard(theme, primary),
              _buildDivider(primary),
              _buildTitleField(theme, primary),
              const SizedBox(height: 20),
              _buildMoodSelector(theme, primary),
              const SizedBox(height: 20),
              _buildNoteField(theme, primary, charCount),
              const SizedBox(height: 12),
              _buildAttachButton(theme, primary),
              if (_attachedImage != null) ...[
                const SizedBox(height: 12),
                _buildImagePreview(),
              ],
              const SizedBox(height: 28),
              _buildSaveButton(primary, hasContent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseCard(ThemeData theme, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.12), width: 1.5),
        boxShadow: [ThemeColors.getCardShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.auto_stories_rounded, color: primary, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _verseBlocks.length > 1 ? 'Múltiplos Versículos' : _reference,
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: _verseBlocks.asMap().entries.map((entry) {
                final i = entry.key;
                final block = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_verseBlocks.length > 1) ...[
                      if (i > 0) Divider(color: primary.withValues(alpha: 0.1), height: 20),
                      Text(
                        block.ref,
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primary.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u201c',
                          style: GoogleFonts.lato(
                            fontSize: 36,
                            height: 0.9,
                            color: primary.withValues(alpha: 0.2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              block.text,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                height: 1.7,
                                fontStyle: FontStyle.italic,
                                color: ThemeColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_verseBlocks.length == 1) const SizedBox(height: 4),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: primary.withValues(alpha: 0.12), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.edit_note_rounded,
              color: primary.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          Expanded(
            child: Divider(color: primary.withValues(alpha: 0.12), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.title_rounded, color: primary, size: 15),
              const SizedBox(width: 7),
              Text(
                'TÍTULO',
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.12), width: 1.5),
          ),
          child: TextField(
            controller: _titleController,
            style: GoogleFonts.lato(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Título opcional para sua reflexão...',
              hintStyle: TextStyle(
                color: ThemeColors.getDisabledColor(context),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.mood_rounded, color: primary, size: 15),
              const SizedBox(width: 7),
              Text(
                'CONTEXTO',
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _moods.map((mood) {
            final label = '${mood.$1} ${mood.$2}';
            final selected = _selectedMood == label;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedMood = selected ? null : label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.12)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: selected
                        ? primary
                        : primary.withValues(alpha: 0.15),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? primary
                        : ThemeColors.getSecondaryTextColor(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteField(ThemeData theme, Color primary, int charCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.draw_rounded, color: primary, size: 15),
              const SizedBox(width: 7),
              Text(
                'SUA REFLEXÃO',
                style: GoogleFonts.oswald(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isFocused ? primary : primary.withValues(alpha: 0.12),
              width: _isFocused ? 2 : 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: TextField(
              controller: _noteController,
              focusNode: _focusNode,
              minLines: 8,
              maxLines: null,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.lato(fontSize: 15, height: 1.7),
              decoration: InputDecoration(
                hintText: 'O que este versículo fala ao seu coração hoje?',
                hintStyle: TextStyle(
                  color: ThemeColors.getDisabledColor(context),
                  fontSize: 14,
                  height: 1.5,
                ),
                contentPadding: const EdgeInsets.all(20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: charCount > 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$charCount caractere${charCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  color: ThemeColors.getTertiaryTextColor(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachButton(ThemeData theme, Color primary) {
    final hasImage = _attachedImage != null;
    return GestureDetector(
      onTap: hasImage
          ? () => setState(() => _attachedImage = null)
          : _showImageSourceSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasImage
              ? primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? primary : primary.withValues(alpha: 0.15),
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasImage ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
              color: hasImage ? primary : ThemeColors.getSecondaryIconColor(context),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              hasImage ? 'Remover imagem' : 'Anexar imagem',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasImage
                    ? primary
                    : ThemeColors.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _attachedImage!,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _attachedImage = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color primary, bool hasContent) {
    final enabled = hasContent && !_isSaving;
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primary, const Color(0xFFD65108)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? _saveNote : null,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_added_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'SALVAR REFLEXÃO',
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
