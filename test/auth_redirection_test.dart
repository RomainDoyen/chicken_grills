import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Redirection Tests', () {
    test('should redirect admin to admin_home', () {
      String role = 'admin';
      String expectedRoute = '/admin_home';

      String actualRoute = _getRouteForRole(role);
      expect(actualRoute, expectedRoute);
    });

    test('should redirect pro to pro_home', () {
      String role = 'pro';
      String expectedRoute = '/pro_home';

      String actualRoute = _getRouteForRole(role);
      expect(actualRoute, expectedRoute);
    });

    test('should redirect lambda to lambda_home', () {
      String role = 'lambda';
      String expectedRoute = '/lambda_home';

      String actualRoute = _getRouteForRole(role);
      expect(actualRoute, expectedRoute);
    });

    test('should redirect unknown role to lambda_home', () {
      String role = 'unknown';
      String expectedRoute = '/lambda_home';

      String actualRoute = _getRouteForRole(role);
      expect(actualRoute, expectedRoute);
    });

    test('should redirect empty role to lambda_home', () {
      String role = '';
      String expectedRoute = '/lambda_home';

      String actualRoute = _getRouteForRole(role);
      expect(actualRoute, expectedRoute);
    });

    test('should redirect null role to lambda_home', () {
      String? role = null;
      String expectedRoute = '/lambda_home';

      String actualRoute = _getRouteForRole(role ?? 'lambda');
      expect(actualRoute, expectedRoute);
    });
  });
}

// Fonction de test qui simule la logique de redirection
String _getRouteForRole(String role) {
  if (role == 'admin') {
    return '/admin_home';
  } else if (role == 'pro') {
    return '/pro_home';
  } else {
    return '/lambda_home';
  }
}
