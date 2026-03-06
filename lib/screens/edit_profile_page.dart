import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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

      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'name': _nameController.text,
        if (photoURL != null) 'photoURL': photoURL,
      });

      if (_currentPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
            email: _currentUser!.email!, password: _currentPasswordController.text);
        await _currentUser!.reauthenticateWithCredential(credential);
        await _currentUser!.updatePassword(_newPasswordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!')));
        // CORREÇÃO: Navega para a tela de menu principal, limpando o histórico de navegação.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        // CORREÇÃO: Garante que o botão de voltar sempre leve para a home/menu.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // Navega para a home, que contém o menu
          tooltip: 'Voltar ao Menu',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value!.isEmpty ? 'O nome não pode estar em branco' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Alterar Senha', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Senha Atual'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Nova Senha'),
                obscureText: true,
              ),
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

  Widget _buildAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: _imageFile != null 
              ? FileImage(_imageFile!) 
              : (_currentUser?.photoURL != null ? NetworkImage(_currentUser!.photoURL!) : null) as ImageProvider?,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: _imageFile == null && _currentUser?.photoURL == null 
              ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_camera),
          label: const Text('Alterar Foto'),
          onPressed: _pickImage,
        ),
      ],
    );
  }
}
