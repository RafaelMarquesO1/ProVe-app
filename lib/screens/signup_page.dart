
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

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
                    'CRIE SUA CONTA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Insira seus dados para começar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 48),

                  // Sign up form card
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
                        // Name field
                        const TextField(
                          decoration: InputDecoration(
                            labelText: 'Nome Completo',
                          ),
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 24),

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

                        // Sign up button
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to the main screen after sign up
                            context.go('/home');
                          },
                          child: const Text('CADASTRAR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já possui uma conta?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          // Go back to the login screen
                          context.go('/');
                        },
                        child: const Text('ENTRE!'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
