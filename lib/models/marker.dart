import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class MarkerModel {
  final String id;
  late final LatLng point;
  String address;
  String description;
  final String userId;

  MarkerModel({
    required this.id,
    required this.point,
    required this.address,
    required this.description,
    required this.userId,
  });

  factory MarkerModel.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return MarkerModel(
      id: doc.id,
      point: LatLng(data['latitude'], data['longitude']),
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'],
    );
  }
}