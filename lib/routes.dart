
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/login_page.dart';
import 'package:myapp/screens/signup_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/', // A rota inicial será a de login
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpPage(),
    ),
  ],
);
