import 'package:chicken_grills/services/auth_service.dart';
import 'package:chicken_grills/services/firebase_error_translator.dart';
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
      print('Redirection vers le rôle: $role'); // Debug

      if (role == 'admin') {
        print('Redirection vers admin_home');
        Navigator.pushReplacementNamed(context, '/admin_home');
      } else if (role == 'pro') {
        print('Redirection vers pro_home');
        Navigator.pushReplacementNamed(context, '/pro_home');
      } else {
        print('Redirection vers lambda_home (rôle: $role)');
        Navigator.pushReplacementNamed(context, '/lambda_home');
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
            decoration: const BoxDecoration(color: Color(0xFFF9D3C0)),
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
                              Center(
                                child: Image.asset(
                                  'assets/images/icon.png',
                                  width: 150,
                                ),
                              ),
                              //const SizedBox(height: 10),
                              const Text(
                                "Bienvenue, connectez-vous pour commencer",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFEF5829),
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Champ Email
                              Align(
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  "Email",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                    color: Color(0xFFEF5829),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: "example@example.com",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFDDDDDD),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Champ Mot de passe
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Mot de passe",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                    color: Color(0xFFEF5829),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "************",
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFDDDDDD),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
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
                                  child: const Text(
                                    "Mot de passe oublié ?",
                                    style: TextStyle(
                                      color: Color(0xFFEF5829),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),

                              // Affichage des erreurs
                              if (_errorMessage != null &&
                                  _errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 160, 46, 12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                            SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : _login, // Désactiver le bouton pendant le chargement
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF9B44E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Connexion",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () {
                                          Navigator.pushNamed(
                                            context,
                                            '/signup',
                                          );
                                        }, // Désactiver le bouton pendant le chargement
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Inscription",
                                  style: TextStyle(
                                    fontSize: 23,
                                    color: Color(0xFFEF5829),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFEF5829),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
