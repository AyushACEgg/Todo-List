import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flow/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final UserDetails? userDetails;

  const AuthAuthenticated(this.user, {this.userDetails});

  factory AuthAuthenticated.withPigeonDetails(User user) {
    return AuthAuthenticated(
      user,
      userDetails: UserDetails.fromUser(user),
    );
  }

  @override
  List<Object?> get props => [user.uid, userDetails];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
