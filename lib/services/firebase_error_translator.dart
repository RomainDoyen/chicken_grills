class FirebaseErrorTranslator {
  /// Traduit les messages d'erreur Firebase en français
  static String translateError(String errorMessage) {
    // Messages d'erreur Firebase Auth
    if (errorMessage.contains('firebase_auth/invalid-credential')) {
      return 'Email ou mot de passe incorrect';
    }
    if (errorMessage.contains('firebase_auth/user-not-found')) {
      return 'Aucun compte trouvé avec cet email';
    }
    if (errorMessage.contains('firebase_auth/wrong-password')) {
      return 'Mot de passe incorrect';
    }
    if (errorMessage.contains('firebase_auth/email-already-in-use')) {
      return 'Cet email est déjà utilisé par un autre compte';
    }
    if (errorMessage.contains('firebase_auth/weak-password')) {
      return 'Le mot de passe est trop faible';
    }
    if (errorMessage.contains('firebase_auth/invalid-email')) {
      return 'Format d\'email invalide';
    }
    if (errorMessage.contains('firebase_auth/too-many-requests')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard';
    }
    if (errorMessage.contains('firebase_auth/network-request-failed')) {
      return 'Erreur de connexion réseau';
    }
    if (errorMessage.contains('firebase_auth/user-disabled')) {
      return 'Ce compte a été désactivé';
    }
    if (errorMessage.contains('firebase_auth/operation-not-allowed')) {
      return 'Cette opération n\'est pas autorisée';
    }
    if (errorMessage.contains('firebase_auth/requires-recent-login')) {
      return 'Veuillez vous reconnecter pour effectuer cette action';
    }
    if (errorMessage.contains(
      'firebase_auth/account-exists-with-different-credential',
    )) {
      return 'Un compte existe déjà avec cet email mais avec une méthode de connexion différente';
    }
    if (errorMessage.contains('firebase_auth/invalid-verification-code')) {
      return 'Code de vérification invalide';
    }
    if (errorMessage.contains('firebase_auth/invalid-verification-id')) {
      return 'ID de vérification invalide';
    }
    if (errorMessage.contains('firebase_auth/quota-exceeded')) {
      return 'Quota dépassé. Veuillez réessayer plus tard';
    }
    if (errorMessage.contains('firebase_auth/app-not-authorized')) {
      return 'Application non autorisée';
    }
    if (errorMessage.contains('firebase_auth/captcha-check-failed')) {
      return 'Échec de la vérification CAPTCHA';
    }
    if (errorMessage.contains('firebase_auth/missing-verification-code')) {
      return 'Code de vérification manquant';
    }
    if (errorMessage.contains('firebase_auth/missing-verification-id')) {
      return 'ID de vérification manquant';
    }
    if (errorMessage.contains('firebase_auth/invalid-phone-number')) {
      return 'Numéro de téléphone invalide';
    }
    if (errorMessage.contains('firebase_auth/missing-phone-number')) {
      return 'Numéro de téléphone manquant';
    }
    if (errorMessage.contains('firebase_auth/invalid-verification-code')) {
      return 'Code de vérification invalide';
    }

    // Messages d'erreur Firestore
    if (errorMessage.contains('permission-denied')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires';
    }
    if (errorMessage.contains('unavailable')) {
      return 'Service temporairement indisponible';
    }
    if (errorMessage.contains('deadline-exceeded')) {
      return 'Délai d\'attente dépassé';
    }
    if (errorMessage.contains('resource-exhausted')) {
      return 'Ressources épuisées';
    }
    if (errorMessage.contains('failed-precondition')) {
      return 'Condition préalable non remplie';
    }
    if (errorMessage.contains('aborted')) {
      return 'Opération annulée';
    }
    if (errorMessage.contains('out-of-range')) {
      return 'Valeur hors limites';
    }
    if (errorMessage.contains('unimplemented')) {
      return 'Fonctionnalité non implémentée';
    }
    if (errorMessage.contains('internal')) {
      return 'Erreur interne du serveur';
    }
    if (errorMessage.contains('data-loss')) {
      return 'Perte de données';
    }
    if (errorMessage.contains('unauthenticated')) {
      return 'Non authentifié';
    }

    // Messages d'erreur génériques
    if (errorMessage.contains('network')) {
      return 'Erreur de connexion réseau';
    }
    if (errorMessage.contains('timeout')) {
      return 'Délai d\'attente dépassé';
    }
    if (errorMessage.contains('connection')) {
      return 'Erreur de connexion';
    }

    // Si aucun message spécifique n'est trouvé, retourner le message original
    return 'Une erreur est survenue: $errorMessage';
  }

  /// Traduit les messages d'erreur de validation
  static String translateValidationError(String field, String error) {
    switch (field.toLowerCase()) {
      case 'email':
        if (error.contains('required')) {
          return 'L\'email est requis';
        }
        if (error.contains('invalid')) {
          return 'Format d\'email invalide';
        }
        break;
      case 'password':
        if (error.contains('required')) {
          return 'Le mot de passe est requis';
        }
        if (error.contains('weak')) {
          return 'Le mot de passe est trop faible';
        }
        if (error.contains('length')) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        break;
      case 'firstName':
        if (error.contains('required')) {
          return 'Le prénom est requis';
        }
        break;
      case 'lastName':
        if (error.contains('required')) {
          return 'Le nom est requis';
        }
        break;
      case 'phone':
        if (error.contains('required')) {
          return 'Le numéro de téléphone est requis';
        }
        if (error.contains('invalid')) {
          return 'Format de numéro de téléphone invalide';
        }
        break;
      case 'siret':
        if (error.contains('required')) {
          return 'Le numéro SIRET est requis';
        }
        if (error.contains('invalid')) {
          return 'Format de SIRET invalide';
        }
        if (error.contains('not-found')) {
          return 'Ce SIRET n\'existe pas';
        }
        break;
    }
    return 'Erreur de validation pour $field';
  }
}
