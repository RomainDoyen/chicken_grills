import 'package:chicken_grills/services/auth_service.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage = "";
  String? _successMessage = "";

  final AuthService _authService = AuthService();

  // Expression régulière pour vérifier un email valide
  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  void _resetPassword() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Email";
        _isLoading = false;
      });
      return;
    } else if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = "Veuillez entrer une adresse email valide";
        _isLoading = false;
      });
      return;
    }

    final result = await _authService.resetPassword(_emailController.text);

    setState(() {
      _isLoading = false;
    });

    if (result["success"]) {
      setState(() {
        _successMessage = result["message"];
      });
    } else {
      setState(() {
        _errorMessage = result["message"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9D3C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEF5829)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mot de passe oublié",
          style: TextStyle(
            color: Color(0xFFEF5829),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Color(0xFFF9D3C0)),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      AppBar().preferredSize.height,
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
                                  width: 120,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Réinitialisation du mot de passe",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF5829),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Entrez votre adresse email pour recevoir un lien de réinitialisation",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Champ Email
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
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

                              const SizedBox(height: 24),

                              // Affichage des messages d'erreur
                              if (_errorMessage != null &&
                                  _errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFEF5350),
                                      ),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                              // Affichage des messages de succès
                              if (_successMessage != null &&
                                  _successMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF4CAF50),
                                      ),
                                    ),
                                    child: Text(
                                      _successMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Bouton de réinitialisation
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
                                onPressed: _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF9B44E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Envoyer le lien",
                                  style: TextStyle(
                                    fontSize: 20,
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
                                          Navigator.pop(context);
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Retour à la connexion",
                                  style: TextStyle(
                                    fontSize: 18,
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
