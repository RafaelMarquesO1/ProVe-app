
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Noise texture
          Container(
            color: Colors.black.withOpacity(0.1),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Title
                  Text(
                    'ENTRE AQUI!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Digite seus dados para entrar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 48),

                  // Login form card
                  Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),

                        // Password field
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Senha',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 32),

                        // Login button
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to the main screen after login
                            context.go('/home');
                          },
                          child: const Text('ENTRAR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não possui conta?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to the sign up screen
                          context.go('/signup');
                        },
                        child: const Text('CADASTRE-SE!'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
