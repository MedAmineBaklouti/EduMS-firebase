import 'package:get/get.dart';

import 'bindings.dart';
import 'views/edu_chat_view.dart';

abstract class EduChatRoutes {
  static const chat = '/edu-chat';

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: chat,
      page: () => const EduChatView(),
      binding: EduChatBindings(),
    ),
  ];
}
