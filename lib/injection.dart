import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_routes/blocs/auth_bloc/auth_bloc.dart';
import 'package:smart_routes/blocs/comments_bloc/comments_bloc.dart';
import 'package:smart_routes/blocs/route_bloc/route_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  final firebaseAuth = FirebaseAuth.instance;
  final firebaseFirestore = FirebaseFirestore.instance;
  final sharedPreferences = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerSingleton<FirebaseAuth>(firebaseAuth);
  getIt.registerSingleton<FirebaseFirestore>(firebaseFirestore);

  getIt.registerFactory<RouteBloc>(() => RouteBloc(
        getIt<FirebaseFirestore>(),
        getIt<FirebaseAuth>(),
      ));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(firebaseAuth));
  getIt.registerFactory<CommentsBloc>(() => CommentsBloc(
        getIt<SharedPreferences>(),
        getIt<FirebaseFirestore>(),
        getIt<FirebaseAuth>(),
      ));
}
