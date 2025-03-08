import "dart:async";
import "package:flutter/material.dart";

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

  bool _isLogoVisible = false;

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isLogoVisible = true;
      });
      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.white,
      home: Scaffold(
        backgroundColor: Color(0xFFF9D3C0),
        body: Center(
          child: AnimatedPositioned(
            duration: const Duration(seconds: 2),
            top: _isLogoVisible ? 0 : MediaQuery.of(context).size.height / 4,
            left: 0,
            right: 0,
            child: Container(
              width: 295,
              height: 165,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/icon.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
