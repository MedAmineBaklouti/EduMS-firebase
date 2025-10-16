import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  NetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final RxBool _isOnline = true.obs;
  StreamSubscription<dynamic>? _subscription;

  bool get isOnline => _isOnline.value;

  Future<void> init() async {
    final status = await _connectivity.checkConnectivity();
    await _handleStatusChange(status, initial: true);

    _subscription =
        _connectivity.onConnectivityChanged.listen(_handleStatusChange);
  }

  Future<void> _handleStatusChange(dynamic status,
      {bool initial = false}) async {
    final connected = _isConnected(status);

    if (connected == null) {
      if (Get.isLogEnable) {
        Get.log('Unknown connectivity status type: ${status.runtimeType}');
      }
      return;
    }

    if (!initial && connected == _isOnline.value) {
      return;
    }

    _isOnline.value = connected;

    try {
      if (connected) {
        await FirebaseFirestore.instance.enableNetwork();
      } else {
        await FirebaseFirestore.instance.disableNetwork();
      }
    } catch (error) {
      // Ignore errors caused by repeated enable/disable calls.
      if (Get.isLogEnable) {
        Get.log('Network toggle failed: $error');
      }
    }
  }

  bool? _isConnected(dynamic status) {
    if (status is ConnectivityResult) {
      return status != ConnectivityResult.none;
    }

    if (status is List<ConnectivityResult>) {
      return status.any((result) => result != ConnectivityResult.none);
    }

    return null;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
