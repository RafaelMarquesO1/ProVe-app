
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Aqui tinha uma setinha para redirecionar, que foi removida
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título
              Text(
                'CRIE SUA CONTA',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Insira seus dados para começar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),

              // Campo de Nome
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Nome Completo',
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 24),

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

              // Botão Cadastrar
              ElevatedButton(
                onPressed: () {
                  // Lógica de cadastro aqui
                },
                child: const Text('CADASTRAR'),
              ),
              const SizedBox(height: 48),

              // Link para login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já possui uma conta?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // Retorna para a tela de login
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
    );
  }
}
