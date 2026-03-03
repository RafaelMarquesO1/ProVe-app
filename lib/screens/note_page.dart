
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotePage extends StatelessWidget {
  final String selectedText;

  const NotePage({super.key, required this.selectedText});

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
          icon: const Icon(Icons.close), // Ícone de fechar
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Texto selecionado
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
                selectedText,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 32),

            // Campo de texto para a anotação
            const Expanded(
              child: TextField(
                maxLines: null, // Permite múltiplas linhas
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Sua anotação aqui...',
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botão de salvar
            ElevatedButton(
              onPressed: () {
                // Lógica para salvar a anotação
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anotação salva! (funcionalidade a ser implementada)')),
                );
                context.pop(); // Volta para a tela de leitura
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }
}
