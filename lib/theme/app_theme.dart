import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryOrange = Color(0xFFEF5829);
  static const Color secondaryOrange = Color(0xFFF9B44E);
  static const Color backgroundPeach = Color(0xFFF9D3C0);
  static const Color white = Colors.white;
  static const Color errorRed = Color.fromARGB(255, 160, 46, 12);
  static const Color textGray = Color(0xFFDDDDDD);

  // Styles de texte
  static const TextStyle headingStyle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w500,
    color: primaryOrange,
  );

  static const TextStyle labelStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 20,
    color: primaryOrange,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle linkStyle = TextStyle(
    color: primaryOrange,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle errorStyle = TextStyle(
    color: errorRed,
    fontWeight: FontWeight.bold,
  );

  // Styles de boutons
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryOrange,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    minimumSize: const Size(250, 50),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    minimumSize: const Size(250, 50),
  );

  static ButtonStyle smallButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryOrange,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    minimumSize: const Size(120, 40),
  );

  // Styles de champs de texte
  static InputDecoration textFieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textGray,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  // Thème principal de l'application
  static ThemeData get theme => ThemeData(
    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: backgroundPeach,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryOrange,
      foregroundColor: white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(
        color: textGray,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: headingStyle,
      titleMedium: labelStyle,
      bodyMedium: bodyStyle,
    ),
  );

  // Widgets réutilisables
  static Widget logoWidget({double size = 150}) {
    return Image.asset('assets/images/icon.png', width: size);
  }

  static Widget welcomeText() {
    return const Text(
      "Bienvenue, connectez-vous pour commencer",
      textAlign: TextAlign.left,
      style: headingStyle,
    );
  }

  static Widget sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: labelStyle),
    );
  }

  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: primaryButtonStyle,
        child:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    color: white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ),
    );
  }

  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: secondaryButtonStyle,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 23,
            color: primaryOrange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static Widget errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(message, style: errorStyle),
    );
  }

  static Widget loadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      width: double.infinity,
      height: double.infinity,
      child: const Center(
        child: CircularProgressIndicator(color: primaryOrange),
      ),
    );
  }
}
