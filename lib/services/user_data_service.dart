import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserDataService {
  UserDataService._internal();
  static final UserDataService instance = UserDataService._internal();
  factory UserDataService() => instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> _ensureAuth() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        debugPrint('Error signing in anonymously: $e');
      }
    }
  }

  // --- FAVORITES ---

  Future<void> toggleFavorite({
    required String chapter,
    required String verseNumber,
    required String verseText,
  }) async {
    try {
      await _ensureAuth();
      if (_uid == null) return;
      
      final docId = '${chapter}_$verseNumber';
      final docRef = _firestore.collection('users').doc(_uid).collection('favorites').doc(docId);
      
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'chapter': chapter,
          'verseNumber': verseNumber,
          'text': verseText,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(String chapter, String verseNumber) async {
    if (_uid == null) return false;
    try {
      final docId = '${chapter}_$verseNumber';
      final docSnap = await _firestore.collection('users').doc(_uid).collection('favorites').doc(docId).get();
      return docSnap.exists;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getFavoritesStream() {
    if (_uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteFavorite(String docId) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('favorites').doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting favorite: $e');
      rethrow;
    }
  }

  // --- NOTES ---

  Future<void> saveNote({
    required String reference,
    required String verseText,
    required String noteText,
  }) async {
    try {
      await _ensureAuth();
      if (_uid == null) return;
      
      await _firestore.collection('users').doc(_uid).collection('notes').add({
        'reference': reference,
        'verseText': verseText,
        'noteText': noteText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving note: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getNotesStream() {
    if (_uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteNote(String docId) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).collection('notes').doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }
}
