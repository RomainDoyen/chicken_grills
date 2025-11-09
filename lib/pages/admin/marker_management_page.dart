import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:chicken_grills/components/action_button.dart';
import 'package:chicken_grills/components/marker_card.dart';

class MarkerManagementPage extends StatefulWidget {
  @override
  _MarkerManagementPageState createState() => _MarkerManagementPageState();
}

class _MarkerManagementPageState extends State<MarkerManagementPage> {
  List<Map<String, dynamic>> _markers = [];
  List<Map<String, dynamic>> _filteredMarkers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('markers')
              .orderBy(_sortBy, descending: _sortDescending)
              .get();

      List<Map<String, dynamic>> markers =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'title': data['title'] ?? '',
              'description': data['description'] ?? '',
              'userId': data['userId'] ?? '',
              'latitude': data['latitude'] ?? 0.0,
              'longitude': data['longitude'] ?? 0.0,
              'createdAt': data['createdAt'] ?? Timestamp.now(),
              'isActive': data['isActive'] ?? true,
              'category': data['category'] ?? 'general',
            };
          }).toList();

      // Récupérer les informations des utilisateurs
      for (var marker in markers) {
        if (marker['userId'] != null) {
          try {
            DocumentSnapshot userDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(marker['userId'])
                    .get();

            if (userDoc.exists) {
              Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;
              marker['userName'] =
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';
              marker['userEmail'] = userData['email'] ?? '';
            }
          } catch (e) {
            print('Erreur lors de la récupération des infos utilisateur: $e');
            marker['userName'] = 'Utilisateur inconnu';
            marker['userEmail'] = '';
          }
        }
      }

      setState(() {
        _markers = markers;
        _filteredMarkers = markers;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des marqueurs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMarkers() {
    setState(() {
      _filteredMarkers =
          _markers.where((marker) {
            bool matchesSearch =
                _searchQuery.isEmpty ||
                marker['title'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                marker['description'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (marker['userName'] ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            bool matchesStatus =
                _statusFilter == 'all' ||
                (_statusFilter == 'active' && marker['isActive']) ||
                (_statusFilter == 'inactive' && !marker['isActive']);

            return matchesSearch && matchesStatus;
          }).toList();
    });
  }

  void _toggleMarkerStatus(String markerId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('markers')
          .doc(markerId)
          .update({'isActive': !currentStatus});

      setState(() {
        int index = _markers.indexWhere((marker) => marker['id'] == markerId);
        if (index != -1) {
          _markers[index]['isActive'] = !currentStatus;
        }
        _filterMarkers();
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

  void _deleteMarker(String markerId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmer la suppression'),
            content: Text('Êtes-vous sûr de vouloir supprimer ce marqueur ?'),
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
            .collection('markers')
            .doc(markerId)
            .delete();

        setState(() {
          _markers.removeWhere((marker) => marker['id'] == markerId);
          _filterMarkers();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marqueur supprimé avec succès'),
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

  void _showMarkerDetails(Map<String, dynamic> marker) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Détails du marqueur'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Titre', marker['title']),
                  _buildDetailRow('Description', marker['description']),
                  _buildDetailRow(
                    'Utilisateur',
                    marker['userName'] ?? 'Inconnu',
                  ),
                  _buildDetailRow(
                    'Email',
                    marker['userEmail'] ?? 'Non disponible',
                  ),
                  _buildDetailRow('Latitude', marker['latitude'].toString()),
                  _buildDetailRow('Longitude', marker['longitude'].toString()),
                  _buildDetailRow('Catégorie', marker['category']),
                  _buildDetailRow(
                    'Statut',
                    marker['isActive'] ? 'Actif' : 'Inactif',
                  ),
                  _buildDetailRow('Créé le', _formatDate(marker['createdAt'])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text('Gestion des marqueurs'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMarkers,
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
                    : _buildMarkerList(),
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
              hintText: 'Rechercher un marqueur...',
            ).copyWith(prefixIcon: Icon(Icons.search)),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterMarkers();
            },
          ),
          SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tous les statuts'),
                    ),
                    DropdownMenuItem(value: 'active', child: Text('Actifs')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactifs'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    _filterMarkers();
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
                    DropdownMenuItem(value: 'title', child: Text('Titre')),
                    DropdownMenuItem(
                      value: 'category',
                      child: Text('Catégorie'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _loadMarkers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerList() {
    if (_filteredMarkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Aucun marqueur trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredMarkers.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> marker = _filteredMarkers[index];
        return _buildMarkerCard(marker);
      },
    );
  }

  Widget _buildMarkerCard(Map<String, dynamic> marker) {
    bool isActive = marker['isActive'] ?? true;

    return MarkerCard(
      title: marker['title'] ?? 'Sans titre',
      description: marker['description'] ?? 'Aucune description',
      userName: marker['userName'] ?? 'Utilisateur inconnu',
      userEmail: marker['userEmail'] ?? '',
      category: marker['category'] ?? 'general',
      isActive: isActive,
      onTap: () => _showMarkerDetails(marker),
      onEdit: () => _showMarkerDetails(marker),
      onDelete: () => _deleteMarker(marker['id']),
      onToggleStatus: () => _toggleMarkerStatus(marker['id'], isActive),
    );
  }
}
