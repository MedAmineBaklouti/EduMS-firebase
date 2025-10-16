import 'package:get/get.dart';

import 'package:edums/modules/auth/service/auth_service.dart';

class TeacherController extends GetxController {
  final AuthService _authService = Get.find();
  final RxBool isLoading = false.obs;

  static TeacherController get to => Get.find();

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> logout() async {
    try {
      isLoading(true);
      await _authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Logout failed: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }
}