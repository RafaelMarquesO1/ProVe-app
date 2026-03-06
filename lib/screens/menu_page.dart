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
    // Garante que o estado seja atualizado quando o usuário muda
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MENU',
              textAlign: TextAlign.center,
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 24),

            _buildProfileCard(context, textTheme, colorScheme),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite_border,
                    title: 'Favoritos',
                    onTap: () => context.go('/favorites'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.note_alt_outlined,
                    title: 'Anotações',
                    onTap: () => context.go('/notes'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.alarm_outlined,
                    title: 'Lembretes',
                    onTap: () => context.go('/settings/reminders'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    onTap: () => context.go('/notifications'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildMenuItem(
                    context,
                    icon: Icons.widgets_outlined,
                    title: 'Widgets',
                    onTap: () => context.go('/widgets'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Sair',
                onTap: _signOut,
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    final photoURL = _user?.photoURL;
    final displayName = _user?.displayName ?? 'Nome do Usuário';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Alterado: Navega para a tela de edição de perfil
        onTap: () => context.go('/profile/edit'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                backgroundColor: photoURL == null ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                child: photoURL == null
                    ? Text(
                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                        style: TextStyle(fontSize: 24, color: colorScheme.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                    // Alterado: O texto agora indica a ação de edição
                    Text('Editar Perfil', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap, bool isLogout = false}) {
    final color = isLogout ? Colors.red.shade700 : Theme.of(context).colorScheme.primary;
    final textStyle = isLogout
        ? TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)
        : const TextStyle(fontSize: 16);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 26, color: color),
      title: Text(title, style: textStyle),
      trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
