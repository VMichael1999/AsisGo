import 'package:equatable/equatable.dart';
import '../../domain/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  User? get currentUser => null;

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  User? get currentUser => user;

  @override
  List<Object?> get props => [user];
}

class AuthSessionExpired extends AuthState {
  final User user;
  final String message;

  const AuthSessionExpired({
    required this.user,
    this.message = 'El inicio de sesión ha expirado, vuelve a iniciar sesión nuevamente.',
  });

  @override
  User? get currentUser => user;

  @override
  List<Object?> get props => [user, message];
}

class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated([this.message]);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
