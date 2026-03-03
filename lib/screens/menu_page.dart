import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

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

            // Container não-flutuante para as opções de menu
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

            // Container não-flutuante para o botão de sair
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
                onTap: () => context.go('/'),
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      elevation: 2, // Mantém a elevação aqui para destacar o perfil
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/profile'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome do Usuário', style: textTheme.titleLarge),
                  Text('Ver Perfil', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                ],
              ),
              const Spacer(),
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
