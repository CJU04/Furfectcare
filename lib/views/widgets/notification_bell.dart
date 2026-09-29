import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/models/user.dart';

/// Bell icon with a red-dot unread badge. Place in the upper-right corner
/// of every dashboard/AppBar so all roles see latest updates at a glance.
class NotificationBell extends StatefulWidget {
  final Color iconColor;
  final Stream<List<AppNotification>> Function(String uid)? notificationStream;
  const NotificationBell(
      {super.key, this.iconColor = Colors.white, this.notificationStream});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;
  String? _uid;
  StreamSubscription<List<AppNotification>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.watch<AuthProvider>().firebaseUser?.uid ?? '';
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _unread = 0;
    if (uid.isEmpty) return;
    final stream = widget.notificationStream?.call(uid) ??
        DatabaseService().watchNotificationsForUser(uid);
    _subscription = stream.listen((items) {
      if (!mounted || _uid != uid) return;
      setState(() => _unread = items.where((n) => !n.isRead).length);
    }, onError: (Object error) {
      if (!mounted || _uid != uid) return;
      setState(() => _unread = 0);
      debugPrint('Notification subscription failed: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications_outlined, color: widget.iconColor),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (_unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: Text(_unread > 99 ? '99+' : '$_unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
