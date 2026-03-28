import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    String role = 'player',
    String? clubName,
    String? association,
  }) async {
    await _usersCollection.doc(uid).set({
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': FieldValue.serverTimestamp(),
      'role': role,
      'clubName': clubName,
      'association': association,
      'photoUrl': null,
      'bio': null,
    });
  }

  Future<void> updateUserDocument({
    required String uid,
    String? firstName,
    String? lastName,
    String? username,
    String? clubName,
    String? association,
    String? bio,
    double? handicap,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (username != null) updates['username'] = username;
    if (clubName != null) updates['clubName'] = clubName;
    if (association != null) updates['association'] = association;
    if (bio != null) updates['bio'] = bio;
    if (handicap != null) updates['handicap'] = handicap;

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).update(updates);
    }
  }

  Future<AppUser?> getUserData(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return AppUser.fromFirestore(uid, data);
  }
}
