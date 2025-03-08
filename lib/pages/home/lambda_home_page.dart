import 'package:chicken_grills/pages/home/bottom_navbar.dart';
import 'package:chicken_grills/pages/home/map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LambdaHomePage extends StatefulWidget {
  const LambdaHomePage({super.key});

  @override
  _LambdaHomePage createState() => _LambdaHomePage();
}

class _LambdaHomePage extends State<LambdaHomePage> with SingleTickerProviderStateMixin {
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _numTel = "";
  bool _isSidebarOpen = false;

  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    // Initialisation de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _sidebarAnimation = Tween<double>(begin: -250, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists) {
        setState(() {
          _firstName = userData['firstName'] ?? "";
          _lastName = userData['lastName'] ?? "";
          _email = userData['email'] ?? user.email ?? "";
          _numTel = userData['numTel'] ?? "Non renseigné";
        });
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9D3C0),
      extendBody: true,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  height: 70,
                  decoration: BoxDecoration(color: Color(0xFFF9D3C0)),
                  child: _buildHeader(),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: MapWidget(),
                  ),
                ),
              ),
            ],
          ),

          // Fond assombri avec animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return _isSidebarOpen
                  ? GestureDetector(
                      onTap: _toggleSidebar,
                      child: Container(
                        color: Colors.black.withOpacity(_opacityAnimation.value),
                      ),
                    )
                  : SizedBox.shrink();
            },
          ),

          // Sidebar avec animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Positioned(
                right: _sidebarAnimation.value,
                top: 0,
                bottom: 0,
                child: _buildSidebar(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: 8),
            Text(
              "$_firstName $_lastName".toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.exit_to_app, size: 24, color: Colors.red),
              onPressed: _logout,
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 24, color: Color(0xFFEF5829)),
              onPressed: _toggleSidebar,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF9D3C0),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, size: 24, color: Colors.grey),
              onPressed: _toggleSidebar,
            ),
          ),
          SizedBox(height: 10),
          Text("Nom:", style: _sidebarTextStyle()),
          Text(_firstName, style: _sidebarInfoStyle()),
          SizedBox(height: 10),
          Text("Prénom:", style: _sidebarTextStyle()),
          Text(_lastName, style: _sidebarInfoStyle()),
          SizedBox(height: 10),
          Text("Email:", style: _sidebarTextStyle()),
          Text(_email, style: _sidebarInfoStyle()),
          SizedBox(height: 10),
          Text("Téléphone:", style: _sidebarTextStyle()),
          Text(_numTel, style: _sidebarInfoStyle()),
          Spacer(),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            label: Text("Déconnexion"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _sidebarTextStyle() {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]);
  }

  TextStyle _sidebarInfoStyle() {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}