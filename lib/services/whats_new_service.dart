import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Representa um item de novidade dentro de uma versão.
class WhatsNewItem {
  final IconData icon;
  final String title;
  final String description;

  const WhatsNewItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Representa as novidades de uma versão específica.
class VersionChangelog {
  final String version;
  final String title;
  final List<WhatsNewItem> items;

  const VersionChangelog({
    required this.version,
    required this.title,
    required this.items,
  });
}

class WhatsNewService {
  static const String _prefKey = 'lastSeenVersion';

  /// Mapa de changelogs por versão (buildNumber como chave).
  /// Adicione aqui as novidades de cada nova versão antes de publicar.
  static const Map<String, VersionChangelog> _changelogs = {
    '8': VersionChangelog(
      version: '1.2.0',
      title: 'Novidades incríveis ✨',
      items: [
        WhatsNewItem(
          icon: Icons.highlight_alt_rounded,
          title: 'Marca Texto',
          description:
              'Agora você pode destacar versículos com cores diferentes durante a leitura. Escolha entre amarelo, verde, azul, rosa e laranja para marcar seus versículos preferidos.',
        ),
        WhatsNewItem(
          icon: Icons.emoji_events_rounded,
          title: '+17 Conquistas!',
          description:
              'De 28 para 45 conquistas em 7 categorias: Ofensiva, Leituras, Capítulos, Destaques, Notas, Ciclos Completos e Favoritos.',
        ),
        WhatsNewItem(
          icon: Icons.favorite_rounded,
          title: 'Favoritos',
          description:
              'Nova categoria ao favoritar versículos: Primeiro Favorito, Amante da Palavra, Colecionador de Versículos, Guardião de Joias e Biblioteca Viva (100 favoritos).',
        ),
        WhatsNewItem(
          icon: Icons.loop_rounded,
          title: 'Ciclos Completos',
          description:
              'Nova categoria baseada em ciclos de 31 leituras: Primeiro Ciclo, Veterano (5), Mestre de Provérbios (10) e Sábio Consumado (20 ciclos).',
        ),
        WhatsNewItem(
          icon: Icons.rocket_launch_rounded,
          title: 'Metas de Longo Prazo',
          description:
              'Guardião Incansável (730 dias de ofensiva), Legado de Sabedoria (1.000 leituras), Eterno Aprendiz (1.095), Iluminador (50 destaques) e Tesouro de Sabedoria (100 notas).',
        ),
        WhatsNewItem(
          icon: Icons.highlight_alt_rounded,
          title: 'Destaques na Leitura',
          description:
              'Os versículos destacados aparecem com a cor escolhida durante a leitura. Gerencie seus destaques diretamente na tela de leitura.',
        ),
        WhatsNewItem(
          icon: Icons.edit_note_rounded,
          title: 'Conquistas de Anotações',
          description:
              'Ganhe conquistas ao criar reflexões: Primeira Reflexão, Coração Transbordante, Diário de Sabedoria e Crônicas de Provérbios.',
        ),
        WhatsNewItem(
          icon: Icons.library_books_rounded,
          title: 'Aba de Destaques na Biblioteca',
          description:
              'A biblioteca agora tem uma terceira aba "Destaques" para você visualizar e gerenciar todos os versículos que marcou com cores.',
        ),
      ],
    ),
    '7': VersionChangelog(
      version: '1.2.0',
      title: 'Novidades incríveis ✨',
      items: [
        WhatsNewItem(
          icon: Icons.animation_rounded,
          title: 'Novas Animações',
          description:
              'Aproveite as novas animações ao favoritar versículos, concluir leituras e salvar reflexões.',
        ),
        WhatsNewItem(
          icon: Icons.calendar_today_rounded,
          title: 'Histórico nas Notas',
          description:
              'Agora você acompanha quando as suas notas e favoritos foram criados ou editados pela última vez.',
        ),
        WhatsNewItem(
          icon: Icons.content_copy_rounded,
          title: 'Melhorias nos Favoritos',
          description:
              'A tela de favoritos foi redesenhada, agora incluindo botão para copiar o versículo facilmente.',
        ),
        WhatsNewItem(
          icon: Icons.format_align_left_rounded,
          title: 'Leitura Aprimorada',
          description:
              'Corrigimos o espaçamento dos versículos, tornando a leitura muito mais agradável e natural.',
        ),
        WhatsNewItem(
          icon: Icons.tablet_mac_rounded,
          title: 'Otimização para Telas Grandes',
          description:
              'A tela de edição de notas agora fica centralizada e melhor alinhada em iPads e tablets.',
        ),
      ],
    ),
    '6': VersionChangelog(
      version: '1.1.0',
      title: 'O que há de novo 🚀',
      items: [
        WhatsNewItem(
          icon: Icons.palette_rounded,
          title: 'Cores nas Anotações',
          description:
              'Agora você pode personalizar suas reflexões escolhendo uma cor de destaque para cada card.',
        ),
        WhatsNewItem(
          icon: Icons.zoom_out_map_rounded,
          title: 'Imagens em Tela Cheia',
          description:
              'Toque na imagem anexada à sua anotação para vê-la em tamanho maior e com suporte a zoom.',
        ),
        WhatsNewItem(
          icon: Icons.tablet_mac_rounded,
          title: 'Melhorias Visuais',
          description:
              'A tela de edição de anotações foi otimizada para funcionar perfeitamente em tablets e telas grandes.',
        ),
      ],
    ),
    '5': VersionChangelog(
      version: '1.0.0',
      title: 'Novidades desta versão 🎉',
      items: [
        WhatsNewItem(
          icon: Icons.notifications_active,
          title: 'Lembretes automáticos',
          description:
              'Notificações diárias já vêm ativas às 08:00 para você nunca esquecer o Provérbio do dia.',
        ),
        WhatsNewItem(
          icon: Icons.auto_stories,
          title: 'Leitura aprimorada',
          description:
              'Interface de leitura mais fluida com ajustes de fonte, espaçamento e tema escuro.',
        ),
        WhatsNewItem(
          icon: Icons.favorite,
          title: 'Anotações',
          description:
              'Salve versículos favoritos e registre suas reflexões pessoais com facilidade. Além da adição de personalização nas suas anotações.',
        ),
        WhatsNewItem(
          icon: Icons.local_fire_department,
          title: 'Sequência de leitura',
          description:
              'Acompanhe sua ofensiva diária e mantenha o hábito de leitura.',
        ),
      ],
    ),
    '10': VersionChangelog(
      version: '1.4.0',
      title: 'Quiz turbinado e mais 🚀',
      items: [
        WhatsNewItem(
          icon: Icons.timer_rounded,
          title: 'Timer no Quiz',
          description:
              'Agora cada pergunta tem 30 segundos para ser respondida! Você pode ativar ou desativar o timer quando quiser. O tempo restante aparece em verde, laranja ou vermelho.',
        ),
        WhatsNewItem(
          icon: Icons.design_services_rounded,
          title: 'Quiz com visual renovado',
          description:
              'O quiz ficou mais bonito e fluido! Novos gradientes, animações nas opções e feedback visual mais rico ao acertar ou errar.',
        ),
        WhatsNewItem(
          icon: Icons.history_rounded,
          title: 'Histórico de tentativas',
          description:
              'Acompanhe seu desempenho ao longo do tempo! Na tela de resultados, expanda o histórico para ver todas as suas tentativas anteriores com data e pontuação.',
        ),
        WhatsNewItem(
          icon: Icons.celebration_rounded,
          title: 'Confete nos resultados',
          description:
              'Ao atingir 70% ou mais de acertos, uma chuva de confete comemora seu resultado!',
        ),
        WhatsNewItem(
          icon: Icons.home_rounded,
          title: 'Quiz na tela inicial',
          description:
              'O quiz agora tem um card especial na página inicial, mostrando sua melhor pontuação e número de tentativas. Toque e comece a jogar!',
        ),
        WhatsNewItem(
          icon: Icons.palette_rounded,
          title: 'Compartilhamento renovado',
          description:
              'Os cards de compartilhamento estão mais bonitos com novas fontes (Oswald e Lato), gradientes mais ricos e layout ajustado para versículos, ofensiva e quiz.',
        ),
      ],
    ),
    '9': VersionChangelog(
      version: '1.3.0',
      title: 'Novidades incríveis ✨',
      items: [
        WhatsNewItem(
          icon: Icons.quiz_rounded,
          title: 'Quiz de Provérbios',
          description:
              'Teste seu conhecimento com perguntas sobre todos os 31 capítulos! Complete versículos e descubra de qual capítulo é cada passagem. Acumule pontos e bata seu recorde.',
        ),
        WhatsNewItem(
          icon: Icons.fullscreen_rounded,
          title: 'Modo Foco',
          description:
              'Leia sem distrações! Ative o modo foco na tela de leitura para esconder botões e menus. Toque no botão "Sair do Modo Foco" para voltar.',
        ),
        WhatsNewItem(
          icon: Icons.image_rounded,
          title: 'Compartilhar como Imagem',
          description:
              'Compartilhe versículos, sua ofensiva e resultados do quiz como imagens estilizadas. Gere cards bonitos com gradiente e compartilhe onde quiser.',
        ),
        WhatsNewItem(
          icon: Icons.share_rounded,
          title: 'Compartilhar Ofensiva',
          description:
              'Mostre sua sequência de leitura para os amigos! Agora você pode compartilhar sua ofensiva atual como imagem diretamente da tela de progresso.',
        ),
        WhatsNewItem(
          icon: Icons.emoji_events_rounded,
          title: 'Compartilhar Resultado do Quiz',
          description:
              'Ao finalizar o quiz, compartilhe sua pontuação com amigos. Mostre quantas perguntas você acertou e desafie outros a fazerem melhor!',
        ),
      ],
    ),
  };

  /// Verifica se há novidades para exibir na versão atual.
  /// Retorna o [VersionChangelog] se for a primeira vez abrindo essa versão,
  /// ou `null` se o usuário já viu as novidades desta versão.
  static Future<VersionChangelog?> checkForWhatsNew() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final buildNumber = info.buildNumber;

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_prefKey);

      // Já viu esta versão — não exibe nada
      if (lastSeen == buildNumber) return null;

      // Busca o changelog desta versão
      return _changelogs[buildNumber];
    } catch (e) {
      debugPrint('[WhatsNewService] Erro ao verificar novidades: $e');
      return null;
    }
  }

  /// Marca a versão atual como "já vista" para não exibir novamente.
  static Future<void> markAsSeen() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, info.buildNumber);
    } catch (e) {
      debugPrint('[WhatsNewService] Erro ao salvar versão vista: $e');
    }
  }
}
