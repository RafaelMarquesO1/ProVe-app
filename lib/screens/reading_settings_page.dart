import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/reading_settings_provider.dart';

// Enum para representar a seleção de voz
enum VoiceType { masculina, feminina }

class ReadingSettingsPage extends StatelessWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ReadingSettingsProvider.instance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajustes de Leitura',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'), // Navegação consistente
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, child) {
          // Estado para o SegmentedButton
          final Set<VoiceType> voiceSelection = {settings.voiceType};

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'APARÊNCIA DO TEXTO'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildFontSizeSlider(context, settings),
                      const Divider(height: 1, indent: 24, endIndent: 24),
                      _buildBackgroundColorSelector(context, settings),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'PREFERÊNCIAS DE ÁUDIO'),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildSpeechRateSlider(context, settings),
                      const Divider(height: 1, indent: 24, endIndent: 24),
                      _buildVoiceSelector(context, settings, voiceSelection),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, ReadingSettingsProvider settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tamanho da Fonte', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Slider(
            value: settings.fontSize,
            min: 12.0,
            max: 32.0,
            divisions: 10,
            label: settings.fontSize.round().toString(),
            onChanged: (value) => settings.setFontSize(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundColorSelector(BuildContext context, ReadingSettingsProvider settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cor de Fundo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildColorChip(context, const Color(0xFFFFF9F0), 'Padrão'),
              _buildColorChip(context, Colors.white, 'Branco'),
              _buildColorChip(context, const Color(0xFF212121), 'Noturno'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechRateSlider(BuildContext context, ReadingSettingsProvider settings) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Velocidade da Leitura', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Slider(
            value: settings.speechRate,
            min: 0.5,
            max: 1.5, 
            divisions: 10,
            label: '${(settings.speechRate * 100).toInt()}%',
            onChanged: (value) => settings.setSpeechRate(value),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector(BuildContext context, ReadingSettingsProvider settings, Set<VoiceType> selection) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voz', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<VoiceType>(
              segments: const <ButtonSegment<VoiceType>>[
                ButtonSegment(value: VoiceType.masculina, label: Text('Masculina'), icon: Icon(Icons.male)),
                ButtonSegment(value: VoiceType.feminina, label: Text('Feminina'), icon: Icon(Icons.female)),
              ],
              selected: selection,
              onSelectionChanged: (newSelection) {
                settings.setVoiceType(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                selectedForegroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(BuildContext context, Color color, String label) {
    final settings = ReadingSettingsProvider.instance;
    final bool isSelected = settings.backgroundColor == color;
    final bool isDark = color.computeLuminance() < 0.4;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => settings.setBackgroundColor(color),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white54 : Colors.black26),
                width: isSelected ? 3.0 : 1.5,
              ),
            ),
            child: isSelected ? Icon(Icons.check, color: isDark ? Colors.white : Colors.black) : null,
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
