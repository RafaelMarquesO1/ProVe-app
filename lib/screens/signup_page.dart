import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/email_service.dart';
import 'package:myapp/widgets/app_logo.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/bounce_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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
              SnackBar(
                content: const Text('Não foi possível enviar o código de verificação.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        email: userEmail,
        password: userPassword,
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
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao criar conta.';
        if (e.code == 'email-already-in-use') {
          _emailErrorText = 'Este e-mail já está em uso.';
        } else if (e.code == 'weak-password') {
          _passwordErrorText = 'Senha muito fraca.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateSixDigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 80),
                    const SizedBox(height: 24),
                    Text(
                      'CRIE SUA CONTA',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Junte-se a nós nesta jornada de sabedoria',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _nameErrorText,
                      ),
                      keyboardType: TextInputType.name,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.email_outlined),
                        errorText: _emailErrorText,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || !value.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        errorText: _passwordErrorText,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.grey.shade400,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 32),
                    BounceButton(
                      onTap: _isLoading ? () {} : _signUp,
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, const Color(0xFFD65108)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'CADASTRAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já possui uma conta? ',
                          style: GoogleFonts.lato(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Text(
                            'ENTRAR',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
