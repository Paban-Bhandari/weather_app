import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  firebase_auth.FirebaseAuth? _auth;

  firebase_auth.FirebaseAuth get _firebaseAuth {
    _auth ??= firebase_auth.FirebaseAuth.instance;
    return _auth!;
  }

  // Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  // Create user profile
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Save weather search to history
  Future<void> saveWeatherSearch({
    required String city,
    required Map<String, dynamic> weatherData,
  }) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('weather_history')
          .add({
            'city': city,
            'weatherData': weatherData,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error saving weather search: $e');
      rethrow;
    }
  }

  // Get weather history
  Stream<QuerySnapshot> getWeatherHistory() {
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('weather_history')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  // Save favorite city
  Future<void> saveFavoriteCity({
    required String city,
    required String country,
  }) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(city)
          .set({
            'city': city,
            'country': country,
            'addedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error saving favorite city: $e');
      rethrow;
    }
  }

  // Remove favorite city
  Future<void> removeFavoriteCity(String city) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(city)
          .delete();
    } catch (e) {
      print('Error removing favorite city: $e');
      rethrow;
    }
  }

  // Get favorite cities
  Stream<QuerySnapshot> getFavoriteCities() {
    if (currentUserId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Check if city is favorite
  Future<bool> isFavoriteCity(String city) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(city)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite city: $e');
      return false;
    }
  }

  // Delete weather history
  Future<void> deleteWeatherHistory() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final historyDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('weather_history')
          .get();

      for (var doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting weather history: $e');
      rethrow;
    }
  }

  // Delete specific weather history item
  Future<void> deleteWeatherHistoryItem(String city) async {
    if (currentUserId == null) return;

    try {
      final historyDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('weather_history')
          .where('city', isEqualTo: city)
          .get();

      final batch = _firestore.batch();
      for (var doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting weather history item: $e');
      rethrow;
    }
  }
}
