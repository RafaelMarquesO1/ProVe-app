import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/widgets/app_alerts.dart';
import 'package:myapp/widgets/bounce_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _storedPhotoUrl;
  bool _removeCurrentPhoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _currentUser?.displayName ?? '';
    _storedPhotoUrl = _currentUser?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _removeCurrentPhoto = false;
      });
    }
  }

  Future<String?> _uploadProfilePicture(String userId) async {
    if (_imageFile == null) return null;
    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Erro ao enviar foto: $e',
          type: AppAlertType.error,
        );
      }
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bool canProceed = await _showPreviewAndConfirmSave();
    if (!canProceed) return;

    final user = _currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoURL = user.photoURL;
      if (_removeCurrentPhoto) {
        photoURL = null;
      } else if (_imageFile != null) {
        photoURL = await _uploadProfilePicture(user.uid);
      }

      await user.updateDisplayName(_nameController.text);
      await user.updatePhotoURL(photoURL);
      await user.reload();
      
      final Map<String, dynamic> updateData = {
        'name': _nameController.text,
      };
      updateData['photoURL'] = photoURL;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      setState(() {
        _storedPhotoUrl = photoURL;
        _imageFile = null;
        _removeCurrentPhoto = false;
      });

      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        final email = user.email;
        if (email != null) {
          AuthCredential credential = EmailAuthProvider.credential(
              email: email, password: _currentPasswordController.text);
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);
        }
      }

      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Perfil atualizado com sucesso!',
          type: AppAlertType.success,
        );
        context.go('/home', extra: {'index': 2});
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        AppAlerts.showSnackBar(
          context,
          message: 'Erro: ${e.message}',
          type: AppAlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto de perfil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Escolha de onde deseja selecionar a imagem.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galeria'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Câmera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                if (_storedPhotoUrl != null || _imageFile != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(Icons.delete_outline_rounded),
                    iconColor: Colors.red.shade700,
                    title: const Text('Remover foto atual'),
                    textColor: Colors.red.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                        _storedPhotoUrl = null;
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
    final ImageProvider? imageProvider = _imageFile != null
        ? FileImage(_imageFile!)
        : (_storedPhotoUrl != null ? NetworkImage(_storedPhotoUrl!) : null);

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Confirmar alterações'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
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
                'Verifique os dados antes de salvar.',
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
                'Mantenha seus dados sempre atualizados',
                style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              _buildAvatar(context, colorScheme),
              const SizedBox(height: 40),
              
              _buildSectionTitle(context, 'INFORMAÇÕES BÁSICAS'),
              _buildInfoContainer(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) => (value?.isEmpty ?? true) ? 'O nome não pode estar em branco' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _currentUser?.email,
                      enabled: false,
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle(context, 'SEGURANÇA'),
              _buildInfoContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alterar Senha',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preencha apenas se desejar alterar sua senha atual.',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha Atual',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nova Senha',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                    ),
                  ],
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
                            'Salvar Alterações',
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
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
    final photoURL = _storedPhotoUrl;
    final displayName = _currentUser?.displayName ?? 'U';

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
                radius: 64,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (photoURL != null ? NetworkImage(photoURL) : null),
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: _imageFile == null && photoURL == null
                    ? Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: colorScheme.primary),
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
                  border: Border.all(color: Colors.white, width: 3),
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
}

