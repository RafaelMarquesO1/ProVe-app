import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/services/user_data_service.dart';
import 'package:myapp/widgets/app_alerts.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final UserDataService _userDataService = UserDataService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Anotações'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userDataService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar as anotações.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma anotação ainda',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Suas anotações aparecerão aqui.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final note = notes[index];
              final data = note.data() as Map<String, dynamic>;
              final docId = note.id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['noteText'],
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"${data['verseText']}"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['reference'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              final confirm = await AppAlerts.showConfirmationDialog(
                                context,
                                title: 'Excluir Anotação',
                                content: 'Tem certeza que deseja excluir esta anotação?',
                              );
                              if (confirm == true) {
                                await _userDataService.deleteNote(docId);
                                if (mounted) {
                                  AppAlerts.showSnackBar(
                                    context,
                                    message: 'Anotação excluída.',
                                    type: AppAlertType.success,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
