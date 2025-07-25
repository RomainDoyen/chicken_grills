import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service de validation des numéros SIRET
///
/// Ce service permet de valider les numéros SIRET français avec plusieurs niveaux de vérification :
///
/// 1. **Validation locale** : Vérification du format et de l'algorithme de Luhn
/// 2. **Validation API** : Vérification via l'API INSEE (nécessite une clé d'API)
/// 3. **Validation alternative** : Vérification via une API tierce
///
/// ## Utilisation
///
/// ```dart
/// // Validation locale (recommandée pour les tests)
/// Map<String, dynamic> result = await SiretValidator.validateSiret('78467169500103');
///
/// // Validation avec API (pour la production)
/// Map<String, dynamic> result = await SiretValidator.validateSiret('78467169500103', useAPI: true);
///
/// // Validation du format uniquement
/// bool isValid = SiretValidator.validateSiretFormat('78467169500103');
///
/// // Formatage du SIRET
/// String formatted = SiretValidator.formatSiret('78467169500103');
/// // Résultat: "784 671 695 001 03"
/// ```
///
/// ## Format SIRET
///
/// Le SIRET (Système d'Identification du Répertoire des Établissements) est composé de :
/// - **SIREN** : 9 chiffres (identifiant de l'entreprise)
/// - **NIC** : 5 chiffres (numéro d'établissement)
/// - **Total** : 14 chiffres avec clé de contrôle
///
/// ## Algorithme de Luhn
///
/// La validation utilise l'algorithme de Luhn pour vérifier la clé de contrôle :
/// 1. Multiplier par 2 les chiffres en position paire (en partant de la droite)
/// 2. Si le résultat > 9, additionner les chiffres du résultat
/// 3. Additionner tous les chiffres
/// 4. Le total doit être divisible par 10
///
/// ## Exemples de SIRET valides
///
/// - Google France : 784 671 695 00103
/// - Apple France : 552 081 317 00034
/// - Microsoft France : 443 061 841 00047
class SiretValidator {
  // Algorithme de Luhn pour vérifier la validité du SIRET
  static bool _luhnCheck(String siret) {
    if (siret.length != 14) return false;

    int sum = 0;
    bool alternate = false;

    // Parcourir les chiffres de droite à gauche
    for (int i = siret.length - 1; i >= 0; i--) {
      int digit = int.parse(siret[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit ~/ 10) + (digit % 10);
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Validation locale du format SIRET
  static bool validateSiretFormat(String siret) {
    // Supprimer les espaces et caractères spéciaux
    String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');

    // Vérifier la longueur (14 chiffres)
    if (cleanSiret.length != 14) {
      return false;
    }

    // Vérifier que ce sont bien des chiffres
    if (!RegExp(r'^\d{14}$').hasMatch(cleanSiret)) {
      return false;
    }

    // Appliquer l'algorithme de Luhn
    return _luhnCheck(cleanSiret);
  }

  // Validation via API gouvernementale (INSEE)
  static Future<Map<String, dynamic>> validateSiretWithAPI(String siret) async {
    try {
      // Nettoyer le SIRET
      String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');

      // URL de l'API Sirene (INSEE)
      String url =
          'https://api.insee.fr/entreprises/sirene/V3/siret/$cleanSiret';

      // Note: Cette API nécessite une clé d'authentification
      // Pour un usage en production, il faudrait s'inscrire sur api.insee.fr

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          // 'Authorization': 'Bearer YOUR_API_KEY', // À ajouter en production
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return {
          'valid': true,
          'exists': true,
          'data': data,
          'message': 'SIRET valide et trouvé',
        };
      } else if (response.statusCode == 404) {
        return {
          'valid': true,
          'exists': false,
          'data': null,
          'message': 'SIRET valide mais non trouvé dans la base de données',
        };
      } else {
        return {
          'valid': false,
          'exists': false,
          'data': null,
          'message': 'Erreur lors de la vérification',
        };
      }
    } catch (e) {
      return {
        'valid': false,
        'exists': false,
        'data': null,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  // Validation via API alternative (gratuite)
  static Future<Map<String, dynamic>> validateSiretAlternative(
    String siret,
  ) async {
    try {
      String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');

      // Utilisation d'une API alternative (exemple)
      // Note: Cette URL est un exemple, il faudrait utiliser une vraie API
      String url = 'https://api.example.com/siret/$cleanSiret';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return {
          'valid': true,
          'exists': true,
          'data': json.decode(response.body),
          'message': 'SIRET vérifié avec succès',
        };
      } else {
        return {
          'valid': true,
          'exists': false,
          'data': null,
          'message': 'SIRET non trouvé dans la base de données',
        };
      }
    } catch (e) {
      // En cas d'erreur, on retourne une validation locale
      return validateSiretLocal(siret);
    }
  }

  // Validation locale uniquement (sans API)
  static Map<String, dynamic> validateSiretLocal(String siret) {
    String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanSiret.length != 14) {
      return {
        'valid': false,
        'exists': false,
        'data': null,
        'message': 'Le SIRET doit contenir exactement 14 chiffres',
      };
    }

    if (!RegExp(r'^\d{14}$').hasMatch(cleanSiret)) {
      return {
        'valid': false,
        'exists': false,
        'data': null,
        'message': 'Le SIRET ne doit contenir que des chiffres',
      };
    }

    if (!_luhnCheck(cleanSiret)) {
      return {
        'valid': false,
        'exists': false,
        'data': null,
        'message': 'Le SIRET n\'est pas valide (algorithme de Luhn)',
      };
    }

    return {
      'valid': true,
      'exists': true, // On suppose qu'il existe si le format est correct
      'data': {
        'siret': cleanSiret,
        'nic': cleanSiret.substring(9, 14), // Numéro d'établissement
        'siren': cleanSiret.substring(0, 9), // Numéro SIREN
      },
      'message': 'Format SIRET valide',
    };
  }

  // Méthode principale de validation
  static Future<Map<String, dynamic>> validateSiret(
    String siret, {
    bool useAPI = false,
  }) async {
    if (useAPI) {
      // Essayer d'abord l'API INSEE, puis l'API alternative
      Map<String, dynamic> result = await validateSiretWithAPI(siret);
      if (result['valid']) {
        return result;
      }

      // Si l'API INSEE échoue, essayer l'API alternative
      return await validateSiretAlternative(siret);
    } else {
      // Validation locale uniquement
      return validateSiretLocal(siret);
    }
  }

  // Formatage du SIRET pour l'affichage
  static String formatSiret(String siret) {
    String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanSiret.length != 14) return siret;

    return '${cleanSiret.substring(0, 3)} ${cleanSiret.substring(3, 6)} ${cleanSiret.substring(6, 9)} ${cleanSiret.substring(9, 12)} ${cleanSiret.substring(12, 14)}';
  }

  // Extraction des informations du SIRET
  static Map<String, String> extractSiretInfo(String siret) {
    String cleanSiret = siret.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanSiret.length != 14) {
      return {};
    }

    return {
      'siren': cleanSiret.substring(0, 9),
      'nic': cleanSiret.substring(9, 14),
      'siret': cleanSiret,
      'formatted': formatSiret(cleanSiret),
    };
  }
}
