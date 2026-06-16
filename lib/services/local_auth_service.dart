import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:prove/models/user_model.dart';
import 'package:prove/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  LocalAuthService._internal();
  static final LocalAuthService instance = LocalAuthService._internal();

  static const String _sessionKey = 'local_session_active';

  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();
  final StreamController<UserModel?> _profileController =
      StreamController<UserModel?>.broadcast();

  bool _initialized = false;
  bool _sessionActive = false;
  UserModel? _currentUser;

  UserModel? get currentUser => _sessionActive ? _currentUser : null;
  bool get isSignedIn => currentUser != null;
  Stream<bool> get authStateChanges => _authController.stream;
  Stream<UserModel?> get profileChanges => _profileController.stream;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _sessionActive = prefs.getBool(_sessionKey) ?? false;
    _currentUser = await DatabaseService.instance.getUserProfile();

    _emit();
  }

  Future<bool> hasProfile() async {
    await init();
    return _currentUser != null;
  }

  Future<void> signIn() async {
    await init();
    if (_currentUser == null) return;
    _sessionActive = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    _emit();
  }

  Future<UserModel> createProfile({
    required String name,
    File? photoFile,
  }) async {
    final sanitizedName = _sanitizeName(name);
    final now = DateTime.now();
    final photoPath = await _persistProfilePhoto(photoFile);
    final user = UserModel(
      uid: 'local_user',
      name: sanitizedName,
      photoPath: photoPath,
      createdAt: now,
    );

    await DatabaseService.instance.upsertUserProfile(user);
    _currentUser = user;
    _sessionActive = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);

    _emit();
    return user;
  }

  Future<void> updateProfile({
    required String name,
    File? newPhotoFile,
    bool removePhoto = false,
  }) async {
    await init();
    final current = _currentUser;
    if (current == null) return;

    final String? photoPath;
    if (removePhoto) {
      photoPath = null;
      await _deletePhotoIfLocal(current.photoPath);
    } else if (newPhotoFile != null) {
      photoPath = await _persistProfilePhoto(newPhotoFile);
      await _deletePhotoIfLocal(current.photoPath);
    } else {
      photoPath = current.photoPath;
    }

    final updated = current.copyWith(
      name: _sanitizeName(name),
      photoPath: photoPath,
    );

    await DatabaseService.instance.upsertUserProfile(updated);
    _currentUser = updated;
    _emit();
  }

  Future<void> refreshProfile() async {
    _currentUser = await DatabaseService.instance.getUserProfile();
    _emit();
  }

  Future<void> signOut() async {
    _sessionActive = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, false);
    _emit();
  }

  void _emit() {
    _authController.add(isSignedIn);
    _profileController.add(currentUser);
  }

  String _sanitizeName(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= 80) return collapsed;
    return collapsed.substring(0, 80).trimRight();
  }

  Future<String?> _persistProfilePhoto(File? source) async {
    if (source == null) return null;
    final appDir = await getApplicationSupportDirectory();
    final profileDir = Directory(p.join(appDir.path, 'profile'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    final extension = p.extension(source.path).toLowerCase();
    final safeExtension = ['.jpg', '.jpeg', '.png', '.webp'].contains(extension)
        ? extension
        : '.jpg';
    final target = File(
      p.join(profileDir.path, 'avatar_${DateTime.now().microsecondsSinceEpoch}$safeExtension'),
    );
    return source.copy(target.path).then((file) => file.path);
  }

  Future<void> _deletePhotoIfLocal(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return;
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Erro ao remover foto local antiga: $e');
    }
  }
}
