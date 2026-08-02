part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.userOrFailure,
    this.isGuest = false,
  });
  final Option<Either<String, User?>> userOrFailure;
  final bool isGuest;

  factory AuthState.initial() => AuthState(
        userOrFailure: none(),
        isGuest: false,
      );

  AuthState copyWith({
    Option<Either<String, User?>>? userOrFailure,
    bool? isGuest,
  }) {
    return AuthState(
      userOrFailure: userOrFailure ?? this.userOrFailure,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [
        userOrFailure,
        isGuest,
      ];
}
