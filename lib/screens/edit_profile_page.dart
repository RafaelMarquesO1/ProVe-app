import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/local_auth_service.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/bounce_button.dart';
import 'package:myapp/widgets/photo_reframer.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? _storedPhotoPath;
  bool _removeCurrentPhoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = LocalAuthService.instance.currentUser;
    _nameController.text = currentUser?.name ?? '';
    _storedPhotoPath = currentUser?.photoPath;
  }

  @override
  void dispose() {
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
        setState(() {
          _imageFile = cropped;
          _removeCurrentPhoto = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final canProceed = await _showPreviewAndConfirmSave();
    if (!canProceed) return;

    setState(() => _isLoading = true);

    try {
      await LocalAuthService.instance.updateProfile(
        name: _nameController.text,
        newPhotoFile: _imageFile,
        removePhoto: _removeCurrentPhoto,
      );

      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Perfil atualizado com sucesso!',
          type: AppAlertType.success,
        );
        context.go('/home', extra: {'index': 2});
      }
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Nao foi possivel salvar o perfil local.',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galeria'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                if (_storedPhotoPath != null || _imageFile != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
                    title: Text('Remover foto atual', style: TextStyle(color: Colors.red.shade700)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                        _storedPhotoPath = null;
                        _removeCurrentPhoto = true;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showPreviewAndConfirmSave() async {
    final imageProvider = _currentImageProvider();
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Confirmar alteracoes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        _avatarInitial(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _nameController.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Deseja salvar as alteracoes do seu perfil?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Revisar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    return confirm ?? false;
  }

  ImageProvider? _currentImageProvider() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (_storedPhotoPath != null) return FileImage(File(_storedPhotoPath!));
    return null;
  }

  String _avatarInitial() {
    final displayName = _nameController.text.trim();
    return displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = _nameController.text.trim().isEmpty
        ? (LocalAuthService.instance.currentUser?.name ?? 'Usuario')
        : _nameController.text.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/home', extra: {'index': 2}),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MEU PERFIL',
                style: textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Mantenha seu perfil atualizado',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileHeader(context, colorScheme, displayName),
              const SizedBox(height: 28),
              _buildSectionTitle(context, 'INFORMACOES BASICAS'),
              _buildInfoContainer(
                child: TextFormField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'O nome nao pode estar em branco';
                    if (trimmed.length < 2) return 'Informe pelo menos 2 letras';
                    if (trimmed.length > 80) return 'Use ate 80 caracteres';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 40),
              BounceButton(
                onTap: _isLoading ? () {} : _updateProfile,
                child: Container(
                  height: 56,
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
                            'Salvar Alteracoes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildInfoContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme colorScheme) {
    final imageProvider = _currentImageProvider();
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2),
            ),
            child: Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                radius: 56,
                backgroundImage: imageProvider,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: imageProvider == null
                    ? Text(
                        _avatarInitial(),
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: BounceButton(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ColorScheme colorScheme,
    String displayName,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(context, colorScheme),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showImageSourceSheet,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: const Text('Trocar foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary.withOpacity(0.28)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
