import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/service.dart';

class ServiceRepository {
  final CollectionReference _servicesCollection =
  FirebaseFirestore.instance.collection('services');

  Future<String> addService(Service service) async {
    try {
      final docRef = await _servicesCollection.add(service.toMap());
      await _servicesCollection.doc(docRef.id).update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add service: $e');
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await _servicesCollection.doc(service.id).update(service.toMap());
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _servicesCollection.doc(serviceId).delete();
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  Future<List<Service>> getServices() async {
    try {
      final querySnapshot = await _servicesCollection.get();
      return querySnapshot.docs
          .map((doc) => Service.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get services: $e');
    }
  }
}