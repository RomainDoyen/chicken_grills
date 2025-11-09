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
        Navigator.pushReplacementNamed(context, '/main');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9D3C0),
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: _isLogoVisible ? 1 : 0,
          curve: Curves.easeInOut,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 600),
            scale: _isLogoVisible ? 1 : 0.85,
            curve: Curves.easeOutBack,
            child: Container(
              width: 220,
              height: 220,
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
