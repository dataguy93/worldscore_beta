import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
    required this.role,
    this.clubName,
    this.association,
    this.photoUrl,
    this.bio,
  });

  final String uid;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final Timestamp? createdAt;
  final String role;
  final String? clubName;
  final String? association;
  final String? photoUrl;
  final String? bio;

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? username : combined;
  }

  factory AppUser.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final legacyDisplayName = (data['displayName'] as String?) ?? '';
    return AppUser(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      username: (data['username'] as String?) ?? legacyDisplayName,
      firstName: (data['firstName'] as String?) ?? '',
      lastName: (data['lastName'] as String?) ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      role: (data['role'] as String?) ?? 'player',
      clubName: data['clubName'] as String?,
      association: data['association'] as String?,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt,
      'role': role,
      'clubName': clubName,
      'association': association,
      'photoUrl': photoUrl,
      'bio': bio,
    };
  }
}
