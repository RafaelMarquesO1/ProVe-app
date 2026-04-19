import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/email_service.dart';

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
  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _nameErrorText = null;
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    try {
      final bool emailVerificationEnabled = EmailService.isConfigured;
      final String verificationCode = _generateSixDigitCode();
      final String userName = _nameController.text.trim();
      final String userEmail = _emailController.text.trim();
      final String userPassword = _passwordController.text.trim();

      if (emailVerificationEnabled) {
        final bool sent = await EmailService.sendOTP(
          userName: userName,
          userEmail: userEmail,
          otpCode: verificationCode,
        );

        if (!sent) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não foi possível enviar o código de verificação. Tente novamente em instantes.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (mounted) {
          context.go('/verify-email', extra: {
            'name': userName,
            'email': userEmail,
            'password': userPassword,
            'code': verificationCode,
            'otpCreatedAt': DateTime.now().millisecondsSinceEpoch,
            'otpAttempts': 0,
          });
        }
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(userName);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': userName,
          'email': userEmail,
          'readingStreak': 0,
          'longestStreak': 0,
          'lastReadDate': null,
          'createdAt': FieldValue.serverTimestamp(),
          'completedDays': [],
          'currentChapter': 1,
          'isEmailVerified': true,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada. Ative a chave pública do EmailJS para liberar verificação por código.'),
            ),
          );
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message ?? 'Ocorreu um erro desconhecido.';
        if (e.code == 'email-already-in-use') {
          _emailErrorText = 'Este e-mail já está cadastrado.';
          errorMessage = 'Este e-mail já está em uso.';
        } else if (e.code == 'invalid-email') {
          _emailErrorText = 'Digite um e-mail válido.';
          errorMessage = 'E-mail inválido.';
        } else if (e.code == 'weak-password') {
          _passwordErrorText = 'Senha fraca. Use ao menos 6 caracteres.';
          errorMessage = 'Senha fraca.';
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  String _generateSixDigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  decoration: InputDecoration(
                    labelText: 'Nome Completo',
                    errorText: _nameErrorText,
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  keyboardType: TextInputType.name,
                  onChanged: (_) {
                    if (_nameErrorText != null) {
                      setState(() => _nameErrorText = null);
                    }
                  },
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
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    errorText: _emailErrorText,
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailErrorText != null) {
                      setState(() => _emailErrorText = null);
                    }
                  },
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
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    errorText: _passwordErrorText,
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _isLoading ? null : _signUp(),
                  onChanged: (_) {
                    if (_passwordErrorText != null) {
                      setState(() => _passwordErrorText = null);
                    }
                  },
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
      ),
    );
  }
}
