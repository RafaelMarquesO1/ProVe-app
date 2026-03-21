import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CONFIGURAÇÕES',
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie sua conta e preferências',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 32),

            _buildSectionTitle(context, 'CONTA'),
            _buildProfileCard(context),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'GERAL'),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.text_fields_sharp,
                    title: 'Ajustes de Leitura',
                    onTap: () => context.go('/settings/reading'),
                  ),
                  const Divider(height: 1, indent: 70),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Lembretes',
                    onTap: () => context.go('/settings/reminders'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(context, 'SAIR'),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Sair da Conta',
                onTap: _signOut,
                isLogout: true,
              ),
            ),
          ],
        ),
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
          color: theme.textTheme.bodySmall?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final photoURL = _user?.photoURL;
    final displayName = _user?.displayName ?? 'Nome do Usuário';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/profile/edit'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                backgroundColor: photoURL == null ? colorScheme.primary.withAlpha(26) : Colors.transparent,
                child: photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                        style: TextStyle(fontSize: 28, color: colorScheme.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Visualizar e editar perfil', style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap, bool isLogout = false}) {
    final color = isLogout ? Colors.red.shade700 : Theme.of(context).textTheme.bodyLarge?.color;
    final iconColor = isLogout ? Colors.red.shade700 : Theme.of(context).colorScheme.primary;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isLogout ? Colors.red.shade50 : Theme.of(context).colorScheme.primary).withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 24, color: iconColor),
      ),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
