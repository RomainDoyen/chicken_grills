import 'package:flutter/material.dart';

class SignupSuccessPage extends StatelessWidget {
  const SignupSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 432,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône de validation
          Container(
            padding: const EdgeInsets.all(20),
            child: Image.asset('assets/images/check-circle.png'),
          ),

          const SizedBox(height: 20),

          // Texte de validation
          const Text(
            "Félicitation, votre inscription a été validée !",
            textAlign: TextAlign.center,
            style: TextStyle(
              //fontFamily: 'ArchivoNarrow',
              fontSize: 18, 
              fontWeight: FontWeight.w600
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Vous recevrez un mail de validation prochainement.",
            textAlign: TextAlign.center,
            style: TextStyle(
              //fontFamily: 'ArchivoNarrow',
              fontSize: 16, 
              color: Colors.black
            ),
          ),
          const SizedBox(height: 20),

          // Bouton "Commencer"
          SizedBox(
            width: 207,
            height: 45,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Ferme la modale
                Navigator.pushReplacementNamed(context, '/home'); // Va à l'accueil
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5829),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Commencer",
                style: TextStyle(
                  //fontFamily: 'ArchivoNarrow',
                  fontSize: 20, 
                  color: Colors.white,
                  fontWeight: FontWeight.w700
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}