import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prove/services/local_auth_service.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:prove/widgets/app_logo.dart';
import 'package:prove/widgets/bounce_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasProfile = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadProfileState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileState() async {
    final hasProfile = await LocalAuthService.instance.hasProfile();
    if (mounted) setState(() => _hasProfile = hasProfile);
  }

  Future<void> _continueLocally() async {
    setState(() => _isLoading = true);
    try {
      if (_hasProfile) {
        await LocalAuthService.instance.signIn();
      }
      if (mounted) {
        context.go(_hasProfile ? '/home' : '/signup');
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Nao foi possivel abrir seu perfil.',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = LocalAuthService.instance.currentUser;
    final firstName = user?.name.trim().split(' ').first;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Gradiente de fundo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),

          // Blobs decorativos
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(isDark ? 0.1 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(isDark ? 0.05 : 0.04),
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),

                    // Logo
                    Center(child: const AppLogo(size: 100)),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      _hasProfile ? 'BEM-VINDO\nDE VOLTA!' : 'BEM-VINDO!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        letterSpacing: 1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo
                    Text(
                      _hasProfile && firstName != null
                          ? 'Continue sua jornada, $firstName.'
                          : 'Comece sua jornada pelos Provérbios.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Botão principal
                    BounceButton(
                      onTap: _isLoading ? () {} : _continueLocally,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              const Color(0xFFD65108),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _hasProfile ? 'ENTRAR' : 'COMEÇAR',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
