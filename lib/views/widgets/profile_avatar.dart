import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.radius = 20,
    this.onTap,
  });

  /// Single source of truth for which picture to show.
  /// Priority: FirebaseAuth.photoURL -> users.photoUrl -> users.imageUrl.
  static String resolvePhotoUrl({
    String? authPhotoUrl,
    String? firestorePhotoUrl,
    String? firestoreImageUrl,
  }) {
    if (authPhotoUrl != null && authPhotoUrl.trim().isNotEmpty) {
      return authPhotoUrl.trim();
    }
    if (firestorePhotoUrl != null && firestorePhotoUrl.trim().isNotEmpty) {
      return firestorePhotoUrl.trim();
    }
    if (firestoreImageUrl != null && firestoreImageUrl.trim().isNotEmpty) {
      return firestoreImageUrl.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUserProvider = context.watch<FirebaseUserProvider>();
    final currentUser = firebaseUserProvider.currentUser;
    final displayName = auth.displayName ?? currentUser?.fullname ?? 'User';
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();
    final imageUrl = resolvePhotoUrl(
      authPhotoUrl: auth.firebaseUser?.photoURL,
      firestorePhotoUrl: currentUser?.photoUrl,
      firestoreImageUrl: currentUser?.imageUrl,
    );

    Widget avatar;
    if (imageUrl.isEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    } else {
      // Key forces a fresh image when the URL changes (cache-busted URLs
      // still need a new widget so CircleAvatar drops the old in-memory art).
      // CachedNetworkImageProvider handles caching/retries better than
      // raw NetworkImage and shows the initial while loading/failing.
      avatar = CircleAvatar(
        key: ValueKey<String>('avatar_$imageUrl'),
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
