import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prove/services/user_data_service.dart';
import 'package:prove/utils/theme_colors.dart';
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
      length: 2,
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
                ); // Volta para a aba Biblioteca no scaffold
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
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildFavoritesTab(theme), _buildNotesTab(theme)],
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

            return _buildFavoriteCard(
              theme,
              reference: reference,
              text: text,
              onDelete: () => _confirmDeleteFavorite(id),
              onShare: () => Share.share('"$text"\n— $reference'),
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
                const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reference,
                    style: GoogleFonts.oswald(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.pinkAccent.shade100,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
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
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Compartilhar'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
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

            return _buildNoteCard(
              theme,
              reference: reference,
              verseText: verseText,
              noteText: noteText,
              mood: mood,
              imagePath: imagePath,
              title: title,
              onDelete: () => _confirmDeleteNote(id),
              onShare: () => Share.share(
                '"$verseText"\n— $reference\n\nReflexão:\n$noteText',
              ),
            );
          },
        );
      },
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
    required VoidCallback onDelete,
    required VoidCallback onShare,
  }) {
    final primary = theme.colorScheme.primary;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

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
                File(imagePath!),
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
                    style: GoogleFonts.lato(
                      height: 1.65,
                      fontSize: 15,
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Compartilhar'),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  textStyle: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
