import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/note.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Importa o novo pacote

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final List<Note> _notes = [
    Note(
      content: 'Lembre-se de que a verdadeira sabedoria vem de reconhecer o quanto ainda temos a aprender. A jornada do conhecimento é infinita.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      color: const Color(0xFFFFF9E5), // Amarelo claro
    ),
    Note(
      content: 'A paciência é uma virtude que se cultiva nos momentos de maior provação.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      color: const Color(0xFFE5F9FF), // Azul claro
    ),
    Note(
      content: 'Uma pequena anotação sobre como a simplicidade pode ser a chave para a felicidade. Menos é mais, especialmente quando se trata de paz de espírito.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      color: const Color(0xFFF0E5FF), // Roxo claro
    ),
    Note(
      content: 'Ideia para um novo projeto: um aplicativo que ajuda a conectar voluntários a ONGs locais. Foco em usabilidade e impacto social.',
      date: DateTime.now().subtract(const Duration(days: 7)),
      color: const Color(0xFFE5FFE7), // Verde claro
    ),
  ];

  void _navigateToEditor({Note? note}) async {
    final result = await context.push<Map<String, dynamic>>('/notes/editor', extra: note);

    if (result != null) {
      setState(() {
        if (result['action'] == 'delete') {
          _notes.removeWhere((n) => n == note);
        } else if (result['action'] == 'save') {
          final newContent = result['content'] as String;
          final newColor = result['color'] as Color;
          if (note != null) {
            note.content = newContent;
            note.color = newColor;
            note.date = DateTime.now();
          } else {
            _notes.insert(0, Note(content: newContent, date: DateTime.now(), color: newColor));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        tooltip: 'Nova Anotação',
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Minhas Anotações',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 36, color: theme.colorScheme.onSurface),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.home_outlined),
              onPressed: () => context.go('/home'),
              tooltip: 'Voltar para a Home',
            ),
          ),
          // Usa a nova função para construir a grade
          _buildNotesGrid(),
        ],
      ),
    );
  }

  Widget _buildNotesGrid() {
    if (_notes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Nenhuma anotação encontrada.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Novo layout em grade
    return SliverPadding(
      padding: const EdgeInsets.all(12.0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, // Duas colunas
        mainAxisSpacing: 12, // Espaçamento vertical
        crossAxisSpacing: 12, // Espaçamento horizontal
        childCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return InkWell(
            onTap: () => _navigateToEditor(note: note),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: note.color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    // Formatação da data corrigida
                    DateFormat('dd/MM/yy ' " | "' HH:mm').format(note.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
