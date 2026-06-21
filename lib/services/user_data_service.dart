import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:prove/services/database_service.dart';

class UserDataService {
  UserDataService._internal();
  static final UserDataService instance = UserDataService._internal();
  factory UserDataService() => instance;

  // Usar StreamControllers broadcast simples — sem async* generators
  // para evitar Bad State ao re-subscrever em navegações
  final _favoritesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _notesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Último valor conhecido (cache em memória)
  List<Map<String, dynamic>>? _lastFavorites;
  List<Map<String, dynamic>>? _lastNotes;

  /// Retorna um Stream que emite imediatamente o valor atual e depois
  /// emite atualizações subsequentes via broadcast.
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    StreamSubscription? sub;
    controller.onListen = () {
      final initial = _lastFavorites;
      if (initial != null) {
        controller.add(initial);
      } else {
        DatabaseService.instance.getFavorites().then((val) {
          _lastFavorites = val;
          if (!controller.isClosed) controller.add(val);
        });
      }
      sub = _favoritesController.stream.listen(
        (val) {
          if (!controller.isClosed) controller.add(val);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    };
    controller.onCancel = () {
      sub?.cancel();
    };
    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> getNotesStream() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    StreamSubscription? sub;
    controller.onListen = () {
      final initial = _lastNotes;
      if (initial != null) {
        controller.add(initial);
      } else {
        DatabaseService.instance.getNotes().then((val) {
          _lastNotes = val;
          if (!controller.isClosed) controller.add(val);
        });
      }
      sub = _notesController.stream.listen(
        (val) {
          if (!controller.isClosed) controller.add(val);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    };
    controller.onCancel = () {
      sub?.cancel();
    };
    return controller.stream;
  }

  Future<void> toggleFavorite({
    required String chapter,
    required String verseNumber,
    required String verseText,
  }) async {
    try {
      await DatabaseService.instance.toggleFavorite(
        chapter: chapter,
        verseNumber: verseNumber,
        verseText: verseText,
      );
      await refreshFavorites();
    } catch (e) {
      debugPrint('Erro ao alternar favorito local: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(String chapter, String verseNumber) {
    return DatabaseService.instance.isFavorite(chapter, verseNumber);
  }

  Future<void> refreshFavorites() async {
    final favorites = await DatabaseService.instance.getFavorites();
    _lastFavorites = favorites;
    if (!_favoritesController.isClosed) {
      _favoritesController.add(favorites);
    }
  }

  Future<void> deleteFavorite(String id) async {
    await DatabaseService.instance.deleteFavorite(id);
    await refreshFavorites();
  }

  Future<void> saveNote({
    required String reference,
    required String verseText,
    required String noteText,
    String? mood,
    String? imagePath,
    List<String>? verseKeys,
    String? title,
  }) async {
    try {
      await DatabaseService.instance.saveNote(
        reference: reference,
        verseText: verseText,
        noteText: noteText,
        mood: mood,
        imagePath: imagePath,
        verseKeys: verseKeys,
        title: title,
      );
      await refreshNotes();
    } catch (e) {
      debugPrint('Erro ao salvar anotacao local: $e');
      rethrow;
    }
  }

  Future<void> refreshNotes() async {
    final notes = await DatabaseService.instance.getNotes();
    _lastNotes = notes;
    if (!_notesController.isClosed) {
      _notesController.add(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.instance.deleteNote(id);
    await refreshNotes();
  }
}
