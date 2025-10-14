import 'package:get/get.dart';

import 'controllers/edu_chat_controller.dart';
import 'services/edu_chat_service.dart';

class EduChatBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EduChatService>(() => EduChatService());
    Get.lazyPut<EduChatController>(
      () => EduChatController(Get.find<EduChatService>()),
    );
  }
}
