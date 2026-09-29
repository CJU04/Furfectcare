import 'package:vetcare_connect/views/widgets/dashboard_action_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/utils/helpers.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/views/widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load after the first frame: notifyListeners() during build throws
    // "setState() or markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<FirebaseUserProvider>(context, listen: false).loadUsers();
    Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
    Provider.of<PetProvider>(context, listen: false).loadPets();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
    Provider.of<SalesProvider>(context, listen: false).loadSales();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);

    final totalUsers = firebaseUserProvider.users.length;
    final totalAppointments = appointmentProvider.appointments.length;
    final totalPets = petProvider.pets.length;
    final totalProducts = productProvider.products.length;
    final totalSales = salesProvider.sales.length;
    final totalRevenue =
        salesProvider.sales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    // Pending approvals count
    final pendingApprovals = firebaseUserProvider.users
        .where((u) => !u.approved && u.role.value != 'admin')
        .length;
    // Confirmed appointments today
    final today = DateTime.now();
    final confirmedToday = appointmentProvider.appointments.where((a) {
      try {
        final date = DateTime.parse(a.date);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day &&
            a.status == 'confirmed';
      } catch (e) {
        return false;
      }
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: const [NotificationBell()],
      ),
      drawer: const AppDrawer(currentRoute: '/admin'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final maxWidth = isWide ? 1000.0 : double.infinity;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${auth.displayName ?? currentUser?.fullname ?? 'Administrator'} (Administrator)!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your clinic from here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats - 2 columns grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildStatCard(
                          'Total Users',
                          totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, '/user_management'),
                        ),
                        _buildStatCard(
                          'Total Pets',
                          totalPets.toString(),
                          Icons.pets,
                          Colors.orange,
                          onTap: () =>
                              Navigator.pushNamed(context, '/pet_management'),
                        ),
                        _buildStatCard(
                          'Appointments',
                          totalAppointments.toString(),
                          Icons.calendar_today,
                          Colors.green,
                          onTap: () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                        _buildStatCard(
                          'Products',
                          totalProducts.toString(),
                          Icons.inventory_2,
                          Colors.purple,
                          onTap: () => Navigator.pushNamed(
                              context, '/product_inventory'),
                        ),
                        _buildStatCard(
                          'Total Sales',
                          totalSales.toString(),
                          Icons.point_of_sale,
                          Colors.teal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/sales_pos'),
                        ),
                        _buildStatCard(
                          'Revenue',
                          _formatCurrency(totalRevenue),
                          Icons.attach_money,
                          Colors.green.shade700,
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          pendingApprovals.toString(),
                          Icons.pending_actions,
                          Colors.amber,
                          onTap: () =>
                              Navigator.pushNamed(context, '/user_management'),
                        ),
                        _buildStatCard(
                          'Today Scheduled',
                          confirmedToday.toString(),
                          Icons.check_circle,
                          Colors.green.shade600,
                          onTap: () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          context,
                          'Manage Users',
                          Icons.person_add,
                          () =>
                              Navigator.pushNamed(context, '/user_management'),
                        ),
                        _buildActionButton(
                          context,
                          'Appointments',
                          Icons.calendar_today,
                          () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                        _buildActionButton(
                          context,
                          'Products',
                          Icons.inventory_2,
                          () => Navigator.pushNamed(
                              context, '/product_inventory'),
                        ),
                        _buildActionButton(
                          context,
                          'Sales / POS',
                          Icons.point_of_sale,
                          () => Navigator.pushNamed(context, '/sales_pos'),
                        ),
                        _buildActionButton(
                          context,
                          'Reports',
                          Icons.bar_chart,
                          () => Navigator.pushNamed(context, '/reports'),
                        ),
                        _buildActionButton(
                          context,
                          'Inventory Logs',
                          Icons.inventory,
                          () => Navigator.pushNamed(context, '/inventory_logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24.0, color: color),
              const SizedBox(height: 6.0),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return DashboardActionTile(label: label, icon: icon, onTap: onTap);
  }

  String _formatCurrency(double amount) {
    return Formatters.formatCurrency(amount);
  }
}
