import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/note.dart'; // Importa o modelo Note
import 'package:myapp/screens/login_page.dart';
import 'package:myapp/screens/signup_page.dart';
import 'package:myapp/screens/main_scaffold.dart';
import 'package:myapp/screens/reading_page.dart';
import 'package:myapp/screens/note_page.dart';
import 'package:myapp/screens/reminders_settings_page.dart';
import 'package:myapp/screens/favorites_page.dart';
import 'package:myapp/screens/notes_list_page.dart';
import 'package:myapp/screens/note_editor_page.dart';
import 'package:myapp/screens/widgets_page.dart';
import 'package:myapp/screens/notifications_page.dart';
import 'package:myapp/screens/profile_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
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
      path: '/home',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: '/reading',
      builder: (context, state) => const ReadingPage(),
      routes: [
        GoRoute(
          path: 'new-note',
          builder: (context, state) {
            final selectedText = state.extra as String? ?? '';
            return NotePage(selectedText: selectedText);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings/reminders',
      builder: (context, state) => const RemindersSettingsPage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesListPage(),
        routes: [
          GoRoute(
            path: 'editor',
            builder: (context, state) {
              // Agora a rota conhece o tipo 'Note'
              final note = state.extra as Note?;
              return NoteEditorPage(note: note);
            },
          )
        ]),
    GoRoute(
      path: '/widgets',
      builder: (context, state) => const WidgetsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
