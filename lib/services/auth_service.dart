import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chicken_grills/services/firebase_error_translator.dart';
import 'package:chicken_grills/models/user_model.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inscription d'un utilisateur
  Future<Map<String, dynamic>> signup(User user) async {
    try {
      // Créer un utilisateur Firebase
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      
      // Récupération de l'ID utilisateur
      String userId = userCredential.user!.uid;
      


      if (user.numSiret.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Le numéro SIRET est obligatoire pour accéder à l’espace professionnel.',
        };
      }

      // Ajout des informations supplémentaires dans Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'numTel': user.numTel,
        'numSiret': user.numSiret,
        'profileImageData': null,
        'coverImageData': null,
        'role': 'pro',
      });

      return {
        'success': true, 
        'message': 'Inscription réussie!',
        'userId': userId, // Ajout de l'ID utilisateur dans la réponse
      };
    } catch (e) {
      return {
        'success': false,
        'message': FirebaseErrorTranslator.translateError(e.toString()),
      };
    }
  }

  // Connexion d'un utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Récupérer les informations de l'utilisateur depuis Firestore
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé dans la base de données',
        };
      }

      // Récupérer le rôle avec une valeur par défaut
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String role = userData['role'] ?? 'lambda';

      return {'success': true, 'message': 'Connexion réussie!', 'role': role};
    } catch (e) {
      return {
        'success': false,
        'message': FirebaseErrorTranslator.translateError(e.toString()),
      };
    }
  }

  // Réinitialisation du mot de passe
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message':
            'Un email de réinitialisation a été envoyé à votre adresse email.',
      };
    } catch (e) {
      return {'success': false, 'message': FirebaseErrorTranslator.translateError(e.toString())};
    }
  }
}
