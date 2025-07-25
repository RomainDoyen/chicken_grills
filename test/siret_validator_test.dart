import 'package:flutter_test/flutter_test.dart';
import 'package:chicken_grills/services/siret_validator.dart';

void main() {
  group('SiretValidator Tests', () {
    test('should validate correct SIRET format', () {
      // SIRET valide : 784 671 695 00103 (Google France)
      String validSiret = '78467169500103';
      expect(SiretValidator.validateSiretFormat(validSiret), true);
    });

    test('should reject invalid SIRET format', () {
      // SIRET invalide (chiffre de contrôle incorrect)
      String invalidSiret = '78467169500104';
      expect(SiretValidator.validateSiretFormat(invalidSiret), false);
    });

    test('should reject SIRET with wrong length', () {
      String shortSiret = '123456789';
      expect(SiretValidator.validateSiretFormat(shortSiret), false);

      String longSiret = '123456789012345';
      expect(SiretValidator.validateSiretFormat(longSiret), false);
    });

    test('should reject SIRET with non-numeric characters', () {
      String invalidSiret = '7846716950010A';
      expect(SiretValidator.validateSiretFormat(invalidSiret), false);
    });

    test('should format SIRET correctly', () {
      String siret = '78467169500103';
      String formatted = SiretValidator.formatSiret(siret);
      expect(formatted, '784 671 695 001 03');
    });

    test('should extract SIRET information correctly', () {
      String siret = '78467169500103';
      Map<String, String> info = SiretValidator.extractSiretInfo(siret);

      expect(info['siren'], '784671695');
      expect(info['nic'], '00103');
      expect(info['siret'], '78467169500103');
      expect(info['formatted'], '784 671 695 001 03');
    });

    test('should handle SIRET with spaces and special characters', () {
      String siretWithSpaces = '784 671 695 001 03';
      expect(SiretValidator.validateSiretFormat(siretWithSpaces), true);

      String siretWithDashes = '784-671-695-001-03';
      expect(SiretValidator.validateSiretFormat(siretWithDashes), true);
    });

    test('should validate multiple known valid SIRETs', () {
      List<String> validSirets = [
        '78467169500103', // Google France
        '55208131700034', // Apple France
        '44306184100047', // Microsoft France
        '78467169500103', // Google France (duplicate for testing)
      ];

      for (String siret in validSirets) {
        expect(
          SiretValidator.validateSiretFormat(siret),
          true,
          reason: 'SIRET $siret should be valid',
        );
      }
    });

    test('should reject known invalid SIRETs', () {
      List<String> invalidSirets = [
        '78467169500104', // Chiffre de contrôle incorrect
        '12345678901234', // SIRET fictif
        '11111111111111', // SIRET avec chiffres identiques
      ];

      for (String siret in invalidSirets) {
        expect(
          SiretValidator.validateSiretFormat(siret),
          false,
          reason: 'SIRET $siret should be invalid',
        );
      }
    });
  });
}
