import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxBool isInitialized = false.obs;

  Future<DatabaseService> init() async {
    // Configure any Firestore settings if needed
    // await _firestore.settings = const Settings(...);

    isInitialized.value = true;
    return this;
  }

  // Firestore instance getter for direct access when needed
  FirebaseFirestore get firestore => _firestore;
}