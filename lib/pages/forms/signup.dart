import 'package:chicken_grills/pages/forms/login.dart';
import 'package:chicken_grills/pages/signup_success.dart';
import 'package:chicken_grills/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:chicken_grills/models/user_model.dart';
//import 'package:chicken_grills/pages/widgets/custom_dropdown.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _numSiret = TextEditingController();
  final TextEditingController _numTelController = TextEditingController();
  String? _selectedSpecialty;
  String _userType = 'lambda';  // 'lambda' ou 'pro'
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false; // Ajout d'une variable pour suivre l'état de chargement

  final AuthService _authService = AuthService();

  // Expression régulière pour vérifier un email valide
  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  // Expression régulière pour un mot de passe sécurisé
  final RegExp passwordRegex = RegExp(
    // r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{6,}$",
    r"^(?=.*[a-z])(?=.*\d)[a-zA-Z\d]{6,}$", // sans les majuscules
  );

  bool _validateFields() {
    setState(() {
      _errorMessage = null;
    });

    // Vérification des champs
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Email";
      });
      return false;
    } else if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = "Veuillez entrer une adresse email valide";
      });
      return false;
    } else if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Mot de passe";
      });
      return false;
    } else if (!passwordRegex.hasMatch(_passwordController.text)) {
      setState(() {
        _errorMessage = "Le mot de passe doit contenir au moins 6 caractères, une majuscule, une minuscule et un chiffre";
      });
      return false;
    } else if (_lastNameController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Nom";
      });
      return false;
    } else if (_firstNameController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Prénom";
      });
      return false;
    } else if (_numTelController.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Numéro de téléphone";
      });
      return false;
    }  else if (_userType == 'pro' && _numSiret.text.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir le champ Numéro de siret";
      });
      return false;
    }

    return true;
  }

  void _signup() async {
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
    });

    User newUser = User(
      email: _emailController.text,
      password: _passwordController.text,
      lastName: _lastNameController.text,
      firstName: _firstNameController.text,
      numSiret: _userType == 'pro' ? _numSiret.text : '',
      numTel: _numTelController.text,
      role: _userType == 'pro' ? 'pro' : 'lambda',
    );

    try {
      final result = await _authService.signup(newUser);

      if (result["success"]) {
        final String? userId = result["userId"];
        
        print("Résultat de signup: $result");
        
        if (userId != null) {
          try {
            // Création du profil public
            Map<String, dynamic> publicData = {
              'firstName': newUser.firstName,
              'lastName': newUser.lastName,
              'numTel': newUser.numTel,
              'description': newUser.description ?? '',
              'address': newUser.address ?? '',
              'email': newUser.email,
              'role': newUser.role,
            };
            
            // Ajouter le numéro SIRET uniquement pour les utilisateurs pro
            if (newUser.role == 'pro') {
              publicData['numSiret'] = newUser.numSiret;
            }
            
            await FirebaseFirestore.instance.collection('publicProfiles').doc(userId).set(publicData);
            print("Profil public créé avec succès pour l'utilisateur: $userId");
            
            setState(() {
              _isLoading = false; // Désactiver le loader
            });
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
            showModalBottomSheet(
              context: context,
              isDismissible: false,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SignupSuccessPage(),
            );
          } catch (e) {
            print("Erreur lors de la création du profil public: $e");
            setState(() {
              _isLoading = false; // Désactiver le loader
              _errorMessage = "Inscription réussie mais problème avec la création du profil.";
            });
          }
        } else {
          print("ERREUR: userId est null");
          setState(() {
            _isLoading = false; // Désactiver le loader
            _errorMessage = "Erreur: Impossible de récupérer l'identifiant utilisateur";
          });
        }
      } else {
        setState(() {
          _isLoading = false; // Désactiver le loader
          _errorMessage = result["message"];
        });
      }
    } catch (e) {
      print("ERREUR GLOBALE dans _signup: $e");
      setState(() {
        _isLoading = false; // Désactiver le loader
        _errorMessage = "Une erreur inattendue s'est produite: $e";
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FC),
      body: SafeArea(
        child: Stack(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 35),
                      color: Colors.white,
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Inscription",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF5829),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Créez votre compte",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: Color(0xFFF9B44E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildTextField("Email", _emailController, hintText: "example@example.com"),
                          _buildTextField("Mot de passe", _passwordController, hintText: "***************", isPassword: true),
                          _buildTextField("Nom", _lastNameController, hintText: "Doe"),
                          _buildTextField("Prénom", _firstNameController, hintText: "John"),
                          _buildTextField("Numéro de téléphone", _numTelController, hintText: "0262693457896"),

                          // Dropdown pour choisir le type d'utilisateur
                          DropdownButton<String>(
                            value: _userType,
                            onChanged: (String? newValue) {
                              setState(() {
                                _userType = newValue!;
                              });
                            },
                            items: <String>['lambda', 'pro']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'lambda' ? 'Utilisateur lambda' : 'Utilisateur professionnel'),
                              );
                            }).toList(),
                          ),

                          // Afficher l'input Siret seulement pour les professionnels
                          if (_userType == 'pro') 
                            _buildTextField("Numéro de siret", _numSiret, hintText: "784 671 695 00103"),

                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Center(
                            child: SizedBox(
                              width: 250,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup, // Désactiver le bouton pendant le chargement
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF5829),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Inscription",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: "Vous avez un compte ? ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Connectez-vous !",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFEF5829),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Afficher le loader au centre de l'écran quand _isLoading est true
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF5829)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.w500, 
          fontSize: 20,
          //fontFamily: 'ArchivoNarrow',
        )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Color(0xFFDDDDDD)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: _obscurePassword
                            ? Image.asset("assets/images/eye-slash.png")
                            : Image.asset("assets/images/eye.png"),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}