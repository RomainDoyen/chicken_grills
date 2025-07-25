import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSeeder {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Informations du compte admin par défaut
  static const String adminEmail = 'admin@chicken-grills.com';
  static const String adminPassword = 'Admin123!';
  static const String adminFirstName = 'Admin';
  static const String adminLastName = 'ChickenGrills';
  static const String adminPhone = '0123456789';
  static const String adminSiret = 'ADMIN123456789';

  /// Vérifie si le compte admin spécifique existe déjà
  Future<bool> _adminExists() async {
    try {
      // Vérifier si l'email admin existe déjà
      QuerySnapshot adminQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: adminEmail)
              .limit(1)
              .get();

      if (adminQuery.docs.isNotEmpty) {
        print('Compte admin avec email $adminEmail existe déjà');
        return true;
      }

      // Vérifier s'il y a déjà un admin (pour éviter les doublons)
      QuerySnapshot adminRoleQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .limit(1)
              .get();

      if (adminRoleQuery.docs.isNotEmpty) {
        print('Un compte admin existe déjà (rôle admin)');
        return true;
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification de l\'admin: $e');
      return false;
    }
  }

  /// Crée le compte admin par défaut
  Future<void> createAdminIfNotExists() async {
    try {
      // Vérifier si un admin existe déjà
      bool adminExists = await _adminExists();

      if (adminExists) {
        print('Un compte admin existe déjà');
        return;
      }

      print('Création du compte admin...');

      // Créer l'utilisateur Firebase Auth
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

      String userId = userCredential.user!.uid;
      print('Utilisateur admin créé avec ID: $userId');

      // Ajouter les informations dans Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': adminEmail,
        'firstName': adminFirstName,
        'lastName': adminLastName,
        'numTel': adminPhone,
        'numSiret': adminSiret,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': true,
      });

      // Créer un profil public pour l'admin (optionnel)
      await _firestore.collection('publicProfiles').doc(userId).set({
        'firstName': adminFirstName,
        'lastName': adminLastName,
        'numTel': adminPhone,
        'description': 'Administrateur de Chicken Grills',
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Compte admin créé avec succès !');
      print('📧 Email: $adminEmail');
      print('🔑 Mot de passe: $adminPassword');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠️ Le compte admin existe déjà dans Firebase Auth');
        // Essayer de mettre à jour le rôle dans Firestore
        await _updateExistingUserToAdmin();
      } else {
        print('❌ Erreur lors de la création du compte admin: $e');
      }
    }
  }

  /// Met à jour un utilisateur existant en admin
  Future<void> _updateExistingUserToAdmin() async {
    try {
      // Récupérer l'utilisateur par email
      auth.User? user = _auth.currentUser;
      if (user == null) {
        // Essayer de se connecter avec les credentials admin
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        user = _auth.currentUser;
      }

      if (user != null) {
        // Mettre à jour le rôle dans Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': adminEmail,
          'firstName': adminFirstName,
          'lastName': adminLastName,
          'numTel': adminPhone,
          'numSiret': adminSiret,
          'role': 'admin',
          'isAdmin': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Utilisateur existant mis à jour en admin');
      }
    } catch (e) {
      print('❌ Erreur lors de la mise à jour en admin: $e');
    }
  }

  /// Supprime le compte admin (pour les tests)
  Future<void> deleteAdmin() async {
    try {
      QuerySnapshot adminQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      for (var doc in adminQuery.docs) {
        await doc.reference.delete();
        print('Compte admin supprimé: ${doc.id}');
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'admin: $e');
    }
  }
}
