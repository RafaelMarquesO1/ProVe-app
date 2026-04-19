import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/login_page.dart';
import 'package:myapp/screens/signup_page.dart';
import 'package:myapp/screens/main_scaffold.dart';
import 'package:myapp/screens/reading_page.dart';
import 'package:myapp/screens/note_page.dart';
import 'package:myapp/screens/reminders_settings_page.dart';
import 'package:myapp/screens/favorites_page.dart';
import 'package:myapp/screens/widgets_page.dart';
import 'package:myapp/screens/notifications_page.dart';
import 'package:myapp/screens/edit_profile_page.dart';
import 'package:myapp/screens/reading_settings_page.dart';
import 'package:myapp/screens/verify_email_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  GoRouterRefreshStream() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(),
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final bool loggedIn = user != null;
    final String location = state.matchedLocation;
    const publicRoutes = {'/', '/signup', '/verify-email'};
    final bool isAuthRoute = publicRoutes.contains(location);

    if (!loggedIn) {
      return isAuthRoute ? null : '/';
    }

    // Se j estiver logado e tentar entrar em / ou /signup, manda pra home
    if (isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        final registrationData = state.extra as Map<String, dynamic>?;
        return VerifyEmailPage(registrationData: registrationData);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      // O builder agora simplesmente retorna o filho (a tela da rota correspondente)
      builder: (context, state, child) {
        return child;
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final Map<String, dynamic> extra = (state.extra as Map<String, dynamic>?) ?? {};
            final int initialIndex = extra['index'] as int? ?? 0;
            final bool showConfetti = extra['showConfetti'] as bool? ?? false;
            return MainScaffold(initialIndex: initialIndex, showConfetti: showConfetti);
          },
        ),
        GoRoute(
          path: '/reading',
          builder: (context, state) => const ReadingPage(),
          routes: [
            GoRoute(
              path: 'nova-nota',
              builder: (context, state) {
                final selectedText = state.extra as String? ?? '';
                return NotePage(selectedText: selectedText);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings/reminders',
          builder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int returnIndex = extra['returnIndex'] as int? ?? 0;
            return RemindersSettingsPage(returnIndex: returnIndex);
          },
        ),
        GoRoute(
          path: '/settings/reading',
          builder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int returnIndex = extra['returnIndex'] as int? ?? 0;
            return ReadingSettingsPage(returnIndex: returnIndex);
          },
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
        GoRoute(
          path: '/widgets',
          builder: (context, state) => const WidgetsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
    ),
  ],
);
