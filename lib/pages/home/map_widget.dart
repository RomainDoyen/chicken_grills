import 'package:chicken_grills/models/marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  late Stream<QuerySnapshot> _markersStream;
  
  @override
  void initState() {
    super.initState();
    // Initialiser le stream pour écouter en temps réel
    _markersStream = FirebaseFirestore.instance.collection('markers').snapshots();
  }
  
  List<Marker> _buildMarkers(List<DocumentSnapshot> documents) {
    return documents.map((doc) {
      final MarkerModel markerModel = MarkerModel.fromFirestore(doc);
      
      return Marker(
        width: 40.0,
        height: 40.0,
        point: markerModel.point,
        child: GestureDetector(
          onTap: () {
            _showMarkerDetails(markerModel);
          },
          child: Image.asset(
            'assets/images/chicken-marker.png',
            width: 40,
            height: 40,
          ),
        ),
      );
    }).toList();
  }

  void _showMarkerDetails(MarkerModel marker) {
    // Obtenir l'ID de l'utilisateur actuel
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser != null && currentUser.uid == marker.userId;
    
    // Afficher la popup moderne
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poignée de glissement
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // Image d'en-tête (vous pouvez utiliser une image liée au type de lieu)
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/chicken-header.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // Informations du lieu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Adresse avec icône
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  marker.address,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Description du lieu
                          if (marker.description.isNotEmpty) ...[
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: Text(marker.description),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Informations sur le professionnel
                          const Text(
                            'Contact professionnel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Carte du professionnel - avec informations limitées
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              color: Colors.white,
                            ),
                            child: isOwner 
                              ? _buildOwnerInfoCard(marker)  // Si c'est le propriétaire, afficher toutes les infos
                              : _buildLimitedInfoCard(marker)  // Sinon, afficher des informations limitées
                          ),
                        ],
                      ),
                    ),
                    
                    // Boutons d'action
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Itinéraire'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // Logique pour obtenir l'itinéraire
                              },
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Modifier'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Logique pour modifier le marqueur
                                  Navigator.pop(context);
                                  // Naviguez vers la page de modification
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Widget pour afficher les informations complètes du propriétaire (si c'est l'utilisateur actuel)
  Widget _buildOwnerInfoCard(MarkerModel marker) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(marker.userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Impossible de charger vos informations'),
          );
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom et prénom
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber[700],
                  child: Text(
                    '${userData['firstName'][0]}${userData['lastName'][0]}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${userData['firstName']} ${userData['lastName']} (Vous)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informations de contact
            _infoRow(Icons.email, userData['email']),
            const SizedBox(height: 8),
            _infoRow(Icons.phone, userData['numTel']),
            const SizedBox(height: 8),
            _infoRow(Icons.business, 'SIRET: ${userData['numSiret']}'),
            
            // Description de l'utilisateur si disponible
            if (userData['description'] != null && userData['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'À propos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(userData['description']),
            ],

            // Adresse de l'utilisateur si disponible
            if (userData['address'] != null && userData['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Adresse',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(userData['address']),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLimitedInfoCard(MarkerModel marker) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('publicProfiles')
          .doc(marker.userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('Impossible de charger les informations'),
          );
        }
        
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom et prénom du professionnel
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber[700],
                  child: Text(
                    '${userData['firstName'][0]}${userData['lastName'][0]}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${userData['firstName']} ${userData['lastName']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Numéro de téléphone professionnel
            _infoRow(Icons.phone, userData['numTel']),

            const SizedBox(height: 16),

            // Email professionnel
            _infoRow(Icons.email, userData['email']),
            
            // Description du professionnel si disponible
            if (userData['description'] != null && userData['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'À propos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(userData['description']),
            ],

          ],
        );
      },
    );
  }
  
  // Helper pour créer une ligne d'information avec icône
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _markersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              
              // Si nous avons des données, construire la carte avec les marqueurs
              final List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];
              final List<Marker> markers = _buildMarkers(documents);
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-21.1151, 55.5364),
                  initialZoom: 10.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.chicken_grills.app',
                    maxZoom: 18,
                  ),
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}