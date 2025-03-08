import 'package:chicken_grills/pages/home/bottom_navbar.dart';
import 'package:chicken_grills/pages/home/map_widget.dart';
import 'package:flutter/material.dart';

class LambdaHomePage extends StatefulWidget {
  const LambdaHomePage({super.key});

  @override
  _LambdaHomePage createState() => _LambdaHomePage();
}

class _LambdaHomePage extends State<LambdaHomePage> {
  String _firstName = "";
  String _lastName = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: _buildHeader(),
                ),
              ),
              
              // Map widget
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(top: 3, left: 0, right: 0),
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
              style: TextStyle(
                fontFamily: 'ArchivoNarrow',
                fontWeight: FontWeight.w400,
                fontSize: 14
              )
            ),
          ],
        ),
        Row(
          children: [
            SizedBox(width: 8), // Ajoute un espace entre les boutons
            IconButton(
              //icon: Image.asset("assets/images/settings.png", width: 24, height: 24),
              icon: Icon(
                Icons.settings, 
                size: 24, 
                color: Color(0xFFEF5829)
              ),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}