import 'package:get/get.dart';

import '../controllers/edu_chat_controller.dart';
import '../services/edu_chat_service.dart';

class EduChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EduChatService>(() => EduChatService(), fenix: true);
    Get.lazyPut<EduChatController>(() => EduChatController(), fenix: true);
  }
}
