import 'package:flutter/material.dart';

import '../../../data/models/announcement_model.dart';

class AnnouncementDetailView extends StatelessWidget {
  final AnnouncementModel announcement;

  AnnouncementDetailView({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(announcement.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(announcement.description),
      ),
    );
  }
}
