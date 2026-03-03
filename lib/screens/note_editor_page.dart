import 'package:flutter/material.dart';
import 'package:myapp/models/note.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _controller;
  late Color _selectedColor;

  final List<Color> _colorPalette = [
    Colors.white,
    const Color(0xFFFFF9E5),
    const Color(0xFFE5F9FF),
    const Color(0xFFF0E5FF),
    const Color(0xFFE5FFE7),
    const Color(0xFFFFE5E5),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.content);
    _selectedColor = widget.note?.color ?? Colors.white;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_controller.text.trim().isNotEmpty) {
      final result = {
        'action': 'save',
        'content': _controller.text.trim(),
        'color': _selectedColor,
      };
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A anotação não pode estar vazia.')),
      );
    }
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Anotação?'),
        content: const Text('Esta ação é permanente e não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {'action': 'delete'});
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _selectedColor,
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'Nova Anotação' : 'Editar Anotação',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
              tooltip: 'Apagar Nota',
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveNote,
            tooltip: 'Salvar Nota',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Escreva sua anotação aqui...',
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: Colors.black87),
              ),
            ),
          ),
          _buildColorPalette(),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _colorPalette.map((color) {
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = color),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 22,
              child: _selectedColor == color
                  ? const Icon(Icons.check, color: Colors.black54)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
