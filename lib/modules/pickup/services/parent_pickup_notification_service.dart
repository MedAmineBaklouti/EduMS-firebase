import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:edums/modules/auth/service/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../models/pickup_model.dart';

class ParentPickupNotificationService extends GetxService {
  final DatabaseService _db = Get.find();
  final AuthService _auth = Get.find();

  StreamSubscription? _authSubscription;
  StreamSubscription? _ticketsSubscription;

  final Set<String> _notifiedTicketIds = <String>{};
  bool _notificationSeeded = false;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.user.listen(_handleAuthChange);
    final parentId = _auth.currentUser?.uid;
    if (parentId != null) {
      _startListening(parentId);
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.onClose();
  }

  void _handleAuthChange(User? user) {
    _clearSubscriptions();
    if (user?.uid != null) {
      _startListening(user!.uid);
    }
  }

  void _startListening(String parentId) {
    _ticketsSubscription = _db.firestore
        .collection('pickupTickets')
        .snapshots()
        .listen((snapshot) {
      final tickets = snapshot.docs.map(PickupTicketModel.fromDoc).toList();
      _checkTicketNotifications(parentId, tickets);
    });
  }

  void _clearSubscriptions() {
    _ticketsSubscription?.cancel();
    _ticketsSubscription = null;
    _notifiedTicketIds.clear();
    _notificationSeeded = false;
  }

  void _checkTicketNotifications(
    String parentId,
    List<PickupTicketModel> items,
  ) {
    final validatedTickets = items.where((ticket) {
      if (ticket.parentId != parentId) {
        return false;
      }
      final validated =
          ticket.teacherValidatedAt != null || ticket.adminValidatedAt != null;
      if (!validated) {
        return false;
      }
      return true;
    }).toList();

    if (!_notificationSeeded) {
      _notifiedTicketIds
        ..clear()
        ..addAll(validatedTickets.map((ticket) => ticket.id));
      _notificationSeeded = true;
      return;
    }

    for (final ticket in validatedTickets) {
      if (_notifiedTicketIds.contains(ticket.id)) {
        continue;
      }
      _notifiedTicketIds.add(ticket.id);
      Future.microtask(() {
        if (Get.isDialogOpen ?? false) {
          return;
        }

        final overlayContext = Get.overlayContext ?? Get.context;
        if (overlayContext == null) {
          return;
        }

        showDialog<void>(
          context: overlayContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Pickup update'),
            content: Text(
              '${ticket.childName} is on the way to you. Thank you for your patience!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }
}
