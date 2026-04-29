import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/email_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/widgets/bounce_button.dart';

class VerifyEmailPage extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const VerifyEmailPage({super.key, this.registrationData});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with SingleTickerProviderStateMixin {
  static const int _maxAttempts = 5;
  static const Duration _otpExpiration = Duration(minutes: 10);

  final _codeController = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndRegister() async {
    if (widget.registrationData == null) return;

    final int attempts = widget.registrationData!['otpAttempts'] as int? ?? 0;
    if (attempts >= _maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite de tentativas atingido.'),
          backgroundColor: Color(0xFFD17A00),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int createdAtMillis =
        widget.registrationData!['otpCreatedAt'] as int? ?? 0;
    final bool isExpired = DateTime.now().isAfter(
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis).add(_otpExpiration),
    );
    if (isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código expirado. Solicite um novo.'),
          backgroundColor: Color(0xFFD17A00),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String inputCode = _codeController.text.trim();
    final String? correctCode = widget.registrationData?['code'];

    if (inputCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite os 6 dígitos do código.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (inputCode != correctCode) {
      final int updatedAttempts = attempts + 1;
      widget.registrationData!['otpAttempts'] = updatedAttempts;
      final int remainingAttempts = _maxAttempts - updatedAttempts;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remainingAttempts > 0
                ? 'Código incorreto. Restam $remainingAttempts tentativas.'
                : 'Limite de tentativas atingido.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String name = widget.registrationData!['name'];
      final String email = widget.registrationData!['email'];
      final String password = widget.registrationData!['password'];

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erro ao criar conta.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (widget.registrationData == null || !EmailService.isConfigured) return;
    final String name = widget.registrationData!['name'];
    final String email = widget.registrationData!['email'];
    final String newCode = (100000 + Random().nextInt(900000)).toString();

    setState(() => _isLoading = true);
    final bool sent = await EmailService.sendOTP(
      userName: name,
      userEmail: email,
      otpCode: newCode,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);
    if (sent) {
      widget.registrationData!['code'] = newCode;
      widget.registrationData!['otpCreatedAt'] =
          DateTime.now().millisecondsSinceEpoch;
      widget.registrationData!['otpAttempts'] = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Novo código enviado!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao reenviar.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.registrationData == null) {
      Future.delayed(Duration.zero, () => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String email = widget.registrationData!['email'];
    final int attempts = widget.registrationData!['otpAttempts'] as int? ?? 0;
    final int remainingAttempts = (_maxAttempts - attempts).clamp(
      0,
      _maxAttempts,
    );
    final int createdAtMillis =
        widget.registrationData!['otpCreatedAt'] as int? ?? 0;
    final bool isExpired = DateTime.now().isAfter(
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis).add(_otpExpiration),
    );
    final bool canValidate = !isExpired && remainingAttempts > 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/signup'),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'VALIDAR E-MAIL',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Digite o código de 6 dígitos que enviamos para:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 32,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    maxLength: 6,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isExpired
                        ? 'O código expirou.'
                        : 'Tentativas restantes: $remainingAttempts',
                    style: TextStyle(
                      color: isExpired
                          ? colorScheme.error
                          : colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 40),
                  BounceButton(
                    onTap: _isLoading || !canValidate
                        ? () {}
                        : _verifyAndRegister,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: canValidate
                              ? [colorScheme.primary, const Color(0xFFD65108)]
                              : [
                                  colorScheme.onSurface.withOpacity(0.35),
                                  colorScheme.onSurface.withOpacity(0.5),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: canValidate
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'CADASTRAR E ENTRAR',
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
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: EmailService.isConfigured && !_isLoading
                            ? _resendCode
                            : null,
                        child: const Text('Reenviar código'),
                      ),
                      Text(
                        '|',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
