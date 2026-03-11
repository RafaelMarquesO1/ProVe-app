import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/providers/reading_settings_provider.dart';

class ReadingSettingsPage extends StatelessWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ReadingSettingsProvider.instance;

    return Scaffold(
      appBar: AppBar(
        // Aplica o estilo de título padrão do app
        title: Text(
          'Configurações de Leitura',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // Ação de voltar para a home
        ),
        // Removemos a transparência para um visual consistente
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tamanho da Fonte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Slider(
                  value: settings.fontSize,
                  min: 12.0,
                  max: 32.0,
                  divisions: 20,
                  label: settings.fontSize.round().toString(),
                  onChanged: (value) {
                    settings.setFontSize(value);
                  },
                ),
                const SizedBox(height: 32),
                const Text('Cor de Fundo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    _buildColorChip(context, const Color(0xFFFFF9F0), 'Padrão'),
                    _buildColorChip(context, Colors.white, 'Branco'),
                    _buildColorChip(context, const Color(0xFF212121), 'Noturno'),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Concluído'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorChip(BuildContext context, Color color, String label) {
    final settings = ReadingSettingsProvider.instance;
    final bool isSelected = settings.backgroundColor == color;
    final bool isDark = color.computeLuminance() < 0.4;

    return GestureDetector(
      onTap: () {
        settings.setBackgroundColor(color);
      },
      child: Chip(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        label: Text(
          label,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5)
            : BorderSide(color: Colors.grey.shade300, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
