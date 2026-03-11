import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoURL = _currentUser!.photoURL;
      if (_imageFile != null) {
        photoURL = await _uploadProfilePicture(_currentUser!.uid);
      }

      await _currentUser!.updateDisplayName(_nameController.text);
      if (photoURL != null) {
        await _currentUser!.updatePhotoURL(photoURL);
      }

      // A atualização do Firestore já é feita pela função de criação de usuário
      // ou pode ser feita por uma cloud function para manter a consistência.
      // Não é estritamente necessário aqui, a menos que queira dados adicionais.

      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
            email: _currentUser!.email!, password: _currentPasswordController.text);
        await _currentUser!.reauthenticateWithCredential(credential);
        await _currentUser!.updatePassword(_newPasswordController.text);
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
        title: Text('Editar Perfil', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(context),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Nome Completo',
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? 'O nome não pode estar em branco' : null,
              ),
              const SizedBox(height: 16),
              _buildEmailField(theme),
              const SizedBox(height: 24),
              _buildPasswordSection(theme),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 70,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_currentUser?.photoURL != null ? NetworkImage(_currentUser!.photoURL!) : null) as ImageProvider?,
          backgroundColor: colorScheme.surfaceVariant,
          child: _imageFile == null && _currentUser?.photoURL == null
              ? Icon(Icons.person, size: 80, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        Material(
          color: colorScheme.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
            onPressed: _pickImage,
            tooltip: 'Alterar Foto',
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            _currentUser?.email ?? 'E-mail não disponível',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alterar Senha',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Deixe em branco se não quiser alterar.',
              style: theme.textTheme.bodySmall,
            ),
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
}
