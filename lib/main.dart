import 'package:chicken_grills/pages/admin/marker_management_page.dart';
import 'package:chicken_grills/pages/admin/settings_page.dart';
import 'package:chicken_grills/pages/admin/user_management_page.dart';
import 'package:chicken_grills/pages/forms/forgot_password.dart';
import 'package:chicken_grills/pages/forms/login.dart';
import 'package:chicken_grills/pages/forms/signup.dart';
import 'package:chicken_grills/pages/home/admin_home_page.dart';
import 'package:chicken_grills/pages/home/pro_home_page.dart';
import 'package:chicken_grills/pages/navigation/main_navigation.dart';
import 'package:chicken_grills/splash_screen.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verrouillage de l'orientation en mode portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MySplashScreen(), // SplashScreen
        '/main': (context) => const MainNavigation(),
        '/login': (context) => const LoginPage(), // Page de connexion
        '/signup': (context) => const SignupPage(), // Page d'inscription
        '/forgot_password':
            (context) =>
                const ForgotPasswordPage(), // Page de mot de passe oublié
        '/pro_home': (context) => const ProHomePage(),
        '/admin_home':
            (context) => const AdminHomePage(), // Page d'administration
        '/admin_users':
            (context) => UserManagementPage(), // Gestion utilisateurs
        '/admin_markers':
            (context) => MarkerManagementPage(), // Gestion marqueurs
        '/admin_settings': (context) => SettingsPage(), // Paramètres admin
      },
    );
  }
}
