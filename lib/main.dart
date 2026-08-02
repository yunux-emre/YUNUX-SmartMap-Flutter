import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_routes/app_logo.dart';
import 'package:smart_routes/blocs/auth_bloc/auth_bloc.dart';
import 'package:smart_routes/blocs/comments_bloc/comments_bloc.dart';
import 'package:smart_routes/blocs/route_bloc/route_bloc.dart';
import 'package:smart_routes/colors.dart';
import 'package:smart_routes/firebase_options.dart';
import 'package:smart_routes/home_page.dart';
import 'package:smart_routes/injection.dart';
import 'package:smart_routes/login_page.dart';
import 'package:smart_routes/restartable_widget.dart';

void main() {
  runZonedGuarded(
    () async {
      final binding = WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      for (final renderView in binding.renderViews) {
        renderView.automaticSystemUiAdjustment = false;
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await setupInjection();
      runApp(const RestartableApp(child: MyApp()));
    },
    (error, stack) {},
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<AuthBloc>()),
        BlocProvider(
          lazy: false,
          create: (context) => getIt<CommentsBloc>()..add(CommentsLoad()),
        ),
        BlocProvider(
          lazy: false,
          create: (context) => getIt<RouteBloc>()..add(RouteInitial()),
        ),
      ],
      child: MaterialApp(
        title: 'Yunux RouteMap',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: appBackgroundColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: appPrimaryColor,
            brightness: Brightness.dark,
            primary: appPrimaryColor,
            secondary: appAccentColor,
            surface: appCardBackgroundColor,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: appPrimaryColor,
            brightness: Brightness.dark,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: appPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: "/",
        routes: {
          '/': (context) => const SplashPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/root') {
            return MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const RootPage(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    context.read<AuthBloc>().add(AuthInit());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        Future.delayed(const Duration(seconds: 2), () {
          if (state.isGuest) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/root',
              (route) => false,
            );
            return;
          }
          state.userOrFailure.fold(() => null, (a) {
            a.fold((l) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) {
                return const LoginPage();
              }));
            }, (r) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/root',
                (route) => false,
              );
            });
          });
        });
      },
      child: const Scaffold(
        backgroundColor: appBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 220),
              SizedBox(height: 24),
              Text(
                "Yunux RouteMap",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Akıllı Sürücü & Canlı Rota Asistanı",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.isGuest) {
          return const HomePage();
        }
        return state.userOrFailure.fold(
          () {
            return const Scaffold(
              backgroundColor: appPrimaryColor,
              body: Center(
                child: AppLogo(),
              ),
            );
          },
          (a) => a.fold(
            (l) {
              return const LoginPage();
            },
            (r) {
              return const HomePage();
            },
          ),
        );
      },
    );
  }
}
