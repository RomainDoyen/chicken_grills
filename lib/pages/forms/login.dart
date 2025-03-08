import 'package:chicken_grills/services/auth_service.dart';
import 'package:flutter/material.dart';
//import 'package:chicken_grills/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  double _logoPosition = 0.0;
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
    // r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{6,}$", // avec les majuscules
    r"^(?=.*[a-z])(?=.*\d)[a-zA-Z\d]{6,}$", // sans les majuscules
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _logoPosition = -20.0;
      });
    });
  }

  void _login() async {
    setState(() {
      _errorMessage = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Email";
      });
      return;
    } else if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = "Veuillez entrer une adresse email valide";
      });
      return;
    } else if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Mot de passe";
      });
      return;
    } else if (!passwordRegex.hasMatch(_passwordController.text)) {
      setState(() {
        _errorMessage = "Le mot de passe doit contenir au moins 6 caractères, une majuscule, une minuscule et un chiffre";
      });
      return;
    }

    final result = await _authService.login(_emailController.text, _passwordController.text);

  if (result["success"]) {
    // Naviguer en fonction du rôle
    String role = result["role"];
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_home');
    } else if (role == 'pro') {
      Navigator.pushReplacementNamed(context, '/pro_home');
    } else {
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
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9D3C0),
        ),
        child: SizedBox.expand(
          child:
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
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
                              icon: _obscurePassword
                                  ? Image.asset("assets/images/eye-slash.png")
                                  : Image.asset("assets/images/eye.png"),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
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
                        if (_errorMessage != null && _errorMessage!.isNotEmpty)
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    children: [
                      Container(
                        width: 250,
                        height: 50,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9B44E),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
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
                      Container(
                        width: 250,
                        height: 50,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
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
    );
  }
}