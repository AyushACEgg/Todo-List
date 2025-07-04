import 'package:firebase_auth/firebase_auth.dart';

class UserDetails {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  UserDetails({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  factory UserDetails.fromUser(User user) {
    return UserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }
}
