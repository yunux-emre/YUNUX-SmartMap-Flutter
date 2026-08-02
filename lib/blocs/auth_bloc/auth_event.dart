part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInit extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthLogin(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;

  const AuthRegister(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthGuestLogin extends AuthEvent {}

class AuthLogout extends AuthEvent {}
