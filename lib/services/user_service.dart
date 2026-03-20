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
    String displayName = '',
    String preferredRole = 'player',
  }) async {
    await _usersCollection.doc(uid).set(
      {
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'preferredRole': preferredRole,
        'preferences': <String, dynamic>{},
      },
      SetOptions(merge: true),
    );
  }

  Future<AppUser?> getUserData(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AppUser.fromFirestore(uid, snapshot.data()!);
  }
}
