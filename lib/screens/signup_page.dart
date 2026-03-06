import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'readingStreak': 0,
          'lastReadDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'completedDays': [], // INICIALIZA A LISTA
          'currentChapter': 1, // INICIALIZA O CAPÍTULO ATUAL
        });

        if (mounted) {
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Ocorreu um erro desconhecido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar os dados do usuário.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'CRIE SUA CONTA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Text(
                  'Insira seus dados para começar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira seu nome completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Por favor, insira um e-mail válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('CADASTRAR'),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já possui uma conta?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
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
      ),
    );
  }
}
