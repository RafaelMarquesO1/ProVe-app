import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prove/services/local_auth_service.dart';
import 'package:prove/widgets/app_alerts.dart';
import 'package:prove/widgets/bounce_button.dart';
import 'package:prove/widgets/photo_reframer.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  String? _nameErrorText;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (pickedFile != null && mounted) {
      final cropped = await PhotoReframer.reframe(
        context: context,
        imageFile: File(pickedFile.path),
      );
      if (cropped != null && mounted) {
        setState(() => _imageFile = cropped);
      }
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Escolher da galeria'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Usar câmera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                if (_imageFile != null)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                    ),
                    title: Text(
                      'Remover foto',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _imageFile = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _nameErrorText = null;
    });

    try {
      await LocalAuthService.instance.createProfile(
        name: _nameController.text,
        photoFile: _imageFile,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Nao foi possivel criar o perfil.',
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
    final name = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Cabeçalho ──────────────────────────────────────
                        Text(
                          'CRIE SEU\nPERFIL',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 36,
                            letterSpacing: 1.5,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Como podemos te chamar?',
                          style: GoogleFonts.lato(
                            color: colorScheme.onSurface.withOpacity(0.55),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Avatar ─────────────────────────────────────────
                        Center(
                          child: BounceButton(
                            onTap: _showImageSourceSheet,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Avatar simples sem anel de gradiente exagerado
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.primary.withOpacity(0.3),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                                      backgroundImage: _imageFile != null
                                          ? FileImage(_imageFile!)
                                          : null,
                                      child: _imageFile == null
                                          ? Text(
                                              initial,
                                              style: GoogleFonts.oswald(
                                                fontSize: 42,
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                // Badge câmera simples com cor sólida
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            _imageFile == null ? 'Adicionar foto' : 'Alterar foto',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Campo de nome ──────────────────────────────────
                        TextFormField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Seu nome',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                            errorText: _nameErrorText,
                          ),
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Informe seu nome';
                            if (trimmed.length < 2) {
                              return 'Informe pelo menos 2 letras';
                            }
                            if (trimmed.length > 80) {
                              return 'Use ate 80 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        // ── Botão ──────────────────────────────────────────
                        BounceButton(
                          onTap: _isLoading ? () {} : _signUp,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
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
                                        const Text(
                                          'CONTINUAR',
                                          style: TextStyle(
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
