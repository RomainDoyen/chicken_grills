import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chicken_grills/models/user_model.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inscription d'un utilisateur
  Future<Map<String, dynamic>> signup(User user) async {
    try {
      // Créer un utilisateur Firebase
      auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      
      // Récupération de l'ID utilisateur
      String userId = userCredential.user!.uid;
      
      print("Utilisateur créé avec ID: $userId");

      // Ajout des informations supplémentaires dans Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'numTel': user.numTel,
        'numSiret': user.numSiret,
        'role': user.numSiret.isEmpty ? 'lambda' : 'pro',  // Identifie le type d'utilisateur
      });

      return {
        'success': true, 
        'message': 'Inscription réussie!',
        'userId': userId  // Ajout de l'ID utilisateur dans la réponse
      };
    } catch (e) {
      print("Erreur dans signup: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Connexion d'un utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupérer les informations de l'utilisateur depuis Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      String role = userDoc['role'];

      return {'success': true, 'message': 'Connexion réussie!', 'role': role};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}