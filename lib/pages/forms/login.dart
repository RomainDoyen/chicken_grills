import 'package:chicken_grills/services/auth_service.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false; // Nouvel état pour gérer le chargement
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage = "";

  final AuthService _authService = AuthService();

  // Expression régulière pour vérifier un email valide
  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  // Expression régulière pour un mot de passe sécurisé
  final RegExp passwordRegex = RegExp(
    r"^(?=.*[a-z])(?=.*\d).{6,}$",
  ); // 6 caractères min, 1 lettre minuscule et 1 chiffre

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true; // Activer le chargement
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Email";
        _isLoading = false; // Désactiver le chargement
      });
      return;
    } else if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = "Veuillez entrer une adresse email valide";
        _isLoading = false;
      });
      return;
    } else if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Mot de passe";
        _isLoading = false;
      });
      return;
    } else if (!passwordRegex.hasMatch(_passwordController.text)) {
      setState(() {
        _errorMessage =
            "Le mot de passe doit contenir au moins 6 caractères, une lettre minuscule ou majuscule et un chiffre";
        _isLoading = false;
      });
      return;
    }

    final result = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false; // Désactiver le chargement après la connexion
    });

    if (result["success"]) {
      // Naviguer selon le rôle de l'utilisateur
      String role = result["role"];

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_home');
      } else if (role == 'pro') {
        Navigator.pushReplacementNamed(context, '/pro_home');
      } else {
        await firebase_auth.FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage =
              "Cet espace est réservé aux professionnels référencés. Contactez l'équipe Chicken Grills pour obtenir un accès.";
        });
      }
    } else {
      setState(() {
        _errorMessage = result["message"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: AppTheme.backgroundPeach),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(child: AppTheme.logoWidget()),
                              AppTheme.welcomeText(),
                              const SizedBox(height: 30),

                              // Champ Email
                              AppTheme.sectionTitle("Email"),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                decoration: AppTheme.textFieldDecoration(
                                  hintText: "example@example.com",
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Champ Mot de passe
                              AppTheme.sectionTitle("Mot de passe"),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: AppTheme.textFieldDecoration(
                                  hintText: "************",
                                  suffixIcon: IconButton(
                                    icon:
                                        _obscurePassword
                                            ? Image.asset(
                                              "assets/images/eye-slash.png",
                                            )
                                            : Image.asset(
                                              "assets/images/eye.png",
                                            ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              // Lien "Mot de passe oublié"
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forgot_password',
                                    );
                                  },
                                  child: Text(
                                    "Mot de passe oublié ?",
                                    style: AppTheme.linkStyle,
                                  ),
                                ),
                              ),

                              // Affichage des erreurs
                              if (_errorMessage != null &&
                                  _errorMessage!.isNotEmpty)
                                AppTheme.errorText(_errorMessage!),
                            ],
                          ),
                        ),
                      ),

                      // Boutons Connexion et Inscription
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          children: [
                            AppTheme.primaryButton(
                              text: "Connexion",
                              onPressed: _login,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 16),
                            AppTheme.secondaryButton(
                              text: "Inscription",
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryOrange),
                onPressed: _handleBackNavigation,
                tooltip: 'Retour',
              ),
            ),
          ),
          // Indicateur de chargement
          if (_isLoading) AppTheme.loadingOverlay(),
        ],
      ),
    );
  }
}
