import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/bounce_button.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  User? _user;
  late final AnimationController _attentionController;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..repeat(reverse: true);
    FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _attentionController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: child,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Row(
              children: [
                Icon(Icons.logout_rounded, color: Colors.red.shade700),
                const SizedBox(width: 10),
                const Text('Sair da Conta'),
              ],
            ),
            content: const Text('Tem certeza que deseja sair agora?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Sessão encerrada com sucesso.',
          type: AppAlertType.info,
        );
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MENU',
              style: textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie sua jornada e preferências',
              style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 32),

            _buildSectionTitle(context, 'SUA CONTA'),
            _buildProfileCard(context),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'PREFERÊNCIAS'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.text_fields_sharp,
                    title: 'Ajustes de Leitura',
                    onTap: () =>
                        context.go('/settings/reading', extra: {'returnIndex': 2}),
                  ),
                  Divider(height: 1, indent: 70, color: Colors.grey.shade100),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Lembretes Diários',
                    onTap: () => context.go(
                      '/settings/reminders',
                      extra: {'returnIndex': 2},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(context, 'SAIR'),
            Semantics(
              button: true,
              label: 'Sair da conta',
              child: BounceButton(
                onTap: _signOut,
                child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Sair da Conta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final photoURL = _user?.photoURL;
    final displayName = _user?.displayName ?? 'Usuário';

    return BounceButton(
      onTap: () => context.go('/profile/edit'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _attentionController,
              builder: (context, child) {
                final pulse = 1 + (math.sin(_attentionController.value * math.pi) * 0.03);
                return Transform.scale(scale: pulse, child: child);
              },
              child: Hero(
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
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.menu_book_rounded,
            title: 'Ler Agora',
            subtitle: 'Provérbio do dia',
            color: colorScheme.primary,
            onTap: () => context.go('/reading'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.local_fire_department_rounded,
            title: 'Ofensiva',
            subtitle: 'Ver progresso',
            color: const Color(0xFFD65108),
            onTap: () => context.go('/home', extra: {'index': 1}),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

