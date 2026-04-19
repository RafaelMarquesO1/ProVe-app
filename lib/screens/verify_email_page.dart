import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/services/email_service.dart';

class VerifyEmailPage extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const VerifyEmailPage({super.key, this.registrationData});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const int _maxAttempts = 5;
  static const Duration _otpExpiration = Duration(minutes: 10);

  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndRegister() async {
    if (widget.registrationData == null) return;

    final int attempts = widget.registrationData!['otpAttempts'] as int? ?? 0;
    if (attempts >= _maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite de tentativas atingido. Reenvie um novo código.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final int createdAtMillis =
        widget.registrationData!['otpCreatedAt'] as int? ?? 0;
    final bool isExpired = DateTime.now()
        .isAfter(DateTime.fromMillisecondsSinceEpoch(createdAtMillis).add(_otpExpiration));
    if (isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código expirado. Solicite um novo código.'),
          backgroundColor: Colors.orange,
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
          backgroundColor: Colors.orange,
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
                : 'Limite de tentativas atingido. Reenvie um novo código.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String name = widget.registrationData!['name'];
      final String email = widget.registrationData!['email'];
      final String password = widget.registrationData!['password'];

      // 1. Criar o usuário no Firebase Auth agora que o e-mail foi validado
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        // 2. Criar o documento do usuário no Firestore
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
          'isEmailVerified': true, // Já marcado como verificado
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada com sucesso! Bem-vindo.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erro ao criar conta.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro inesperado. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          content: Text('Novo código enviado com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao reenviar o código.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se não houver dados de registro, volta para o início
    if (widget.registrationData == null) {
       Future.delayed(Duration.zero, () => context.go('/'));
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String email = widget.registrationData!['email'];
    final int attempts = widget.registrationData!['otpAttempts'] as int? ?? 0;
    final int remainingAttempts = (_maxAttempts - attempts).clamp(0, _maxAttempts);
    final int createdAtMillis =
        widget.registrationData!['otpCreatedAt'] as int? ?? 0;
    final bool isExpired = DateTime.now()
        .isAfter(DateTime.fromMillisecondsSinceEpoch(createdAtMillis).add(_otpExpiration));
    final bool canValidate = !isExpired && remainingAttempts > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Cadastro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/signup'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DIGITE O CÓDIGO',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Insira o código de 6 dígitos enviado para:\n$email',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isExpired
                  ? 'Código expirado. Reenvie para continuar.'
                  : 'Tentativas restantes: $remainingAttempts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isExpired ? Colors.orange.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _verifyAndRegister(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              maxLength: 6,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading || !canValidate ? null : _verifyAndRegister,
              child: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  ) 
                : const Text('CADASTRAR E ENTRAR'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: EmailService.isConfigured && !_isLoading ? _resendCode : null,
              child: const Text('Reenviar código'),
            ),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('E-mail incorreto? Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
