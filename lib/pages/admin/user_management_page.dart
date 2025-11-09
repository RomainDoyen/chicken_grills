import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:chicken_grills/components/user_card.dart';
import 'package:chicken_grills/components/action_button.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .orderBy(_sortBy, descending: _sortDescending)
              .get();

      List<Map<String, dynamic>> users =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'firstName': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'email': data['email'] ?? '',
              'role': data['role'] ?? 'lambda',
              'createdAt': data['createdAt'] ?? Timestamp.now(),
              'phone': data['phone'] ?? '',
              'isActive': data['isActive'] ?? true,
            };
          }).toList();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des utilisateurs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers =
          _users.where((user) {
            bool matchesSearch =
                _searchQuery.isEmpty ||
                user['firstName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                user['lastName'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                user['email'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            bool matchesRole =
                _roleFilter == 'all' || user['role'] == _roleFilter;

            return matchesSearch && matchesRole;
          }).toList();
    });
  }

  void _updateUserRole(String userId, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });

      // Mettre à jour la liste locale
      setState(() {
        int index = _users.indexWhere((user) => user['id'] == userId);
        if (index != -1) {
          _users[index]['role'] = newRole;
        }
        _filterUsers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rôle mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du rôle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });

      setState(() {
        int index = _users.indexWhere((user) => user['id'] == userId);
        if (index != -1) {
          _users[index]['isActive'] = !currentStatus;
        }
        _filterUsers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du statut'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteUser(String userId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmer la suppression'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer cet utilisateur ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
          _filterUsers();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text('Gestion des utilisateurs'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange,
                      ),
                    )
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: AppTheme.textFieldDecoration(
              hintText: 'Rechercher un utilisateur...',
            ).copyWith(prefixIcon: Icon(Icons.search)),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterUsers();
            },
          ),
          SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _roleFilter,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par rôle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous les rôles'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrateurs'),
                    ),
                    DropdownMenuItem(
                      value: 'pro',
                      child: Text('Professionnels'),
                    ),
                    DropdownMenuItem(
                      value: 'lambda',
                      child: Text('Particuliers'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _roleFilter = value!;
                    });
                    _filterUsers();
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Date de création'),
                    ),
                    DropdownMenuItem(value: 'firstName', child: Text('Prénom')),
                    DropdownMenuItem(value: 'lastName', child: Text('Nom')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    bool isActive = user['isActive'] ?? true;

    return UserCard(
      name: '${user['firstName']} ${user['lastName']}',
      email: user['email'],
      role: user['role'],
      phone: user['phone'] ?? '',
      isActive: isActive,
      onEdit: () => _showRoleDialog(user),
      onDelete: () => _deleteUser(user['id']),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'pro':
        return Colors.orange;
      case 'lambda':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'pro':
        return 'Pro';
      case 'lambda':
        return 'Particulier';
      default:
        return 'Inconnu';
    }
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Modifier le rôle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Utilisateur: ${user['firstName']} ${user['lastName']}'),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Nouveau rôle',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'lambda',
                      child: Text('Particulier'),
                    ),
                    DropdownMenuItem(
                      value: 'pro',
                      child: Text('Professionnel'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrateur'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _updateUserRole(user['id'], selectedRole);
                },
                child: Text('Confirmer'),
              ),
            ],
          ),
    );
  }
}
