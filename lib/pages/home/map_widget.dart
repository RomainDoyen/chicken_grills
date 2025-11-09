import 'dart:async';
import 'dart:convert';

import 'package:chicken_grills/models/marker.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  late Stream<QuerySnapshot> _markersStream;
  StreamSubscription<auth.User?>? _authSubscription;
  bool _isUserAuthorizedToAddMarker = false;

  @override
  void initState() {
    super.initState();
    // Initialiser le stream pour écouter en temps réel
    _markersStream =
        FirebaseFirestore.instance.collection('markers').snapshots();
    _authSubscription = auth.FirebaseAuth.instance.userChanges().listen(
      _handleAuthChanges,
    );
    _evaluateUserPermissions(auth.FirebaseAuth.instance.currentUser);
  }

  void _handleAuthChanges(auth.User? user) {
    _evaluateUserPermissions(user);
  }

  Future<void> _evaluateUserPermissions(auth.User? user) async {
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _isUserAuthorizedToAddMarker = false;
      });
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = doc.data();
      final role = (data != null ? data['role'] : null) ?? 'lambda';
      final bool authorized = role == 'pro' || role == 'admin';

      if (mounted) {
        setState(() {
          _isUserAuthorizedToAddMarker = authorized;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUserAuthorizedToAddMarker = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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

  void _handleMapLongPress(TapPosition tapPosition, LatLng latLng) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _promptLogin();
      return;
    }

    if (!_isUserAuthorizedToAddMarker) {
      _notifyInsufficientPermissions();
      return;
    }

    _showAddMarkerSheet(latLng);
  }

  void _promptLogin() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
            'Connectez-vous ou créez un compte pour ajouter un nouveau marqueur sur la carte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Se connecter'),
            ),
          ],
        );
      },
    );
  }

  void _notifyInsufficientPermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Seuls les professionnels ou administrateurs peuvent ajouter des marqueurs.',
        ),
      ),
    );
  }

  Future<void> _showAddMarkerSheet(LatLng position) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    if (!_isUserAuthorizedToAddMarker) {
      _notifyInsufficientPermissions();
      return;
    }

    final TextEditingController addressController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final String resolvedAddress = await _reverseGeocode(position);
    if (resolvedAddress.isNotEmpty) {
      addressController.text = resolvedAddress;
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        bool isSubmitting = false;
        String? errorMessage;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nouveau marqueur',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(modalContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Latitude ${position.latitude.toStringAsFixed(4)}, Longitude ${position.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnelle)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              isSubmitting
                                  ? null
                                  : () async {
                                    final String address =
                                        addressController.text.trim();
                                    if (address.isEmpty) {
                                      setModalState(() {
                                        errorMessage =
                                            'Merci de renseigner une adresse.';
                                      });
                                      return;
                                    }

                                    setModalState(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('markers')
                                          .add({
                                            'address': address,
                                            'description':
                                                descriptionController.text
                                                    .trim(),
                                            'latitude': position.latitude,
                                            'longitude': position.longitude,
                                            'userId': currentUser.uid,
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      if (mounted) {
                                        Navigator.of(modalContext).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Marqueur ajouté avec succès !',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() {
                                        isSubmitting = false;
                                        errorMessage =
                                            'Une erreur est survenue lors de l\'enregistrement.';
                                      });
                                    }
                                  },
                          child:
                              isSubmitting
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    addressController.dispose();
    descriptionController.dispose();
  }

  Future<String> _reverseGeocode(LatLng position) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return '';
      }
      final place = placemarks.first;
      final parts = <String>[];
      if ((place.street ?? '').isNotEmpty) {
        parts.add(place.street!);
      }
      final postalAndCity = [
        place.postalCode,
        place.locality,
      ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
      if (postalAndCity.isNotEmpty) {
        parts.add(postalAndCity);
      }
      return parts.join(', ');
    } catch (e) {
      return '';
    }
  }

  void _showMarkerDetails(MarkerModel marker) {
    // Obtenir l'ID de l'utilisateur actuel
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    final bool isOwner =
        currentUser != null && currentUser.uid == marker.userId;

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
                color: Color(0xFFF9D3C0),
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
                            child:
                                isOwner
                                    ? _buildOwnerInfoCard(
                                      marker,
                                    ) // Si c'est le propriétaire, afficher toutes les infos
                                    : _buildLimitedInfoCard(
                                      marker,
                                    ), // Sinon, afficher des informations limitées
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
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final Uri url = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=${marker.point.latitude},${marker.point.longitude}',
                                );
                                final bool launched = await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!launched && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Impossible d\'ouvrir l\'itinéraire dans Google Maps.',
                                      ),
                                    ),
                                  );
                                }
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(marker.userId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildUnavailableContactSection();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String? coverData = userData['coverImageData'];
        final String? profileData = userData['profileImageData'];
        final String initials = _initialsFromData(
          userData['firstName'],
          userData['lastName'],
          userData['email'],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarkerHeader(coverData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMarkerAvatar(profileData, initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userData['firstName']} ${userData['lastName']} (Vous)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData['email'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.phone, userData['numTel'] ?? 'Non renseigné'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.business, 'SIRET: ${userData['numSiret']}'),
                  if (userData['description'] != null &&
                      userData['description'].toString().isNotEmpty) ...[
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
                  if (userData['address'] != null &&
                      userData['address'].toString().isNotEmpty) ...[
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarkerHeader(String? coverData) {
    final ImageProvider? image = _decodeImage(coverData);
    if (image != null) {
      return Container(
        height: 180,
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF9D3C0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(
            image: image,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  color: const Color(0xFFF9D3C0),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.primaryOrange,
                    size: 40,
                  ),
                ),
          ),
        ),
      );
    }
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF9D3C0),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppTheme.primaryOrange,
        size: 40,
      ),
    );
  }

  Widget _buildMarkerAvatar(String? imageData, String initials) {
    final ImageProvider? image = _decodeImage(imageData);
    if (image != null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.secondaryOrange.withOpacity(0.2),
        backgroundImage: image,
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.secondaryOrange.withOpacity(0.2),
      child: Text(
        initials,
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUnavailableContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMarkerHeader(null),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Impossible de charger les informations'),
        ),
      ],
    );
  }

  String _initialsFromData(dynamic firstName, dynamic lastName, dynamic email) {
    final String first = (firstName ?? '').toString().trim();
    final String last = (lastName ?? '').toString().trim();
    if (first.isEmpty && last.isEmpty) {
      final String mail = (email ?? '').toString();
      return mail.isNotEmpty ? mail.substring(0, 1).toUpperCase() : '?';
    }
    final String firstInitial = first.isNotEmpty ? first.substring(0, 1) : '';
    final String lastInitial = last.isNotEmpty ? last.substring(0, 1) : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  ImageProvider? _decodeImage(String? data) {
    if (data == null) return null;
    final String trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) {
      return NetworkImage(trimmed);
    }
    try {
      final bytes = base64Decode(trimmed);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Widget _buildLimitedInfoCard(MarkerModel marker) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('publicProfiles')
              .doc(marker.userId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildUnavailableContactSection();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String? coverData = userData['coverImageData'];
        final String? profileData = userData['profileImageData'];
        final String initials = _initialsFromData(
          userData['firstName'],
          userData['lastName'],
          userData['email'],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMarkerHeader(coverData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMarkerAvatar(profileData, initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userData['firstName']} ${userData['lastName']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData['email'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.phone, userData['numTel'] ?? 'Non renseigné'),
                  if (userData['description'] != null &&
                      userData['description'].toString().isNotEmpty) ...[
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
              ),
            ),
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
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _markersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];
        final List<Marker> markers = _buildMarkers(documents);

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-21.1151, 55.5364),
            initialZoom: 10.0,
            onLongPress: _handleMapLongPress,
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
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }
}
