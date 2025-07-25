import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugService {
  static Future<void> debugUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }

      print('🔍 Debug des données utilisateur:');
      print('User ID: ${currentUser.uid}');
      print('Email: ${currentUser.email}');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        print('❌ Document utilisateur non trouvé dans Firestore');
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      print('📋 Données Firestore:');
      print('  - Email: ${userData['email']}');
      print('  - Prénom: ${userData['firstName']}');
      print('  - Nom: ${userData['lastName']}');
      print('  - Téléphone: ${userData['numTel']}');
      print('  - SIRET: ${userData['numSiret']}');
      print('  - Rôle: ${userData['role']}');

      // Vérifier si le rôle est correct
      String role = userData['role'] ?? 'lambda';
      print('🎯 Rôle détecté: $role');

      // Simuler la logique de redirection
      String expectedRoute = _getExpectedRoute(role);
      print('📍 Route attendue: $expectedRoute');

    } catch (e) {
      print('❌ Erreur lors du debug: $e');
    }
  }

  static String _getExpectedRoute(String role) {
    if (role == 'admin') {
      return '/admin_home';
    } else if (role == 'pro') {
      return '/pro_home';
    } else {
      return '/lambda_home';
    }
  }

  static Future<void> listAllUsers() async {
    try {
      print('📋 Liste de tous les utilisateurs:');
      
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        print('  - ${userData['email']} (${userData['role'] ?? 'lambda'})');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des utilisateurs: $e');
    }
  }
} 