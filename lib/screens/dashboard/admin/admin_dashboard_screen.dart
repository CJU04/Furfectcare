import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  void _loadData() {
    Provider.of<FirebaseUserProvider>(context, listen: false).loadUsers();
    Provider.of<AppointmentProvider>(context, listen: false).loadAppointments();
    Provider.of<PetProvider>(context, listen: false).loadPets();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
    Provider.of<SalesProvider>(context, listen: false).loadSales();
  }

  List<Appointment> _getAppointmentsForDay(DateTime day, List<Appointment> appointments) {
    return appointments.where((appointment) {
      try {
        final appointmentDate = DateTime.parse(appointment.date);
        return appointmentDate.year == day.year &&
            appointmentDate.month == day.month &&
            appointmentDate.day == day.day;
      } catch (e) {
        return false;
      }
    }).toList();
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
    final totalRevenue = salesProvider.sales.fold<double>(0, (sum, s) => sum + (s.totalAmount ?? 0));

    // Pending approvals count
    final pendingApprovals = firebaseUserProvider.users.where((u) => !u.approved && u.role.value != 'admin').length;
    // Confirmed appointments today
    final today = DateTime.now();
    final confirmedToday = appointmentProvider.appointments.where((a) {
      try {
        final date = DateTime.parse(a.date);
        return date.year == today.year && date.month == today.month && date.day == today.day && a.status == 'confirmed';
      } catch (e) { return false; }
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: const [],
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
                            style: const TextStyle(
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
                        ),
                        _buildStatCard(
                          'Total Pets',
                          totalPets.toString(),
                          Icons.pets,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Appointments',
                          totalAppointments.toString(),
                          Icons.calendar_today,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Products',
                          totalProducts.toString(),
                          Icons.inventory_2,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Total Sales',
                          totalSales.toString(),
                          Icons.point_of_sale,
                          Colors.teal,
                        ),
                        _buildStatCard(
                          'Revenue',
                          _formatCurrency(totalRevenue),
                          Icons.attach_money,
                          Colors.green.shade700,
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          pendingApprovals.toString(),
                          Icons.pending_actions,
                          Colors.amber,
                        ),
                        _buildStatCard(
                          'Today Confirmed',
                          confirmedToday.toString(),
                          Icons.check_circle,
                          Colors.green.shade600,
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
                          () => Navigator.pushNamed(context, '/user_management'),
                        ),
                        _buildActionButton(
                          context,
                          'Appointments',
                          Icons.calendar_today,
                          () => Navigator.pushNamed(context, '/appointment_management'),
                        ),
                        _buildActionButton(
                          context,
                          'Products',
                          Icons.inventory_2,
                          () => Navigator.pushNamed(context, '/product_inventory'),
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

                    const SizedBox(height: 24),

                    // Recent Activity
                    Row(
                      children: [
                        const Icon(Icons.history, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: firebaseUserProvider.users.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Column(
                              children: firebaseUserProvider.users
                                  .take(5)
                                  .map((user) => _buildActivityTile(context, user))
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Appointment Calendar
                    const Text(
                      'Appointment Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          TableCalendar<Appointment>(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            calendarFormat: _calendarFormat,
                            eventLoader: (day) => _getAppointmentsForDay(day, appointmentProvider.appointments),
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 3,
                              markerDecoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                              formatButtonDecoration: BoxDecoration(
                                border: Border.all(color: AppTheme.primaryGreen),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Appointments for ${_selectedDay != null ? DateFormat('MMMM d, yyyy').format(_selectedDay!) : 'Today'}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                _buildTimeSlotGrid(context, _selectedDay, appointmentProvider.appointments),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTimeSlotGrid(BuildContext context, DateTime? selectedDay, List<Appointment> appointments) {
    final dayAppointments = selectedDay != null
        ? _getAppointmentsForDay(selectedDay, appointments)
        : <Appointment>[];

    // Define time slots from 8 AM to 6 PM
    final timeSlots = [
      '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
      '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM',
      '4:00 PM', '5:00 PM', '6:00 PM',
    ];

    // Map appointments to their time slots
    final occupiedSlots = <String, Appointment>{};
    for (var apt in dayAppointments) {
      final timeKey = _normalizeTime(apt.time);
      if (timeKey != null) {
        occupiedSlots[timeKey] = apt;
      }
    }

    return SizedBox(
      height: 220,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final slot = timeSlots[index];
          final appointment = occupiedSlots[slot];
          final isOccupied = appointment != null;

          return InkWell(
            onTap: () {
              if (isOccupied) {
                _showAppointmentDetails(context, appointment);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isOccupied
                    ? _getStatusColor(appointment.status).withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOccupied
                      ? _getStatusColor(appointment.status)
                      : Colors.green.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isOccupied ? _getStatusColor(appointment.status) : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOccupied ? _getStatusText(appointment.status) : 'Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOccupied ? _getStatusColor(appointment.status) : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _normalizeTime(String? time) {
    if (time == null) return null;
    final cleaned = time.trim().toUpperCase();

    // We only need the appointment slot by hour.
    // Inputs we expect from booking UI: "HH:mm:00" (24h) or "h:mm AM/PM".

    // 1) Handle 24h time like "14:30:00" or "14:30"
    final time24h = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');
    final m24 = time24h.firstMatch(cleaned);
    if (m24 != null) {
      final hour = int.tryParse(m24.group(1) ?? '');
      if (hour == null) return null;
      // Map hour to our display slots (8:00 AM ... 6:00 PM). For non-exact minutes,
      // we still map to the containing hour.
      return _hourToSlot(hour);
    }

    // 2) Handle AM/PM formats like "10:30 AM" or "10:30:00 AM" (best-effort)
    final timeAmPm = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)$');
    final mAmPm = timeAmPm.firstMatch(cleaned.replaceAll(' ', ''));
    if (mAmPm != null) {
      final hour12 = int.tryParse(mAmPm.group(1) ?? '');
      final ampm = mAmPm.group(3);
      if (hour12 == null || ampm == null) return null;
      final hour24 = (ampm == 'AM')
          ? (hour12 == 12 ? 0 : hour12)
          : (hour12 == 12 ? 12 : hour12 + 12);
      return _hourToSlot(hour24);
    }

    // Fallback: try to find an exact slot key inside the string
    final slots = const <String>[
      '8:00 AM',
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '1:00 PM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
      '6:00 PM',
    ];

    for (final slot in slots) {
      if (cleaned.contains(slot.toUpperCase())) return slot;
    }

    return null;
  }

  String? _hourToSlot(int hour24) {
    // Our grid is 8 AM - 6 PM (inclusive hours)
    // Map hour24 directly:
    // 08 -> 8:00 AM ... 11 -> 11:00 AM, 12 -> 12:00 PM, 13 -> 1:00 PM ... 18 -> 6:00 PM
    if (hour24 < 8 || hour24 > 18) return null;

    if (hour24 == 12) return '12:00 PM';
    if (hour24 == 0) return '8:00 AM'; // shouldn't happen given range check
    if (hour24 < 12) return '${hour24}:00 AM';
    return '${hour24 - 12}:00 PM';
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Occupied';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Reason', appointment.reason),
              _detailRow('Time', appointment.time ?? '-'),
              _detailRow('Status', appointment.status),
              _detailRow('Date', appointment.date),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/appointment_management');
            },
            child: const Text('View in Appointments'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/user_management'),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullname,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getRoleColor(user.usertype).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.usertype,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user.usertype),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
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
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 28.0),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    // Format as Philippine Pesos (PHP) without decimals when possible.
    // If you prefer a different currency symbol/text, adjust here.
    final intValue = amount.round();
    return '₱${intValue.toString()}';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.primaryGreen;
      case 'veterinarian':
        return Colors.teal;
      case 'staff':
        return Colors.indigo;
      case 'petowner':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

