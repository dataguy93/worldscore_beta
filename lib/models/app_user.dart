import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.role,
    this.photoUrl,
    this.bio,
  });

  final String uid;
  final String email;
  final String displayName;
  final Timestamp? createdAt;
  final String role;
  final String? photoUrl;
  final String? bio;

  factory AppUser.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return AppUser(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      role: (data['role'] as String?) ?? 'player',
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt,
      'role': role,
      'photoUrl': photoUrl,
      'bio': bio,
    };
  }
}
