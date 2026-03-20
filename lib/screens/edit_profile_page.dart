import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _currentUser?.displayName ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfilePicture(String userId) async {
    if (_imageFile == null) return null;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child('$userId.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
      }
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false) || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoURL = _currentUser?.photoURL;
      if (_imageFile != null) {
        photoURL = await _uploadProfilePicture(_currentUser!.uid);
      }

      await _currentUser?.updateDisplayName(_nameController.text);
      if (photoURL != null) {
        await _currentUser?.updatePhotoURL(photoURL);
      }

      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        final email = _currentUser?.email;
        if (email != null) {
          AuthCredential credential = EmailAuthProvider.credential(
              email: email, password: _currentPasswordController.text);
          await _currentUser?.reauthenticateWithCredential(credential);
          await _currentUser?.updatePassword(_newPasswordController.text);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!')));
        context.go('/home');
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'INFORMAÇÕES PESSOAIS'),
              _buildUserInfoCard(theme),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'SEGURANÇA'),
              _buildPasswordCard(theme),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (_currentUser?.photoURL != null ? NetworkImage(_currentUser!.photoURL!) : null) as ImageProvider?,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: _imageFile == null && _currentUser?.photoURL == null
                ? Icon(Icons.person, size: 80, color: colorScheme.onSurface)
                : null,
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: _pickImage,
                tooltip: 'Alterar Foto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTextField(
              controller: _nameController,
              label: 'Nome Completo',
              icon: Icons.person_outline,
              validator: (value) => (value?.isEmpty ?? true) ? 'O nome não pode estar em branco' : null,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTextField(
              controller: TextEditingController(text: _currentUser?.email ?? 'E-mail não disponível'),
              label: 'E-mail',
              icon: Icons.email_outlined,
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alterar Senha', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Deixe os campos em branco se não desejar alterar a senha.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _currentPasswordController,
              label: 'Senha Atual',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              label: 'Nova Senha',
              icon: Icons.lock_clock_outlined,
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
