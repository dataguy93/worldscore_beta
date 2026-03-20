import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.preferredRole,
    required this.preferences,
  });

  final String uid;
  final String email;
  final String displayName;
  final DateTime? createdAt;
  final String preferredRole;
  final Map<String, dynamic> preferences;

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    final createdAtTimestamp = data['createdAt'];

    return AppUser(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      createdAt: createdAtTimestamp is Timestamp ? createdAtTimestamp.toDate() : null,
      preferredRole: (data['preferredRole'] as String?) ?? 'player',
      preferences: (data['preferences'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
      'preferredRole': preferredRole,
      'preferences': preferences,
    };
  }
}
