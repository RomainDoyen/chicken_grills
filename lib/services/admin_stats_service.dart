import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère les vraies statistiques maintenant que les permissions sont correctes
  Future<Map<String, int>> getStatistics() async {
    try {
      // Vérifier que l'utilisateur est admin
      auth.User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Vérifier le rôle admin
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists || userDoc['role'] != 'admin') {
        throw Exception('Utilisateur non autorisé');
      }

      // Récupérer les vraies statistiques
      Map<String, int> stats = await _getRealStatistics();
      return stats;
    } catch (e) {
      print('Erreur dans AdminStatsService: $e');
      // Retourner des statistiques par défaut
      return {
        'totalUsers': 0,
        'totalMarkers': 0,
        'proUsers': 0,
        'lambdaUsers': 0,
      };
    }
  }

  /// Récupère les vraies statistiques depuis Firestore
  Future<Map<String, int>> _getRealStatistics() async {
    int totalUsers = 0;
    int totalMarkers = 0;
    int proUsers = 0;
    int lambdaUsers = 0;

    try {
      // Récupérer tous les utilisateurs
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'lambda';

        if (role == 'pro') {
          proUsers++;
        } else if (role == 'lambda') {
          lambdaUsers++;
        }
        // Les admins ne sont pas comptés dans les statistiques
      }

      totalUsers = proUsers + lambdaUsers;
    } catch (e) {
      print('Erreur lors de la récupération des utilisateurs: $e');
    }

    try {
      // Récupérer tous les marqueurs
      QuerySnapshot markersSnapshot =
          await _firestore.collection('markers').get();

      totalMarkers = markersSnapshot.docs.length;
    } catch (e) {
      print('Erreur lors de la récupération des marqueurs: $e');
    }

    return {
      'totalUsers': totalUsers,
      'totalMarkers': totalMarkers,
      'proUsers': proUsers,
      'lambdaUsers': lambdaUsers,
    };
  }

  /// Méthode de fallback pour les statistiques simulées
  Future<Map<String, int>> getSimulatedStats() async {
    // Simuler des statistiques basées sur des données réelles si possible
    int totalUsers = 3;
    int totalMarkers = 2;
    int proUsers = 1;
    int lambdaUsers = 2;

    // Essayer de récupérer au moins quelques vraies données
    try {
      // Compter les marqueurs de l'utilisateur actuel
      auth.User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot userMarkers =
            await _firestore
                .collection('markers')
                .where('userId', isEqualTo: currentUser.uid)
                .get();

        if (userMarkers.docs.isNotEmpty) {
          totalMarkers = userMarkers.docs.length;
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des marqueurs utilisateur: $e');
    }

    return {
      'totalUsers': totalUsers,
      'totalMarkers': totalMarkers,
      'proUsers': proUsers,
      'lambdaUsers': lambdaUsers,
    };
  }
}
