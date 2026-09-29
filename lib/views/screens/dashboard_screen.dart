import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/views/widgets/profile_avatar.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.role;
    if (role == null) return;
    if (role.value == 'customer') {
      final uid = authProvider.firebaseUser?.uid;
      if (uid != null) {
        Provider.of<PetProvider>(context, listen: false).loadPetsForOwner(uid);
        Provider.of<AppointmentProvider>(context, listen: false)
            .loadAppointmentsForOwner(uid);
      }
    } else {
      Provider.of<PetProvider>(context, listen: false).loadPets();
      Provider.of<AppointmentProvider>(context, listen: false)
          .loadAppointments();
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<SalesProvider>(context, listen: false).loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final salesProvider = Provider.of<SalesProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;
    final role = authProvider.role;
    final isCustomer = role?.value == 'customer';
    final isAdmin = role?.value == 'admin';
    final isStaff = role?.value == 'staff';
    final isVet = role?.value == 'veterinarian';

    final totalPets = petProvider.pets.length;
    final todaysAppointments = appointmentProvider.appointments.length;
    final lowStockProducts =
        productProvider.products.where((p) => p.stockQuantity < 10).length;
    final totalSales = salesProvider.sales.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          ProfileAvatar(
            radius: 16,
            onTap: () => Navigator.pushNamed(context, '/profile_settings'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossAxisCount = isWide ? 4 : 2;
          final quickActionCrossAxisCount = isWide ? 3 : 2;
          final maxWidth = isWide ? 1200.0 : double.infinity;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Text(
                      'Welcome back, ${authProvider.displayName ?? currentUser?.fullname ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metrics Grid - responsive
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.5 : 1.2,
                      children: [
                        _buildMetricCard(
                          isCustomer ? 'My Pets' : 'Total Pets',
                          totalPets.toString(),
                          Icons.pets,
                          Colors.teal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/pet_management'),
                        ),
                        _buildMetricCard(
                          isCustomer
                              ? 'My Appointments'
                              : "Today's Appointments",
                          todaysAppointments.toString(),
                          Icons.calendar_today,
                          Colors.blue,
                          onTap: () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                        if (!isCustomer && (isAdmin || isStaff))
                          _buildMetricCard(
                            'Low Stock Products',
                            lowStockProducts.toString(),
                            Icons.inventory,
                            Colors.orange,
                            onTap: () => Navigator.pushNamed(
                                context, '/product_inventory'),
                          ),
                        if (!isCustomer && (isAdmin || isStaff))
                          _buildMetricCard(
                            'Total Sales',
                            totalSales.toString(),
                            Icons.point_of_sale,
                            AppTheme.primaryGreen,
                            onTap: () =>
                                Navigator.pushNamed(context, '/sales_pos'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions Section
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: quickActionCrossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.2 : 1.3,
                      children: isCustomer
                          ? [
                              _buildQuickActionCard(
                                context,
                                'My Pets',
                                Icons.pets,
                                () => Navigator.pushNamed(
                                    context, '/pet_management'),
                              ),
                              _buildQuickActionCard(
                                context,
                                'Book Appointment',
                                Icons.calendar_today,
                                () => Navigator.pushNamed(
                                    context, '/appointment_management'),
                              ),
                              _buildQuickActionCard(
                                context,
                                'Medical History',
                                Icons.medical_services,
                                () => Navigator.pushNamed(
                                    context, '/medical_history'),
                              ),
                              _buildQuickActionCard(
                                context,
                                'Products',
                                Icons.inventory,
                                () => Navigator.pushNamed(
                                    context, '/product_inventory'),
                              ),
                            ]
                          : isAdmin
                              ? [
                                  _buildQuickActionCard(
                                    context,
                                    'Manage Pets',
                                    Icons.pets,
                                    () => Navigator.pushNamed(
                                        context, '/pet_management'),
                                  ),
                                  _buildQuickActionCard(
                                    context,
                                    'Appointments',
                                    Icons.calendar_today,
                                    () => Navigator.pushNamed(
                                        context, '/appointment_management'),
                                  ),
                                  _buildQuickActionCard(
                                    context,
                                    'Medical Records',
                                    Icons.medical_services,
                                    () => Navigator.pushNamed(
                                        context, '/medical_history'),
                                  ),
                                  _buildQuickActionCard(
                                    context,
                                    'Inventory',
                                    Icons.inventory,
                                    () => Navigator.pushNamed(
                                        context, '/product_inventory'),
                                  ),
                                  _buildQuickActionCard(
                                    context,
                                    'Sales POS',
                                    Icons.point_of_sale,
                                    () => Navigator.pushNamed(
                                        context, '/sales_pos'),
                                  ),
                                  _buildQuickActionCard(
                                    context,
                                    'Reports',
                                    Icons.bar_chart,
                                    () => Navigator.pushNamed(
                                        context, '/reports'),
                                  ),
                                ]
                              : isVet
                                  ? [
                                      _buildQuickActionCard(
                                        context,
                                        'Manage Pets',
                                        Icons.pets,
                                        () => Navigator.pushNamed(
                                            context, '/pet_management'),
                                      ),
                                      _buildQuickActionCard(
                                        context,
                                        'Appointments',
                                        Icons.calendar_today,
                                        () => Navigator.pushNamed(
                                            context, '/appointment_management'),
                                      ),
                                      _buildQuickActionCard(
                                        context,
                                        'Medical Records',
                                        Icons.medical_services,
                                        () => Navigator.pushNamed(
                                            context, '/medical_history'),
                                      ),
                                    ]
                                  : isStaff
                                      ? [
                                          _buildQuickActionCard(
                                            context,
                                            'Products',
                                            Icons.inventory,
                                            () => Navigator.pushNamed(
                                                context, '/product_inventory'),
                                          ),
                                          _buildQuickActionCard(
                                            context,
                                            'Sales POS',
                                            Icons.point_of_sale,
                                            () => Navigator.pushNamed(
                                                context, '/sales_pos'),
                                          ),
                                          _buildQuickActionCard(
                                            context,
                                            'Reports',
                                            Icons.bar_chart,
                                            () => Navigator.pushNamed(
                                                context, '/reports'),
                                          ),
                                        ]
                                      : [],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreenLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/pet_management'),
          icon: const Icon(
            Icons.add,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3,
      shadowColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      shadowColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
