import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFixService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Corrige le rôle d'un utilisateur spécifique
  Future<void> fixUserRole(String email, String correctRole) async {
    try {
      print('🔧 Correction du rôle pour $email vers $correctRole');

      // Trouver l'utilisateur par email
      QuerySnapshot userQuery =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

      if (userQuery.docs.isEmpty) {
        print('❌ Utilisateur $email non trouvé');
        return;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;
      String userId = userDoc.id;

      // Mettre à jour le rôle
      await _firestore.collection('users').doc(userId).update({
        'role': correctRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rôle corrigé pour $email: $correctRole');
    } catch (e) {
      print('❌ Erreur lors de la correction du rôle: $e');
    }
  }

  /// Supprime tous les comptes admin en double
  Future<void> removeDuplicateAdmins() async {
    try {
      print('🧹 Suppression des admins en double...');

      QuerySnapshot adminQuery =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      List<DocumentSnapshot> admins = adminQuery.docs;

      if (admins.length <= 1) {
        print('✅ Aucun admin en double trouvé');
        return;
      }

      // Garder seulement le premier admin (le plus ancien)
      for (int i = 1; i < admins.length; i++) {
        DocumentSnapshot adminDoc = admins[i];
        Map<String, dynamic> adminData =
            adminDoc.data() as Map<String, dynamic>;

        print('🗑️ Suppression de l\'admin en double: ${adminData['email']}');
        await adminDoc.reference.delete();
      }

      print('✅ Admins en double supprimés');
    } catch (e) {
      print('❌ Erreur lors de la suppression des admins en double: $e');
    }
  }

  /// Liste tous les utilisateurs avec leurs rôles
  Future<void> listAllUsersWithRoles() async {
    try {
      print('📋 Liste de tous les utilisateurs:');

      QuerySnapshot usersQuery =
          await _firestore
              .collection('users')
              .orderBy('createdAt', descending: true)
              .get();

      for (var doc in usersQuery.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String email = userData['email'] ?? 'N/A';
        String role = userData['role'] ?? 'lambda';
        String firstName = userData['firstName'] ?? 'N/A';
        String lastName = userData['lastName'] ?? 'N/A';

        print('  - $email ($firstName $lastName) - Rôle: $role');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  /// Corrige automatiquement les rôles basés sur la présence de SIRET
  Future<void> autoFixRoles() async {
    try {
      print('🔧 Correction automatique des rôles...');

      QuerySnapshot usersQuery = await _firestore.collection('users').get();

      int corrected = 0;

      for (var doc in usersQuery.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String email = userData['email'] ?? '';
        String currentRole = userData['role'] ?? 'lambda';
        String siret = userData['numSiret'] ?? '';

        // Déterminer le rôle correct
        String correctRole = 'lambda';
        if (email == 'admin@chicken-grills.com') {
          correctRole = 'admin';
        } else if (siret.isNotEmpty && siret != 'ADMIN123456789') {
          correctRole = 'pro';
        }

        // Corriger si nécessaire
        if (currentRole != correctRole) {
          print('🔄 Correction: $email ($currentRole → $correctRole)');
          await doc.reference.update({
            'role': correctRole,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          corrected++;
        }
      }

      print('✅ $corrected rôles corrigés');
    } catch (e) {
      print('❌ Erreur lors de la correction automatique: $e');
    }
  }

  /// Nettoie complètement la base de données (ATTENTION: destructif)
  Future<void> cleanDatabase() async {
    try {
      print('⚠️ ATTENTION: Nettoyage de la base de données...');

      // Supprimer tous les utilisateurs sauf admin@chicken-grills.com
      QuerySnapshot usersQuery = await _firestore.collection('users').get();

      for (var doc in usersQuery.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String email = userData['email'] ?? '';

        if (email != 'admin@chicken-grills.com') {
          print('🗑️ Suppression: $email');
          await doc.reference.delete();
        }
      }

      print('✅ Base de données nettoyée');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }
}
