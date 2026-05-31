import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/user_data_service.dart';
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
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index];
            final chapter = data['chapter'] ?? '';
            final verseNumber = data['verse_number'] ?? '';
            final text = data['text'] ?? '';
            final reference = 'Provérbios $chapter:$verseNumber';

            return _buildLibraryCard(
              theme,
              title: reference,
              content: text,
              icon: Icons.favorite_rounded,
              iconColor: Colors.pinkAccent,
              onDelete: () => _userDataService.deleteFavorite(data['id'] as String),
              onShare: () => Share.share('"$text"\n— $reference'),
            );
          },
        );
      },
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
            icon: Icons.note_alt_outlined,
            title: 'Nenhuma anotação',
            message:
                'Selecione a opção "Anotar" em um versículo para escrever suas reflexões.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final data = docs[index];
            final reference = data['reference'] ?? '';
            final verseText = data['verse_text'] ?? '';
            final noteText = data['note_text'] ?? '';

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          reference,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                          size: 22,
                        ),
                        onPressed: () =>
                            _userDataService.deleteNote(data['id'] as String),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      verseText,
                      style: GoogleFonts.lato(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    noteText,
                    style: GoogleFonts.lato(
                      height: 1.6,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Share.share(
                        'Reflexão sobre $reference:\n\n$noteText\n\nVersículo: "$verseText"',
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('COMPARTILHAR'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryCard(
    ThemeData theme, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onDelete,
    required VoidCallback onShare,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                  size: 22,
                ),
                onPressed: onDelete,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.lato(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
              fontStyle: FontStyle.italic,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('COMPARTILHAR'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
