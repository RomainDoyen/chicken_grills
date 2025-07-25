import 'dart:async';
import 'package:chicken_grills/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:chicken_grills/services/auth_service.dart';
import 'package:chicken_grills/models/user_model.dart';
import 'package:chicken_grills/models/marker.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class ProHomePage extends StatefulWidget {
  const ProHomePage({super.key});

  @override
  _ProHomePageState createState() => _ProHomePageState();
}

class _ProHomePageState extends State<ProHomePage> {
  String _email = "";
  String _firstName = "";
  String _lastName = "";
  String _numTel = "";
  String _numSiret = "";
  String _description = "";
  String _address = "";
  final AuthService _authService = AuthService();

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
            color: Color(0xFFF9B44E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Color(0xFFF9B44E)),
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
                            SizedBox(height: 20),
                            Text(
                              "Email: $_email",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: "Prénom",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: "Nom",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: 16),
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
                            SizedBox(height: 16),
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
    return Scaffold(
      backgroundColor: Color(0xFFEEF2FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec les détails de l'utilisateur et le bouton de déconnexion
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bienvenue $_firstName",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.exit_to_app, color: Colors.red),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(-21.1151, 55.5364),
                        initialZoom: 10.0,
                        onTap: (tapPosition, point) {
                          _addMarker(point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                          userAgentPackageName: 'com.chicken_grills.app',
                          maxZoom: 18,
                        ),
                        MarkerLayer(
                          markers:
                              _markers.map((marker) {
                                return Marker(
                                  point: marker.point,
                                  width: 40.0,
                                  height: 40.0,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showMarkerBottomSheet(
                                        marker.point,
                                        marker,
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/images/chicken-marker.png',
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Bouton d'ajout de marqueur
                  Positioned(
                    bottom:
                        100, // Position plus haute pour éviter le chevauchement avec le DraggableScrollableSheet
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add_location, color: Colors.white),
                        label: Text(
                          "Ajouter un marqueur",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF9B44E),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => _addMarker(LatLng(-21.1151, 55.5364)),
                      ),
                    ),
                  ),

                  // DraggableScrollableSheet pour les informations de profil
                  DraggableScrollableSheet(
                    initialChildSize:
                        0.2, // Taille initiale (juste l'en-tête visible)
                    minChildSize: 0.1, // Taille minimale
                    maxChildSize: 0.7, // Taille maximale
                    builder: (
                      BuildContext context,
                      ScrollController scrollController,
                    ) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: Offset(0, -3),
                            ),
                          ],
                        ),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: <Widget>[
                            // En-tête fixe avec poignée de glissement
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 8),
                                  // Poignée de glissement
                                  Container(
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Informations du profil",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFFF9B44E,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Color(0xFFF9B44E),
                                            ),
                                            onPressed:
                                                _showEditProfileBottomSheet,
                                            tooltip:
                                                "Modifier vos informations",
                                            iconSize: 20,
                                            padding: EdgeInsets.all(8),
                                            constraints: BoxConstraints(),
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

                            // Contenu défilable
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  // Informations personnelles
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    margin: EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.05),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Color(
                                                0xFFF9B44E,
                                              ).withOpacity(0.2),
                                              radius: 20,
                                              child: Icon(
                                                Icons.person,
                                                color: Color(0xFFF9B44E),
                                              ),
                                            ),
                                            SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "$_firstName $_lastName",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF333333),
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    _email,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Coordonnées
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    margin: EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.05),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Coordonnées",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF444444),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        _buildInfoRow(
                                          Icons.phone,
                                          "Téléphone",
                                          _numTel,
                                        ),
                                        SizedBox(height: 12),
                                        _buildInfoRow(
                                          Icons.location_on,
                                          "Adresse",
                                          _address,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Informations professionnelles
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    margin: EdgeInsets.only(bottom: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.05),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Informations professionnelles",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF444444),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        _buildInfoRow(
                                          Icons.business,
                                          "Numéro SIRET",
                                          _numSiret,
                                        ),
                                        SizedBox(height: 12),
                                        _buildInfoRow(
                                          Icons.description,
                                          "Description",
                                          _description,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Espace supplémentaire en bas pour le défilement
                                  SizedBox(height: 20),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
