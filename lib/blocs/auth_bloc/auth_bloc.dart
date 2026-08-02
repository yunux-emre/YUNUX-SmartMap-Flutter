import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  AuthBloc(
    this._firebaseAuth,
  ) : super(AuthState.initial()) {
    on<AuthInit>((event, emit) async {
      emit(state.copyWith(userOrFailure: none()));
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        emit(state.copyWith(userOrFailure: some(right(user))));
      } else {
        emit(state.copyWith(
            userOrFailure: some(left("Lütfen giriş yapınız."))));
      }
    });

    on<AuthLogin>((event, emit) async {
      emit(state.copyWith(userOrFailure: none()));

      final email = event.email.trim();
      final password = event.password.trim();

      if (email.isEmpty || password.length < 6) {
        emit(state.copyWith(
          userOrFailure: some(left(
              'E-posta boş olamaz ve şifre en az 6 karakter olmalıdır.')),
        ));
        return;
      }

      try {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        emit(state.copyWith(
          userOrFailure: some(right(userCredential.user!)),
          isGuest: false,
        ));
      } on FirebaseAuthException catch (e) {
        debugPrint('AuthLogin FirebaseAuthException: ${e.code} - ${e.message}');
        String message = 'Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.';
        if (e.code == 'user-not-found') {
          message = 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          message = 'Hatalı şifre veya e-posta adresi.';
        } else if (e.code == 'invalid-email') {
          message = 'Geçersiz e-posta formatı.';
        } else if (e.code == 'user-disabled') {
          message = 'Bu kullanıcı hesabı engellenmiştir.';
        }
        emit(state.copyWith(userOrFailure: some(left(message))));
      } catch (e) {
        debugPrint('AuthLogin error: $e');
        emit(state.copyWith(
          userOrFailure:
              some(left('Giriş yapılırken bir hata oluştu: ${e.toString()}')),
        ));
      }
    });

    on<AuthRegister>((event, emit) async {
      emit(state.copyWith(userOrFailure: none()));

      final email = event.email.trim();
      final password = event.password.trim();

      if (email.isEmpty || password.length < 6) {
        emit(state.copyWith(
          userOrFailure: some(left(
              'E-posta boş olamaz ve şifre en az 6 karakter olmalıdır.')),
        ));
        return;
      }

      try {
        final userCredential =
            await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        emit(state.copyWith(
          userOrFailure: some(right(userCredential.user!)),
          isGuest: false,
        ));
      } on FirebaseAuthException catch (e) {
        debugPrint(
            'AuthRegister FirebaseAuthException: ${e.code} - ${e.message}');
        String message = 'Kayıt başarısız. Lütfen tekrar deneyiniz.';
        if (e.code == 'email-already-in-use') {
          message = 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.code == 'weak-password') {
          message = 'Şifre çok zayıf. Daha güçlü bir şifre seçiniz.';
        } else if (e.code == 'invalid-email') {
          message = 'Geçersiz e-posta formatı.';
        }
        emit(state.copyWith(userOrFailure: some(left(message))));
      } catch (e) {
        debugPrint('AuthRegister error: $e');
        emit(state.copyWith(
          userOrFailure:
              some(left('Kayıt oluşturulurken hata oluştu: ${e.toString()}')),
        ));
      }
    });

    on<AuthGuestLogin>((event, emit) async {
      emit(state.copyWith(userOrFailure: none()));
      try {
        final userCredential = await _firebaseAuth.signInAnonymously();
        emit(state.copyWith(
          userOrFailure: some(right(userCredential.user)),
          isGuest: true,
        ));
      } catch (e) {
        debugPrint(
            'AuthGuestLogin anonymous sign-in exception, proceeding in guest mode: $e');
        emit(state.copyWith(
          userOrFailure: some(right(null)),
          isGuest: true,
        ));
      }
    });

    on<AuthLogout>((event, emit) async {
      emit(state.copyWith(userOrFailure: none()));
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
      emit(state.copyWith(
        userOrFailure: some(left('Oturum kapatıldı.')),
        isGuest: false,
      ));
    });
  }
}
