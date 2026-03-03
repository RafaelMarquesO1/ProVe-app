import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título
              Text(
                'ENTRE AQUI!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 42),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Digite seus dados para entrar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),

              // Campo de E-mail
              const TextField(
                decoration: InputDecoration(
                  labelText: 'E-mail',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Campo de Senha
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Senha',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Botão Entrar
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text('ENTRAR'),
              ),
              const SizedBox(height: 48),

              // Link para cadastro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não possui conta?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navega para a tela de cadastro
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
    );
  }
}