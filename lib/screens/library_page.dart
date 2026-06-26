import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:prove/services/user_data_service.dart';
import 'package:prove/utils/theme_colors.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class LibraryPage extends StatefulWidget {
  final int initialIndex;
  const LibraryPage({super.key, this.initialIndex = 0});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final UserDataService _userDataService = UserDataService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'MINHA BIBLIOTECA',
            style: GoogleFonts.oswald(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(
                  '/home',
                  extra: {'index': 1},
                );
              }
            },
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.45),
            labelStyle: GoogleFonts.lato(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
            tabs: const [
              Tab(text: 'FAVORITOS'),
              Tab(text: 'ANOTAÇÕES'),
              Tab(text: 'DESTAQUES'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoritesTab(theme),
            _buildNotesTab(theme),
            _buildHighlightsTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userDataService.getFavoritesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar favoritos.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Nenhum favorito ainda',
            message:
                'Dê um duplo clique nos versículos da leitura diária para salvá-los aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index];
            final chapter = data['chapter'] ?? '';
            final verseNumber = data['verse_number'] ?? '';
            final text = data['text'] ?? '';
            final reference = 'Provérbios $chapter:$verseNumber';
            final id = data['id'] as String;
            final createdAt = data['created_at'] as String?;

            return _buildFavoriteCard(
              theme,
              reference: reference,
              text: text,
              createdAt: createdAt,
              onDelete: () => _confirmDeleteFavorite(id),
              onShare: () => Share.share('"$text"\n— $reference'),
              onCopy: () {
                Clipboard.setData(ClipboardData(text: '"$text" — $reference'));
                AppAlerts.showSnackBar(
                  context,
                  message: 'Versículo copiado!',
                  type: AppAlertType.success,
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDeleteFavorite(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Remover favorito?',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Este versículo será removido da sua lista de favoritos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
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
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _userDataService.deleteFavorite(id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Remover'),
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

  Widget _buildFavoriteCard(
    ThemeData theme, {
    required String reference,
    required String text,
    required VoidCallback onDelete,
    required VoidCallback onShare,
    required VoidCallback onCopy,
    String? createdAt,
  }) {
    String? formattedDate;
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedDate = DateFormat('dd/MM/yyyy', 'pt_BR').format(dt);
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.pink.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo colorido
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        reference,
                        style: GoogleFonts.oswald(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.pinkAccent.shade100,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Corpo com texto do versículo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aspas decorativas
                Text(
                  '\u201c',
                  style: TextStyle(
                    fontSize: 48,
                    height: 0.85,
                    color: Colors.pink.withOpacity(0.18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      height: 1.65,
                      color: theme.colorScheme.onSurface.withOpacity(0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rodapé
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                if (formattedDate != null) ...
                  [
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.pinkAccent,
                    textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 14),
                  label: const Text('Enviar'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userDataService.getNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar anotações.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.edit_note_rounded,
            title: 'Nenhuma anotação',
            message:
                'Selecione versículos durante a leitura e toque em "Anotar" para registrar suas reflexões.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index];
            final id = data['id'] as String;
            final reference = data['reference'] as String? ?? '';
            final verseText = data['verse_text'] as String? ?? '';
            final noteText = data['note_text'] as String? ?? '';
            final mood = data['mood'] as String?;
            final imagePath = data['image_path'] as String?;
            final title = data['title'] as String?;
            final accentColorValue = data['accent_color'] as int?;
            final accentColor = accentColorValue != null
                ? Color(accentColorValue)
                : null;
            final fontSize = (data['font_size'] as num?)?.toDouble();
            final fontStyle = data['font_style'] as String?;
            final createdAt = data['created_at'] as String?;
            final updatedAt = data['updated_at'] as String?;

            return _buildNoteCard(
              theme,
              reference: reference,
              verseText: verseText,
              noteText: noteText,
              mood: mood,
              imagePath: imagePath,
              title: title,
              accentColor: accentColor,
              fontSize: fontSize,
              fontStyle: fontStyle,
              createdAt: createdAt,
              updatedAt: updatedAt,
              onDelete: () => _confirmDeleteNote(id),
              onEdit: () => _showEditNoteSheet(
                id: id,
                currentTitle: title,
                currentNoteText: noteText,
                currentMood: mood,
                currentImagePath: imagePath,
                currentAccentColor: accentColor,
              ),
              onShare: () => Share.share(
                '"$verseText"\n— $reference\n\nReflexão:\n$noteText',
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHighlightsTab(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userDataService.getHighlightsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar destaques.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.highlight_alt_rounded,
            title: 'Nenhum destaque ainda',
            message:
                'Selecione versículos durante a leitura e toque em "Marcar" para destacá-los com cores.',
          );
        }

        return FutureBuilder<Map<String, String?>>(
          future: _loadAllVerseTexts(docs),
          builder: (context, textsSnapshot) {
            final verseTexts = textsSnapshot.data ?? {};

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index];
                final chapter = data['chapter'] ?? '';
                final verseNumber = data['verse_number'] ?? '';
                final colorValue = data['color_value'] as int? ?? 0xFFFFF176;
                final highlightColor = Color(colorValue);
                final reference = 'Provérbios $chapter:$verseNumber';
                final id = '${chapter}_$verseNumber';
                final text = verseTexts['${chapter}_$verseNumber'] ?? '';

                return _buildHighlightCard(
                  theme,
                  reference: reference,
                  text: text,
                  color: highlightColor,
                  id: id,
                  onDelete: () => _confirmDeleteHighlight(id),
                  onCopy: () {
                    Clipboard.setData(
                      ClipboardData(text: '"$text" — $reference'),
                    );
                    AppAlerts.showSnackBar(
                      context,
                      message: 'Versículo copiado!',
                      type: AppAlertType.success,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, String?>> _loadAllVerseTexts(
    List<Map<String, dynamic>> highlights,
  ) async {
    final jsonString = await rootBundle.loadString(
      'assets/proverbiosBibliaLivre.json',
    );
    final data = jsonDecode(jsonString) as List;
    final result = <String, String?>{};

    for (final h in highlights) {
      final chapter = h['chapter'] as String? ?? '';
      final verseNumber = h['verse_number'] as String? ?? '';
      if (chapter.isEmpty || verseNumber.isEmpty) continue;
      try {
        final chapterData = data[int.parse(chapter) - 1] as Map<String, dynamic>;
        final text = chapterData[chapter]?[verseNumber] as String?;
        result['${chapter}_$verseNumber'] = text;
      } catch (_) {
        result['${chapter}_$verseNumber'] = null;
      }
    }
    return result;
  }

  void _confirmDeleteHighlight(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.highlight_off_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Remover destaque?',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Este versículo não ficará mais destacado na leitura.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
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
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _userDataService.removeHighlight(
                          id.split('_').first,
                          id.split('_').last,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Remover'),
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

  Widget _buildHighlightCard(
    ThemeData theme, {
    required String reference,
    required String text,
    required Color color,
    required String id,
    required VoidCallback onDelete,
    required VoidCallback onCopy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.highlight_alt_rounded, color: color, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        reference,
                        style: GoogleFonts.oswald(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 36,
                    color: color.withOpacity(0.2),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        height: 1.65,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Toque para copiar o versículo',
                style: GoogleFonts.lato(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    textStyle: GoogleFonts.lato(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNoteSheet({
    required String id,
    required String? currentTitle,
    required String currentNoteText,
    required String? currentMood,
    required String? currentImagePath,
    required Color? currentAccentColor,
  }) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: currentTitle ?? '');
    final noteController = TextEditingController(text: currentNoteText);
    Color accentColor = currentAccentColor ?? theme.colorScheme.primary;
    String? selectedMood = currentMood;
    File? attachedImage =
        (currentImagePath != null && currentImagePath.isNotEmpty)
            ? File(currentImagePath)
            : null;
    bool isSaving = false;

    const moods = [
      ('🙏', 'Oração'),
      ('💡', 'Revelação'),
      ('❤️', 'Gratidão'),
      ('🤔', 'Reflexão'),
      ('😔', 'Lamento'),
      ('✨', 'Promessa'),
    ];

    const accentColors = [
      Color(0xFFB85C00),
      Color(0xFF5C6BC0),
      Color(0xFF26A69A),
      Color(0xFF66BB6A),
      Color(0xFFEF5350),
      Color(0xFFAB47BC),
      Color(0xFF29B6F6),
      Color(0xFFFFCA28),
    ];

    Future<void> pickImage(StateSetter setState) async {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) setState(() => attachedImage = File(picked.path));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final primary = accentColor;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'EDITAR ANOTAÇÃO',
                        style: GoogleFonts.oswald(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título
                      _editLabel(Icons.title_rounded, 'TÍTULO', primary),
                      const SizedBox(height: 8),
                      _editTextField(
                        controller: titleController,
                        hint: 'Título opcional...',
                        primary: primary,
                        theme: theme,
                        minLines: 1,
                      ),
                      const SizedBox(height: 20),

                      // Reflexão
                      _editLabel(Icons.draw_rounded, 'SUA REFLEXÃO', primary),
                      const SizedBox(height: 8),
                      _editTextField(
                        controller: noteController,
                        hint: 'O que este versículo fala ao seu coração?',
                        primary: primary,
                        theme: theme,
                        minLines: 5,
                      ),
                      const SizedBox(height: 20),

                      // Contexto (mood)
                      _editLabel(Icons.mood_rounded, 'CONTEXTO', primary),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: moods.map((mood) {
                          final label = '${mood.$1} ${mood.$2}';
                          final selected = selectedMood == label;
                          return GestureDetector(
                            onTap: () => setState(
                              () => selectedMood = selected ? null : label,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? primary.withValues(alpha: 0.12)
                                    : theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: selected
                                      ? primary
                                      : primary.withValues(alpha: 0.2),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? primary
                                      : ThemeColors.getSecondaryTextColor(ctx),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Cor do card
                      _editLabel(Icons.palette_rounded, 'COR DO CARD', primary),
                      const SizedBox(height: 10),
                      Row(
                        children: accentColors.map((color) {
                          final selected =
                              accentColor.toARGB32() == color.toARGB32();
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => accentColor = color),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: selected ? 32 : 26,
                                height: selected ? 32 : 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color:
                                                color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : [],
                                ),
                                child: selected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Imagem
                      _editLabel(
                          Icons.image_rounded, 'IMAGEM ANEXADA', primary),
                      const SizedBox(height: 10),
                      if (attachedImage != null) ...[
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(
                                        backgroundColor: Colors.transparent,
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: Center(
                                        child: InteractiveViewer(
                                          child: Image.file(attachedImage!),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  attachedImage!,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => attachedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      GestureDetector(
                        onTap: () => pickImage(setState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: attachedImage != null
                                ? primary.withValues(alpha: 0.08)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                attachedImage != null
                                    ? Icons.photo_library_rounded
                                    : Icons.add_photo_alternate_rounded,
                                color: primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                attachedImage != null
                                    ? 'Trocar imagem'
                                    : 'Adicionar imagem',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botão salvar
                      StatefulBuilder(
                        builder: (_, setSaving) => SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (noteController.text.trim().isEmpty) {
                                      return;
                                    }
                                    setSaving(() => isSaving = true);
                                    try {
                                      await _userDataService.updateNote(
                                        id: id,
                                        noteText: noteController.text.trim(),
                                        mood: selectedMood,
                                        title: titleController.text.trim().isNotEmpty
                                            ? titleController.text.trim()
                                            : null,
                                        accentColor: accentColor.toARGB32(),
                                        imagePath: attachedImage?.path,
                                      );
                                      if (mounted) {
                                        Navigator.pop(ctx);
                                        AppAlerts.showSnackBar(
                                          context,
                                          message: 'Anotação atualizada!',
                                          type: AppAlertType.success,
                                        );
                                      }
                                    } catch (_) {
                                      setSaving(() => isSaving = false);
                                      if (mounted) {
                                        AppAlerts.showSnackBar(
                                          context,
                                          message: 'Erro ao atualizar.',
                                          type: AppAlertType.error,
                                        );
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'SALVAR ALTERAÇÕES',
                                    style: GoogleFonts.oswald(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _editLabel(IconData icon, String label, Color primary) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: primary,
          ),
        ),
      ],
    );
  }

  Widget _editTextField({
    required TextEditingController controller,
    required String hint,
    required Color primary,
    required ThemeData theme,
    int minLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: null,
        style: GoogleFonts.lato(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: ThemeColors.getDisabledColor(context),
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _confirmDeleteNote(String id) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Apagar anotação?',
                style: GoogleFonts.oswald(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sua reflexão será apagada permanentemente.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
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
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _userDataService.deleteNote(id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Apagar'),
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

  Widget _buildNoteCard(
    ThemeData theme, {
    required String reference,
    required String verseText,
    required String noteText,
    String? mood,
    String? imagePath,
    String? title,
    Color? accentColor,
    double? fontSize,
    String? fontStyle,
    String? createdAt,
    String? updatedAt,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
    required VoidCallback onShare,
  }) {
    final primary = accentColor ?? theme.colorScheme.primary;
    final noteTextSize = fontSize ?? 15.0;
    final noteFont = fontStyle ?? 'lato';
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    // Formata data
    String? dateLabel;
    final dateSource = updatedAt ?? createdAt;
    if (dateSource != null) {
      try {
        final dt = DateTime.parse(dateSource).toLocal();
        final formatted = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(dt);
        dateLabel = updatedAt != null ? 'Editada em $formatted' : 'Criada em $formatted';
      } catch (_) {}
    }

    // Separa múltiplas referências e versículos
    final refs = reference.split(', ').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
    final verses = verseText.split('\n').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    final isMultiple = refs.length > 1;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [ThemeColors.getCardShadow(context)],
        border: Border.all(color: primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.edit_note_rounded, color: primary, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title != null && title.isNotEmpty
                        ? title
                        : isMultiple
                            ? 'Múltiplos Versículos'
                            : reference,
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (mood != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      mood,
                      style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Imagem anexada
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          // Versículos (um por um se múltiplos, ou único)
          if (verseText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: List.generate(isMultiple ? verses.length : 1, (i) {
                  final text = isMultiple ? verses[i] : verseText;
                  final ref = isMultiple && i < refs.length ? refs[i] : null;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isMultiple && i < verses.length - 1 ? 10 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ref != null) ...[
                          if (i > 0) Divider(color: primary.withValues(alpha: 0.1), height: 16),
                          Text(
                            ref,
                            style: GoogleFonts.oswald(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary.withValues(alpha: 0.6),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\u201c',
                              style: TextStyle(
                                fontSize: 36,
                                height: 0.9,
                                color: primary.withValues(alpha: 0.2),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  text,
                                  style: GoogleFonts.lato(
                                    fontStyle: FontStyle.italic,
                                    color: ThemeColors.getTertiaryTextColor(context),
                                    fontSize: 13,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          // Reflexão
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 40,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    noteText,
                    style: _getNoteTextStyle(noteFont).copyWith(
                      height: 1.65,
                      fontSize: noteTextSize,
                      color: ThemeColors.getSecondaryTextColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rodapé
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          updatedAt != null
                              ? Icons.edit_calendar_rounded
                              : Icons.calendar_today_rounded,
                          size: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        textStyle: GoogleFonts.lato(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded, size: 15),
                      label: const Text('Compartilhar'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        textStyle: GoogleFonts.lato(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  static TextStyle _getNoteTextStyle(String fontId) {
    switch (fontId) {
      case 'merriweather':
        return GoogleFonts.merriweather();
      case 'sourcecodepro':
        return GoogleFonts.sourceCodePro();
      default:
        return GoogleFonts.lato();
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.65),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }
}
