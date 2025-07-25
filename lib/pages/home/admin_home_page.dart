import 'package:chicken_grills/pages/home/map_widget.dart';
import 'package:chicken_grills/services/admin_stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePage createState() => _AdminHomePage();
}

class _AdminHomePage extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  bool _isSidebarOpen = false;
  bool _isLoadingStats = true;

  // Statistiques
  int _totalUsers = 0;
  int _totalMarkers = 0;
  int _proUsers = 0;
  int _lambdaUsers = 0;

  // Service pour les statistiques
  final AdminStatsService _statsService = AdminStatsService();

  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchStatistics();

    // Initialisation de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _sidebarAnimation = Tween<double>(begin: -240, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userData.exists) {
        setState(() {
          _firstName = userData['firstName'] ?? "";
          _lastName = userData['lastName'] ?? "";
          _email = userData['email'] ?? user.email ?? "";
        });
      }
    }
  }

  void _fetchStatistics() async {
    try {
      setState(() {
        _isLoadingStats = true;
      });

      // Utiliser le service de statistiques
      Map<String, int> stats = await _statsService.getStatistics();

      // Si les statistiques sont vides, essayer les statistiques simulées
      if (stats['totalUsers'] == 0 && stats['totalMarkers'] == 0) {
        print('Tentative de récupération de statistiques simulées...');
        stats = await _statsService.getSimulatedStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Statistiques simulées affichées (permissions Firebase limitées)',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      setState(() {
        _totalUsers = stats['totalUsers'] ?? 0;
        _totalMarkers = stats['totalMarkers'] ?? 0;
        _proUsers = stats['proUsers'] ?? 0;
        _lambdaUsers = stats['lambdaUsers'] ?? 0;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');

      // En cas d'erreur, afficher des statistiques par défaut
      setState(() {
        _totalUsers = 0;
        _totalMarkers = 0;
        _proUsers = 0;
        _lambdaUsers = 0;
        _isLoadingStats = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de récupérer les statistiques'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
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
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Tableau de bord",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.refresh, color: Color(0xFFEF5829)),
              onPressed: _fetchStatistics,
              tooltip: "Actualiser les statistiques",
            ),
            IconButton(
              icon: Icon(Icons.menu, color: Color(0xFFEF5829)),
              onPressed: _toggleSidebar,
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.red),
              onPressed: _logout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_sidebarAnimation.value, 0),
          child: Container(
            width: 240,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Color(0xFFF9D3C0)),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFFEF5829),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "$_firstName $_lastName",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF5829),
                        ),
                      ),
                      Text(
                        "Administrateur",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFEF5829),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarItem(
                        icon: Icons.people,
                        title: "Gestion utilisateurs",
                        onTap: () {
                          Navigator.pushNamed(context, '/admin_users');
                        },
                      ),
                      _buildSidebarItem(
                        icon: Icons.location_on,
                        title: "Gestion marqueurs",
                        onTap: () {
                          Navigator.pushNamed(context, '/admin_markers');
                        },
                      ),
                      _buildSidebarItem(
                        icon: Icons.settings,
                        title: "Paramètres",
                        onTap: () {
                          Navigator.pushNamed(context, '/admin_settings');
                        },
                      ),
                      Divider(color: Colors.grey.withOpacity(0.3)),
                      _buildSidebarItem(
                        icon: Icons.logout,
                        title: "Déconnexion",
                        onTap: _logout,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Color(0xFFEF5829)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAdminStats() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Statistiques d'administration",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF5829),
                ),
              ),
              if (_isLoadingStats)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFEF5829),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  title: "Utilisateurs",
                  value: _totalUsers.toString(),
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.location_on,
                  title: "Marqueurs",
                  value: _totalMarkers.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.business,
                  title: "Professionnels",
                  value: _proUsers.toString(),
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.person,
                  title: "Particuliers",
                  value: _lambdaUsers.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildAdminStats(),
                      Container(
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(height: 400, child: MapWidget()),
                        ),
                      ),
                    ],
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

          // Sidebar
          if (_isSidebarOpen) _buildSidebar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
