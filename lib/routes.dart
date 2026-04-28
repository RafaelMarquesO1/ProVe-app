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
import 'package:myapp/screens/edit_profile_page.dart';
import 'package:myapp/screens/reading_settings_page.dart';
import 'package:myapp/screens/verify_email_page.dart';
import 'package:myapp/screens/library_page.dart';

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

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

    // Se já estiver logado e tentar entrar em / ou /signup, manda pra home
    if (isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => buildPageWithDefaultTransition(
        context: context,
        state: state,
        child: const SignUpPage(),
      ),
    ),
    GoRoute(
      path: '/verify-email',
      pageBuilder: (context, state) {
        final registrationData = state.extra as Map<String, dynamic>?;
        return buildPageWithDefaultTransition(
          context: context,
          state: state,
          child: VerifyEmailPage(registrationData: registrationData),
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return child;
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int initialIndex = extra['index'] as int? ?? 0;
            final bool showConfetti = extra['showConfetti'] as bool? ?? false;
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: MainScaffold(
                  initialIndex: initialIndex, showConfetti: showConfetti),
            );
          },
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int initialIndex = extra['initialIndex'] as int? ?? 0;
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: LibraryPage(initialIndex: initialIndex),
            );
          },
        ),
        GoRoute(
          path: '/reading',
          pageBuilder: (context, state) => buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const ReadingPage(),
          ),
          routes: [
            GoRoute(
              path: 'nova-nota',
              pageBuilder: (context, state) {
                final selectedText = state.extra as String? ?? '';
                return buildPageWithDefaultTransition(
                  context: context,
                  state: state,
                  child: NotePage(selectedText: selectedText),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings/reminders',
          pageBuilder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int returnIndex = extra['returnIndex'] as int? ?? 0;
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: RemindersSettingsPage(returnIndex: returnIndex),
            );
          },
        ),
        GoRoute(
          path: '/settings/reading',
          pageBuilder: (context, state) {
            final Map<String, dynamic> extra =
                (state.extra as Map<String, dynamic>?) ?? {};
            final int returnIndex = extra['returnIndex'] as int? ?? 0;
            return buildPageWithDefaultTransition(
              context: context,
              state: state,
              child: ReadingSettingsPage(returnIndex: returnIndex),
            );
          },
        ),
        GoRoute(
          path: '/profile/edit',
          pageBuilder: (context, state) => buildPageWithDefaultTransition(
            context: context,
            state: state,
            child: const EditProfilePage(),
          ),
        ),
      ],
    ),
  ],
);
