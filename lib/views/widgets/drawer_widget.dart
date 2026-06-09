import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/routes/app_router.dart';

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;
    final displayName = auth.displayName ?? currentUser?.fullname ?? 'Guest';
    final userEmail = auth.firebaseUser?.email ?? currentUser?.email ?? '';
    final role = auth.role;
    final isAdmin = role?.value == 'admin';
    final isCustomer = role?.value == 'customer';
    // Get photo URL from Firebase Auth user or from Firestore user profile
    final photoUrl = auth.firebaseUser?.photoURL ?? currentUser?.photoUrl ?? currentUser?.imageUrl ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            currentAccountPicture: photoUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    backgroundImage: CachedNetworkImageProvider(photoUrl),
                  )
                : CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    child: Text(
                      displayName.trim().isNotEmpty
                          ? displayName.trim()[0].toUpperCase()
                          : 'G',
                      style: const TextStyle(
                        fontSize: 30,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          _buildDrawerItem(
            context,
            'Dashboard',
            Icons.dashboard,
            _getDashboardRoute(role),
            isSelected: _isOnDashboard,
          ),
          if (isAdmin)
            _buildDrawerItem(context, 'User Management', Icons.people, AppRouter.userManagementRoute),
          _buildDrawerItem(context, 'Pets', Icons.pets, AppRouter.petManagementRoute),
          if (!isCustomer)
            _buildDrawerItem(context, 'Medical History', Icons.medical_services, AppRouter.medicalHistoryRoute),
          _buildDrawerItem(context, 'Appointments', Icons.calendar_today, AppRouter.appointmentManagementRoute),
          if (isCustomer)
            _buildDrawerItem(context, 'Product Catalog', Icons.shopping_bag, AppRouter.productCatalogRoute),
          if (!isCustomer) ...[
            _buildDrawerItem(context, 'Products', Icons.inventory_2, AppRouter.productInventoryRoute),
            _buildDrawerItem(context, 'Sales / POS', Icons.point_of_sale, AppRouter.salesPosRoute),
            _buildDrawerItem(context, 'Inventory Logs', Icons.inventory, AppRouter.inventoryLogsRoute),
            _buildDrawerItem(context, 'Reports', Icons.bar_chart, AppRouter.reportsRoute),
          ],
          const Divider(),
          _buildDrawerItem(context, 'Settings', Icons.settings, AppRouter.settingsRoute),
          _buildDrawerItem(context, 'Profile', Icons.person, AppRouter.profileSettingsRoute),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.primaryGreen),
            title: const Text('Logout'),
            onTap: () => _showLogoutDialog(context, auth),
          ),
        ],
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
        // Check if we're already on this route before closing drawer
        if (currentRoute == route) {
          Navigator.pop(context); // Just close the drawer
          return;
        }
        // Close drawer, then navigate to the new route
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  static void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
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
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
