import 'package:chicken_grills/pages/forms/login.dart';
import 'package:chicken_grills/pages/forms/signup.dart';
import 'package:chicken_grills/pages/home/lambda_home_page.dart';
import 'package:chicken_grills/pages/home/pro_home_page.dart';
import 'package:chicken_grills/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verrouillage de l'orientation en mode portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  //final SessionManager _sessionManager = SessionManager();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /*if (navigatorKey.currentContext != null) {
      _sessionManager.onAppStateChanged(state, navigatorKey.currentContext!);
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        dialogBackgroundColor: const Color(0xFFF9D3C0),
        primarySwatch: Colors.blue,
        iconTheme: const IconThemeData(color: Color(0xFFF9D3C0)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MySplashScreen(), // SplashScreen
        '/login': (context) => const LoginPage(), // Page de connexion
        '/signup': (context) => const SignupPage(), // Page d'inscription
        '/lambda_home': (context) => const LambdaHomePage(), // Page pour les utilisateurs lambda
        '/pro_home': (context) => const ProHomePage(),
      },
    );
  }
}