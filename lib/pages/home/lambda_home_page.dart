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
  bool _isEditing = false;

  // Contrôleurs pour les champs de texte
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _numTelController;

  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialisation des contrôleurs
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _numTelController = TextEditingController();
    
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
          
          // Mise à jour des contrôleurs avec les données utilisateur
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _numTelController.text = _numTel;
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
        // Réinitialiser le mode édition quand on ferme la sidebar
        _isEditing = false;
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveUserData() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Color(0xFFEF5829),
          ),
        );
      },
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Mise à jour des données dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'numTel': _numTelController.text.trim(),
        });

        // Mise à jour des variables d'état
        setState(() {
          _firstName = _firstNameController.text.trim();
          _lastName = _lastNameController.text.trim();
          _email = _emailController.text.trim();
          _numTel = _numTelController.text.trim();
          _isEditing = false;
        });

        // Fermer l'indicateur de chargement
        Navigator.of(context).pop();

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEF2FC),
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
                  decoration: BoxDecoration(color: Color(0xFFEEF2FC)),
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
                right: _isSidebarOpen ? _sidebarAnimation.value : -280,
                top: 0,
                bottom: 0,
                width: 280,
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
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "$_firstName $_lastName".toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            /*IconButton(
              icon: Icon(Icons.exit_to_app, size: 24, color: Colors.red),
              onPressed: _logout,
            ),*/
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
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(-5, 0))],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Color(0xFFEF5829).withOpacity(0.9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? "Modifier profil" : "Profil",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "$_firstName $_lastName",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24, color: Colors.white),
                    onPressed: _toggleSidebar,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing ? _buildEditField(Icons.person, "Nom", _firstNameController) 
                                 : _buildProfileItem(Icons.person, "Nom", _firstName),
                      _buildDivider(),
                      _isEditing ? _buildEditField(Icons.badge, "Prénom", _lastNameController) 
                                 : _buildProfileItem(Icons.badge, "Prénom", _lastName),
                      _buildDivider(),
                      _isEditing ? _buildEditField(Icons.email, "Email", _emailController) 
                                 : _buildProfileItem(Icons.email, "Email", _email),
                      _buildDivider(),
                      _isEditing ? _buildEditField(Icons.phone, "Téléphone", _numTelController) 
                                 : _buildProfileItem(Icons.phone, "Téléphone", _numTel),
                      SizedBox(height: 20),
                      _isEditing
                          ? Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.cancel,
                                    label: "Annuler",
                                    color: Colors.grey,
                                    onPressed: _toggleEditMode,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.save,
                                    label: "Enregistrer",
                                    color: Colors.green,
                                    onPressed: _saveUserData,
                                  ),
                                ),
                              ],
                            )
                          : _buildActionButton(
                              icon: Icons.edit,
                              label: "Modifier profil",
                              color: Color(0xFF5B67CA),
                              onPressed: _toggleEditMode,
                            ),
                      SizedBox(height: 15),
                      if (!_isEditing)
                        _buildActionButton(
                          icon: Icons.exit_to_app,
                          label: "Déconnexion",
                          color: Colors.red.shade400,
                          onPressed: _logout,
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEEF2FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFFEF5829), size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFEEF2FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFFEF5829), size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFEF5829), width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.2),
      thickness: 1.0,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Libérer les contrôleurs
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _numTelController.dispose();
    
    _animationController.dispose();
    super.dispose();
  }
}