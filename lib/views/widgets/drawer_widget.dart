import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/routes/app_router.dart';
import 'package:vetcare_connect/views/widgets/profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  String _getDashboardRoute(UserRole? role) {
    switch (role?.value) {
      case 'customer':
        return AppRouter.customerDashboardRoute;
      case 'staff':
        return AppRouter.staffDashboardRoute;
      case 'veterinarian':
        return AppRouter.veterinarianDashboardRoute;
      case 'admin':
      default:
        return AppRouter.adminDashboardRoute;
    }
  }

  bool get _isOnDashboard {
    return currentRoute == AppRouter.customerDashboardRoute ||
        currentRoute == AppRouter.staffDashboardRoute ||
        currentRoute == AppRouter.veterinarianDashboardRoute ||
        currentRoute == AppRouter.adminDashboardRoute ||
        currentRoute == '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUserProvider = context.watch<FirebaseUserProvider>();
    final currentUser = firebaseUserProvider.currentUser;
    final displayName = auth.displayName ?? currentUser?.fullname ?? 'Guest';
    final userEmail = auth.firebaseUser?.email ?? currentUser?.email ?? '';
    final role = auth.role;
    final isAdmin = role?.value == 'admin';
    final isCustomer = role?.value == 'customer';
    // Same priority as ProfileAvatar: Auth photoURL wins, then Firestore
    // photoUrl, then legacy imageUrl. Drawer previously ignored two of
    // these, so it showed the initial even when a picture existed.
    final photoUrl = ProfileAvatar.resolvePhotoUrl(
      authPhotoUrl: auth.firebaseUser?.photoURL,
      firestorePhotoUrl: currentUser?.photoUrl,
      firestoreImageUrl: currentUser?.imageUrl,
    );

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AppTheme.primaryGreen,
            child: Column(
              children: [
                const SizedBox(height: 48),
                _ProfileAvatar(photoUrl: photoUrl, displayName: displayName),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            'Dashboard',
            Icons.dashboard,
            _getDashboardRoute(role),
            isSelected: _isOnDashboard,
          ),
          if (isAdmin ||
              role?.value == 'staff' ||
              role?.value == 'veterinarian')
            _buildDrawerItem(context, 'User Management', Icons.people,
                AppRouter.userManagementRoute),
          _buildDrawerItem(
              context, 'Pets', Icons.pets, AppRouter.petManagementRoute),
          if (!isCustomer)
            _buildDrawerItem(context, 'Medical History', Icons.medical_services,
                AppRouter.medicalHistoryRoute),
          _buildDrawerItem(context, 'Appointments', Icons.calendar_today,
              AppRouter.appointmentManagementRoute),
          if (isCustomer)
            _buildDrawerItem(context, 'Products', Icons.shopping_bag,
                AppRouter.productCatalogRoute),
          _buildDrawerItem(context, 'Products History', Icons.history,
              AppRouter.productHistoryRoute,
              isSelected: currentRoute == '/product_history'),
          if (!isCustomer) ...[
            const Divider(),
            _buildDrawerSectionHeader('Documents'),
            _buildDrawerItem(
              context,
              'Medical Documents',
              Icons.folder_open,
              AppRouter.medicalDocumentsRoute,
              isSelected: currentRoute == '/medical_documents',
            ),
          ],
          const Divider(),
          _buildDrawerItem(
            context,
            'Notifications',
            Icons.notifications,
            AppRouter.notificationCenterRoute,
            isSelected: currentRoute == '/notifications',
          ),
          if (!isCustomer) ...[
            _buildDrawerItem(context, 'Products', Icons.inventory_2,
                AppRouter.productInventoryRoute),
            _buildDrawerItem(context, 'Sales / POS', Icons.point_of_sale,
                AppRouter.salesPosRoute),
            _buildDrawerItem(context, 'Inventory Logs', Icons.inventory,
                AppRouter.inventoryLogsRoute),
            _buildDrawerItem(
                context, 'Reports', Icons.bar_chart, AppRouter.reportsRoute),
          ],
          const Divider(),
          _buildDrawerItem(
              context, 'Settings', Icons.settings, AppRouter.settingsRoute),
          _buildDrawerItem(
              context, 'Profile', Icons.person, AppRouter.profileSettingsRoute),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryGreen),
            title: const Text('Logout'),
            onTap: () => _showLogoutDialog(context, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF2E7D32).withValues(alpha: 0.10),
      onTap: () {
        if (currentRoute == route) {
          Navigator.pop(context);
          return;
        }
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  static void _showLogoutDialog(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (r) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final String displayName;

  const _ProfileAvatar({required this.photoUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final hasUrl = photoUrl.isNotEmpty;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'G';

    if (!hasUrl) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: Colors.white,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 32,
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Keyed by URL so a newly uploaded picture actually replaces the old
    // CircleAvatar art instead of Flutter reusing the cached render.
    return CircleAvatar(
      key: ValueKey<String>('drawer_avatar_$photoUrl'),
      radius: 44,
      backgroundColor: Colors.white,
      backgroundImage: CachedNetworkImageProvider(photoUrl),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }
}
