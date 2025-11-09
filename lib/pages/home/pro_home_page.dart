import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chicken_grills/models/marker.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class ProHomePage extends StatefulWidget {
  const ProHomePage({super.key});

  @override
  _ProHomePageState createState() => _ProHomePageState();
}

class _ImageEditButton extends StatelessWidget {
  const _ImageEditButton({
    required this.onPressed,
    required this.isLoading,
    this.isMini = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final bool isMini;

  @override
  Widget build(BuildContext context) {
    final double size = isMini ? 30 : 40;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.secondaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child:
            isLoading
                ? SizedBox(
                  width: size / 2,
                  height: size / 2,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: isMini ? 16 : 20,
                ),
      ),
    );
  }
}

class _ProHomePageState extends State<ProHomePage> {
  String _email = "";
  String _firstName = "";
  String _lastName = "";
  String _numTel = "";
  String _numSiret = "";
  String _description = "";
  String _address = "";
  String? _profileImageData;
  String? _coverImageData;
  bool _isUploadingProfileImage = false;
  bool _isUploadingCoverImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  final List<MarkerModel> _markers = [];
  final MapController _mapController = MapController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchMarkers();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.secondaryOrange),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 3),
              Text(
                value.isEmpty ? "Non renseigné" : value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _fetchUserData() async {
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userData.exists) {
        setState(() {
          _email = userData['email'];
          _firstName = userData['firstName'];
          _lastName = userData['lastName'];
          _numTel = userData['numTel'];
          _numSiret = userData['numSiret'];
          _description = userData['description'] ?? 'Aucune description';
          _address = userData['address'] ?? 'Adresse non renseignée';
          _profileImageData = userData['profileImageData'];
          _coverImageData = userData['coverImageData'];
        });
      }
    }
  }

  void _fetchMarkers() async {
    // Charger les marqueurs existants depuis Firestore pour l'utilisateur connecté
    auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('markers')
              .where('userId', isEqualTo: user.uid)
              .get();
      setState(() {
        _markers.clear();
        for (var doc in snapshot.docs) {
          _markers.add(MarkerModel.fromFirestore(doc));
        }
      });
    }
  }

  Future<void> _updateUserImages({
    String? profileData,
    String? coverData,
  }) async {
    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {};
    if (profileData != null) updates['profileImageData'] = profileData;
    if (coverData != null) updates['coverImageData'] = coverData;
    if (updates.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updates, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('publicProfiles')
        .doc(user.uid)
        .set(updates, SetOptions(merge: true));
  }

  Future<void> _pickAndUploadImage({
    required bool isCover,
    void Function(void Function())? modalSetState,
  }) async {
    if ((isCover && _isUploadingCoverImage) ||
        (!isCover && _isUploadingProfileImage)) {
      return;
    }

    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked == null) return;

    void update(bool value) {
      if (isCover) {
        _isUploadingCoverImage = value;
      } else {
        _isUploadingProfileImage = value;
      }
    }

    setState(() => update(true));
    modalSetState?.call(() => update(true));

    try {
      final File file = File(picked.path);
      final List<int> bytes = await file.readAsBytes();
      final String encoded = base64Encode(bytes);

      await _updateUserImages(
        profileData: isCover ? null : encoded,
        coverData: isCover ? encoded : null,
      );

      setState(() {
        if (isCover) {
          _coverImageData = encoded;
        } else {
          _profileImageData = encoded;
        }
      });
      modalSetState?.call(() {
        if (isCover) {
          _coverImageData = encoded;
        } else {
          _profileImageData = encoded;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du traitement de l'image."),
          ),
        );
      }
    } finally {
      setState(() => update(false));
      modalSetState?.call(() => update(false));
    }
  }

  void _logout() async {
    await auth.FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  // Fonction pour ajouter un marqueur
  void _addMarker(LatLng position) {
    _showMarkerBottomSheet(position);
  }

  // Fonction pour supprimer un marqueur
  void _deleteMarker(String markerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('markers')
          .doc(markerId)
          .delete();

      // Stocker la position du marqueur avant de le supprimer
      LatLng? markerPosition;
      int markerIndex = _markers.indexWhere((marker) => marker.id == markerId);
      if (markerIndex != -1) {
        markerPosition = _markers[markerIndex].point;
      }

      setState(() {
        _markers.removeWhere((marker) => marker.id == markerId);
      });

      // Si possible, recentrer la carte sur un autre marqueur ou sur la position précédente
      if (_markers.isNotEmpty) {
        _mapController.move(_markers.first.point, _mapController.camera.zoom);
      } else if (markerPosition != null) {
        _mapController.move(markerPosition, _mapController.camera.zoom);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Marqueur supprimé avec succès")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la suppression du marqueur")),
        );
      }
    }
  }

  // Fonction pour afficher la bottom sheet pour modifier les informations de l'utilisateur
  void _showEditProfileBottomSheet() {
    final TextEditingController firstNameController = TextEditingController(
      text: _firstName,
    );
    final TextEditingController lastNameController = TextEditingController(
      text: _lastName,
    );
    final TextEditingController numTelController = TextEditingController(
      text: _numTel,
    );
    final TextEditingController numSiretController = TextEditingController(
      text: _numSiret,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: _description,
    );
    final TextEditingController addressController = TextEditingController(
      text: _address,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Modifier vos informations",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              "Photo de couverture",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_coverImageData != null &&
                                        _coverImageData!.trim().isNotEmpty)
                                      Image.memory(
                                        base64Decode(_coverImageData!),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              color: AppTheme.backgroundPeach,
                                            ),
                                      )
                                    else
                                      Container(
                                        color: AppTheme.backgroundPeach,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.image_outlined,
                                          color: AppTheme.primaryOrange,
                                          size: 40,
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                        ),
                                        label: const Text("Modifier"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            _isUploadingCoverImage
                                                ? null
                                                : () => _pickAndUploadImage(
                                                  isCover: true,
                                                  modalSetState: setModalState,
                                                ),
                                      ),
                                    ),
                                    if (_isUploadingCoverImage)
                                      Container(
                                        color: Colors.black.withOpacity(0.35),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Photo de profil",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildProfileAvatar(28),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text("Modifier"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed:
                                      _isUploadingProfileImage
                                          ? null
                                          : () => _pickAndUploadImage(
                                            isCover: false,
                                            modalSetState: setModalState,
                                          ),
                                ),
                                if (_isUploadingProfileImage)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Email: $_email",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: "Prénom",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: "Nom",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: numTelController,
                              decoration: InputDecoration(
                                labelText: "Numéro de téléphone",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: numSiretController,
                              decoration: InputDecoration(
                                labelText: "Numéro SIRET",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: addressController,
                              decoration: InputDecoration(
                                labelText: "Adresse",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check, color: Colors.white),
                        label: Text(
                          "Valider les modifications",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF9B44E),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          auth.User? user =
                              auth.FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({
                                  'firstName': firstNameController.text.trim(),
                                  'lastName': lastNameController.text.trim(),
                                  'numTel': numTelController.text.trim(),
                                  'numSiret': numSiretController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                });
                            await FirebaseFirestore.instance
                                .collection('publicProfiles')
                                .doc(user.uid)
                                .set({
                                  'firstName': firstNameController.text.trim(),
                                  'lastName': lastNameController.text.trim(),
                                  'numTel': numTelController.text.trim(),
                                  'address': addressController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                }, SetOptions(merge: true));

                            setState(() {
                              _firstName = firstNameController.text.trim();
                              _lastName = lastNameController.text.trim();
                              _numTel = numTelController.text.trim();
                              _numSiret = numSiretController.text.trim();
                              _address = addressController.text.trim();
                              _description = descriptionController.text.trim();
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Informations mises à jour avec succès",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Erreur lors de la mise à jour des informations",
                                  ),
                                ),
                              );
                            }
                          }

                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Fonction pour afficher la bottom sheet pour ajouter/modifier un marqueur
  void _showMarkerBottomSheet(LatLng position, [MarkerModel? existingMarker]) {
    final TextEditingController addressController = TextEditingController(
      text: existingMarker?.address ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: existingMarker?.description ?? '',
    );

    // Variable pour stocker l'adresse initiale et détecter les changements
    final String initialAddress = addressController.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingMarker != null
                              ? "Modifier le marqueur"
                              : "Ajouter un marqueur",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Text(
                              "Position: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: addressController,
                              decoration: InputDecoration(
                                labelText: "Adresse",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                                suffixIcon: Icon(
                                  Icons.location_on,
                                ), // Indicateur visuel que l'adresse sera géocodée
                              ),
                              onChanged: (value) {
                                // Attendre que l'utilisateur finisse de taper (debounce)
                                _debounce?.cancel();
                                _debounce = Timer(
                                  Duration(milliseconds: 500),
                                  () async {
                                    if (value.isNotEmpty) {
                                      try {
                                        List<geocoding.Location> locations =
                                            await geocoding.locationFromAddress(
                                              value,
                                            );
                                        if (locations.isNotEmpty) {
                                          // Mise à jour de la position avec les nouvelles coordonnées
                                          position = LatLng(
                                            locations.first.latitude,
                                            locations.first.longitude,
                                          );
                                          setModalState(() {});
                                          // Notification subtile (optionnelle)
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Coordonnées mises à jour",
                                              ),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // Gestion silencieuse des erreurs
                                        print(
                                          "Impossible de géocoder l'adresse: $e",
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            TextButton.icon(
                              icon: Icon(Icons.search_rounded, size: 16),
                              label: Text("Convertir l'adresse en coordonnées"),
                              onPressed: () async {
                                String address = addressController.text.trim();
                                if (address.isNotEmpty) {
                                  try {
                                    List<geocoding.Location> locations =
                                        await geocoding.locationFromAddress(
                                          address,
                                        );
                                    if (locations.isNotEmpty) {
                                      // Mise à jour de la position avec les nouvelles coordonnées
                                      position = LatLng(
                                        locations.first.latitude,
                                        locations.first.longitude,
                                      );

                                      setModalState(() {
                                        // Mettre à jour le texte de position dans la modal
                                      });

                                      // Notification de succès
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Adresse convertie en coordonnées avec succès",
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Impossible de convertir cette adresse",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment:
                          existingMarker != null
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                      children: [
                        if (existingMarker != null)
                          Expanded(
                            flex: 1,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.delete, color: Colors.white),
                              label: Text(
                                "Supprimer",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: Size(130, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteMarker(existingMarker.id);
                              },
                            ),
                          ),
                        SizedBox(width: existingMarker != null ? 16 : 0),
                        Expanded(
                          flex: existingMarker != null ? 2 : 1,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.check, color: Colors.white),
                            label: Text(
                              "Valider",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF9B44E),
                              minimumSize: Size(130, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              auth.User? user =
                                  auth.FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              String address = addressController.text.trim();
                              String description =
                                  descriptionController.text.trim();

                              if (existingMarker == null) {
                                // Ajouter un nouveau marqueur
                                try {
                                  DocumentReference docRef =
                                      await FirebaseFirestore.instance
                                          .collection('markers')
                                          .add({
                                            'latitude': position.latitude,
                                            'longitude': position.longitude,
                                            'address': address,
                                            'description': description,
                                            'userId': user.uid,
                                          });

                                  MarkerModel newMarker = MarkerModel(
                                    id: docRef.id,
                                    point: position,
                                    address: address,
                                    description: description,
                                    userId: user.uid,
                                  );

                                  setState(() {
                                    _markers.add(newMarker);
                                  });

                                  // Centrer la carte sur le nouveau marqueur
                                  _mapController.move(
                                    position,
                                    _mapController.camera.zoom,
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Marqueur ajouté avec succès",
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Erreur lors de l'ajout du marqueur",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Modifier un marqueur existant
                                try {
                                  // Si l'adresse a changé et qu'on n'a pas déjà mis à jour les coordonnées
                                  if (address != initialAddress &&
                                      position == existingMarker.point) {
                                    try {
                                      // Tenter de convertir la nouvelle adresse
                                      List<geocoding.Location> locations =
                                          await geocoding.locationFromAddress(
                                            address,
                                          );
                                      if (locations.isNotEmpty) {
                                        position = LatLng(
                                          locations.first.latitude,
                                          locations.first.longitude,
                                        );
                                      }
                                    } catch (e) {
                                      // En cas d'erreur, garder les coordonnées d'origine
                                      print(
                                        "Impossible de convertir l'adresse: $e",
                                      );
                                    }
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('markers')
                                      .doc(existingMarker.id)
                                      .update({
                                        'latitude': position.latitude,
                                        'longitude': position.longitude,
                                        'address': address,
                                        'description': description,
                                      });

                                  setState(() {
                                    // Trouver et mettre à jour le marqueur localement
                                    int index = _markers.indexWhere(
                                      (m) => m.id == existingMarker.id,
                                    );
                                    if (index != -1) {
                                      _markers[index].point = position;
                                      _markers[index].address = address;
                                      _markers[index].description = description;
                                    }
                                  });

                                  // Centrer la carte sur le marqueur mis à jour
                                  _mapController.move(
                                    position,
                                    _mapController.camera.zoom,
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Marqueur mis à jour avec succès",
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Erreur lors de la mise à jour du marqueur",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }

                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: Column(
        children: [
          _buildProHeader(padding.top),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _buildProMap()),
                _buildAddMarkerButton(padding.bottom),
                _buildProfileSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProHeader(double topInset) {
    final ImageProvider? coverImage = _imageFromBase64(_coverImageData);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        height: 220 + topInset,
        color: AppTheme.primaryOrange,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  coverImage != null
                      ? DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: coverImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      : Container(color: AppTheme.primaryOrange),
            ),
            if (coverImage != null)
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            Positioned(
              top: topInset + 12,
              right: 12,
              child: _ImageEditButton(
                isLoading: _isUploadingCoverImage,
                onPressed: () => _pickAndUploadImage(isCover: true),
              ),
            ),
            Positioned(
              top: topInset + 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.exit_to_app, color: AppTheme.white),
                onPressed: _logout,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      _buildProfileAvatar(40),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _ImageEditButton(
                          isMini: true,
                          isLoading: _isUploadingProfileImage,
                          onPressed: () => _pickAndUploadImage(isCover: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _firstName.isNotEmpty || _lastName.isNotEmpty
                              ? '$_firstName $_lastName'
                              : (_email.isNotEmpty ? _email : 'Professionnel'),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _address.isNotEmpty
                              ? _address
                              : 'Adresse à renseigner',
                          style: TextStyle(
                            color: AppTheme.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-21.1151, 55.5364),
        initialZoom: 10.0,
        onTap: (tapPosition, point) {
          _addMarker(point);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.chicken_grills.app',
          maxZoom: 18,
        ),
        MarkerLayer(
          markers:
              _markers.map((marker) {
                return Marker(
                  point: marker.point,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showMarkerBottomSheet(marker.point, marker),
                    child: Image.asset('assets/images/chicken-marker.png'),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddMarkerButton(double bottomInset) {
    return Positioned(
      bottom: bottomInset + 100,
      left: 0,
      right: 0,
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_location, color: Colors.white),
          label: const Text(
            "Ajouter un marqueur",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => _addMarker(const LatLng(-21.1151, 55.5364)),
        ),
      ),
    );
  }

  Widget _buildProfileSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Informations du profil",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9B44E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFFF9B44E),
                              ),
                              onPressed: _showEditProfileBottomSheet,
                              tooltip: "Modifier vos informations",
                              iconSize: 20,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.2),
                      thickness: 1,
                      height: 25,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProfileOverviewCard(),
                    _buildContactCard(),
                    _buildProfessionalCard(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildProfileAvatar(32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _firstName.isNotEmpty || _lastName.isNotEmpty
                      ? '$_firstName $_lastName'
                      : (_email.isNotEmpty ? _email : 'Nom à renseigner'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Coordonnées",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, "Téléphone", _numTel),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, "Adresse", _address),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informations professionnelles",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.business, "Numéro SIRET", _numSiret),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.description, "Description", _description),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(double radius) {
    final ImageProvider? image = _imageFromBase64(_profileImageData);
    if (image != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.secondaryOrange.withOpacity(0.2),
        backgroundImage: image,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.secondaryOrange.withOpacity(0.2),
      child: Text(
        _profileInitials(),
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  String _profileInitials() {
    final String name =
        [
          _firstName,
          _lastName,
        ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (name.isEmpty) {
      return _email.isNotEmpty ? _email.substring(0, 1).toUpperCase() : '?';
    }
    final parts = name.split(' ');
    final String first = parts.first.substring(0, 1);
    final String last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  ImageProvider? _imageFromBase64(String? data) {
    if (data == null) return null;
    final String trimmed = data.trim();
    if (trimmed.isEmpty) return null;
    try {
      final bytes = base64Decode(trimmed);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
