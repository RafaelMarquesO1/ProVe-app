import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/reading_settings_provider.dart';

class ReadingSettingsPage extends StatelessWidget {
  final int returnIndex;

  const ReadingSettingsPage({super.key, this.returnIndex = 0});

  @override
  Widget build(BuildContext context) {
    final settings = ReadingSettingsProvider.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ajustes de Leitura',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home', extra: {'index': returnIndex});
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, child) {
          final Set<VoiceType> voiceSelection = {settings.voiceType};

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // --- LIVE PREVIEW ---
              _buildLivePreview(context, settings),

              const SizedBox(height: 32),

              // --- TEXT SECTION ---
              _buildSectionTitle(context, 'VISUAL DO TEXTO'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFontSizeSlider(context, settings),
                    Divider(
                      height: 1,
                      indent: 24,
                      endIndent: 24,
                      color: theme.dividerColor,
                    ),
                    _buildBackgroundColorSelector(context, settings),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- AUDIO SECTION ---
              _buildSectionTitle(context, 'VOZ E VELOCIDADE'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSpeechRateSlider(context, settings),
                    Divider(
                      height: 1,
                      indent: 24,
                      endIndent: 24,
                      color: theme.dividerColor,
                    ),
                    _buildVoiceSelector(context, settings, voiceSelection),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botão de Reset
              TextButton.icon(
                onPressed: () {
                  // Lógica de reset poderia ser adicionada ao provider
                  settings.setFontSize(18.0);
                  settings.setBackgroundColor(const Color(0xFFFFF9F0));
                  settings.setSpeechRate(1.0);
                  settings.setVoiceType(VoiceType.feminina);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Restaurar padrões'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withOpacity(0.65),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLivePreview(
    BuildContext context,
    ReadingSettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    final isDark = settings.backgroundColor.computeLuminance() < 0.4;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'PRÉ-VISUALIZAÇÃO'),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: settings.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: settings.backgroundColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                'Provérbios 3:5\nConfia no Senhor de todo o teu coração e não te estribes no teu próprio entendimento.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.fontSize,
                  color: textColor,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(
    BuildContext context,
    ReadingSettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tamanho da Fonte',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${settings.fontSize.round()}px',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              Expanded(
                child: Slider(
                  value: settings.fontSize,
                  min: 14.0,
                  max: 30.0,
                  divisions: 8,
                  onChanged: (value) => settings.setFontSize(value),
                ),
              ),
              Icon(
                Icons.text_fields_rounded,
                size: 24,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundColorSelector(
    BuildContext context,
    ReadingSettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cor de Fundo',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildColorChip(context, const Color(0xFFFFF9F0), 'Sépia'),
              _buildColorChip(context, Colors.white, 'Claro'),
              _buildColorChip(context, const Color(0xFF121212), 'Escuro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechRateSlider(
    BuildContext context,
    ReadingSettingsProvider settings,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Velocidade da Leitura',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(settings.speechRate * 10).toInt() / 10}x',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.speed_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              Expanded(
                child: Slider(
                  value: settings.speechRate,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  onChanged: (value) => settings.setSpeechRate(value),
                ),
              ),
              Icon(
                Icons.bolt_rounded,
                size: 24,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector(
    BuildContext context,
    ReadingSettingsProvider settings,
    Set<VoiceType> selection,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voz da Narração',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SegmentedButton<VoiceType>(
              segments: const <ButtonSegment<VoiceType>>[
                ButtonSegment(
                  value: VoiceType.masculina,
                  label: Text(
                    'Masculina',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  icon: Icon(Icons.male_rounded, size: 18),
                ),
                ButtonSegment(
                  value: VoiceType.feminina,
                  label: Text(
                    'Feminina',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  icon: Icon(Icons.female_rounded, size: 18),
                ),
              ],
              selected: selection,
              showSelectedIcon: false,
              onSelectionChanged: (newSelection) {
                HapticFeedback.lightImpact();
                settings.setVoiceType(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.transparent,
                selectedBackgroundColor: theme.colorScheme.primary,
                selectedForegroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(BuildContext context, Color color, String label) {
    final settings = ReadingSettingsProvider.instance;
    final bool isSelected = settings.backgroundColor.value == color.value;
    final bool isDark = color.computeLuminance() < 0.4;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        settings.setBackgroundColor(color);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: isSelected ? 3.0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary.withOpacity(0.8),
        letterSpacing: 1.5,
      ),
    );
  }
}
