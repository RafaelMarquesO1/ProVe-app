import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/app_theme_controller.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/app_logo.dart';
import 'package:myapp/widgets/bounce_button.dart';
import 'package:share_plus/share_plus.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  User? _user;
  StreamSubscription<User?>? _userSubscription;
  bool _updatingTheme = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    AppAlerts.showCustomDialog(
      context: context,
      title: 'Sair da Conta',
      message: 'Tem certeza que deseja sair agora? Sua jornada de sabedoria continuará aqui quando você voltar.',
      confirmText: 'Sair',
      cancelText: 'Cancelar',
      icon: Icons.logout_rounded,
      iconColor: Colors.red.shade700,
      onConfirm: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          AppAlerts.showSnackBar(
            context,
            message: 'Sessão encerrada com sucesso.',
            type: AppAlertType.info,
          );
          context.go('/');
        }
      },
    );
  }

  Future<void> _onThemeChanged(bool isDark) async {
    if (_updatingTheme) return;
    setState(() => _updatingTheme = true);
    await AppThemeController.instance.setThemeMode(
      isDark ? ThemeMode.dark : ThemeMode.light,
    );
    if (mounted) {
      setState(() => _updatingTheme = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final preferencesItems = _buildPreferenceItems(context);
    final quickActions = _buildQuickActions(context);
    final firstName = (_user?.displayName?.trim().split(' ').first ?? 'Usuário');
    final isDarkMode = AppThemeController.instance.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.tune_rounded, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $firstName',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Gerencie sua jornada e preferências',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildHeroReadingCard(context),
              const SizedBox(height: 26),
              _buildSectionTitle(context, 'Acesso rápido'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final spacing = 10.0;
                  final itemWidth = (width - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: quickActions
                        .map(
                          (action) => SizedBox(
                            width: itemWidth,
                            child: _ActionTile(
                              icon: action.icon,
                              title: action.title,
                              subtitle: action.subtitle,
                              color: action.color,
                              onTap: action.onTap,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'Sua conta'),
              _buildProfileCard(context),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Preferências'),
              Container(
                decoration: _cardDecoration(context),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildThemeMenuItem(context, isDarkMode),
                    Divider(
                      height: 1,
                      indent: 72,
                      color: Theme.of(context).dividerColor,
                    ),
                    for (int i = 0; i < preferencesItems.length; i++) ...[
                      _buildMenuItem(
                        context,
                        icon: preferencesItems[i].icon,
                        title: preferencesItems[i].title,
                        subtitle: preferencesItems[i].subtitle,
                        onTap: preferencesItems[i].onTap,
                      ),
                      if (i != preferencesItems.length - 1)
                        Divider(
                          height: 1,
                          indent: 72,
                          color: Theme.of(context).dividerColor,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Sobre'),
              _buildAboutCard(context),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Conta'),
              Semantics(
                button: true,
                label: 'Sair da conta',
                child: BounceButton(
                  onTap: _signOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: colorScheme.error),
                        const SizedBox(width: 10),
                        Text(
                          'Sair da Conta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenuItem(BuildContext context, bool isDarkMode) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onThemeChanged(!isDarkMode),
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema escuro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ativar aparência escura no aplicativo',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                ignoring: _updatingTheme,
                child: Switch(
                  value: isDarkMode,
                  onChanged: _onThemeChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroReadingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context).copyWith(
        border: Border.all(color: colorScheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu momento de leitura',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue sua jornada em Provérbios hoje.',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                BounceButton(
                  onTap: () => context.push('/reading'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Ler agora',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_stories_rounded, color: colorScheme.primary, size: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final photoURL = _user?.photoURL;
    final displayName = _user?.displayName ?? 'Usuário';
    final email = _user?.email ?? 'Conta conectada';

    return BounceButton(
      onTap: () => context.push('/profile/edit'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(context).copyWith(
          border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                radius: 32,
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                backgroundColor: photoURL == null ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                child: photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                        style: TextStyle(fontSize: 28, color: colorScheme.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visualizar e editar perfil',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.68),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MenuPreferenceItem> _buildPreferenceItems(BuildContext context) {
    return [
      _MenuPreferenceItem(
        icon: Icons.favorite_outline,
        title: 'Meus Favoritos',
        subtitle: 'Versículos e trechos salvos',
        onTap: () => context.push('/library', extra: {'initialIndex': 0}),
      ),
      _MenuPreferenceItem(
        icon: Icons.note_alt_outlined,
        title: 'Minhas Anotações',
        subtitle: 'Ideias e reflexões pessoais',
        onTap: () => context.push('/library', extra: {'initialIndex': 1}),
      ),
      _MenuPreferenceItem(
        icon: Icons.text_fields_sharp,
        title: 'Ajustes de Leitura',
        subtitle: 'Fonte, espaçamento e visual',
        onTap: () => context.push('/settings/reading', extra: {'returnIndex': 2}),
      ),
      _MenuPreferenceItem(
        icon: Icons.notifications_active_outlined,
        title: 'Lembretes Diários',
        subtitle: 'Horários e notificações',
        onTap: () => context.push('/settings/reminders', extra: {'returnIndex': 2}),
      ),
      _MenuPreferenceItem(
        icon: Icons.share_rounded,
        title: 'Compartilhar App',
        subtitle: 'Convidar amigos para usar o ProVê',
        onTap: () => Share.share(
          '📖 Conheça o ProVê! Um app para ler Provérbios diariamente e crescer em sabedoria. Baixe agora!',
        ),
      ),
    ];
  }

  List<_QuickActionItem> _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      _QuickActionItem(
        icon: Icons.menu_book_rounded,
        title: 'Ler Agora',
        subtitle: 'Provérbio do dia',
        color: colorScheme.primary,
        onTap: () => context.push('/reading'),
      ),
      _QuickActionItem(
        icon: Icons.local_fire_department_rounded,
        title: 'Ofensiva',
        subtitle: 'Ver progresso',
        color: const Color(0xFFD65108),
        onTap: () => context.go('/home', extra: {'index': 1}),
      ),
      _QuickActionItem(
        icon: Icons.favorite_rounded,
        title: 'Favoritos',
        subtitle: 'Trechos salvos',
        color: const Color(0xFF8E44AD),
        onTap: () => context.push('/library', extra: {'initialIndex': 0}),
      ),
      _QuickActionItem(
        icon: Icons.note_alt_rounded,
        title: 'Anotações',
        subtitle: 'Reflexões pessoais',
        color: const Color(0xFF247BA0),
        onTap: () => context.push('/library', extra: {'initialIndex': 1}),
      ),
    ];
  }

  Widget _buildAboutCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          const AppLogo(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ProVê',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Leia Provérbios todos os dias e cresça em sabedoria.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _MenuPreferenceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuPreferenceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BounceButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.68),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
