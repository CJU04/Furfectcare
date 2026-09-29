import 'package:vetcare_connect/views/widgets/dashboard_action_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/models/pet.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/utils/appointment_scheduling.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/views/widgets/notification_bell.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FirebaseUserProvider>(context, listen: false).loadUsers();
      Provider.of<PetProvider>(context, listen: false).loadPets();
      Provider.of<AppointmentProvider>(context, listen: false)
          .loadAppointments();
    });
  }

  List<Appointment> _getAppointmentsForDay(
      DateTime day, List<Appointment> appointments) {
    return appointments.where((appointment) {
      try {
        final appointmentDate = DateTime.parse(appointment.date);
        return appointmentDate.year == day.year &&
            appointmentDate.month == day.month &&
            appointmentDate.day == day.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firebaseUserProvider = Provider.of<FirebaseUserProvider>(context);
    final currentUser = firebaseUserProvider.currentUser;

    final petProvider = context.watch<PetProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();

    final String? uid = currentUser?.uid;

    // Filter to customer's own data only
    final List<Pet> myPets = uid == null
        ? <Pet>[]
        : petProvider.pets.where((pet) => pet.ownerUid == uid).toList();

    // Keep myAppointments for “My appointments” and viewing details.
    final List<Appointment> myAppointments = uid == null
        ? <Appointment>[]
        : appointmentProvider.appointments
            .where((appt) => appt.ownerUid == uid)
            .toList();

    // Occupancy should be computed from ALL appointments so customers see
    // real availability, but the UI will only show appointment details for
    // their own appointments.
    final List<Appointment> allAppointments = appointmentProvider.appointments;

    final int totalPets = myPets.length;
    final int totalAppointments = myAppointments.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: const [NotificationBell()],
      ),
      drawer: const AppDrawer(currentRoute: '/customer'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 600;
          final double maxWidth = isWide ? 1000.0 : double.infinity;

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
                            'Welcome, ${auth.displayName ?? currentUser?.fullname ?? 'Customer'}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your pets and appointments',
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
                          'My Pets',
                          totalPets.toString(),
                          Icons.pets,
                          Colors.orange,
                          onTap: () =>
                              Navigator.pushNamed(context, '/pet_management'),
                        ),
                        _buildStatCard(
                          'My Appointments',
                          totalAppointments.toString(),
                          Icons.calendar_today,
                          Colors.blue,
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
                          'My Pets',
                          Icons.pets,
                          () => Navigator.pushNamed(context, '/pet_management'),
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
                          Icons.shopping_bag,
                          () =>
                              Navigator.pushNamed(context, '/product_catalog'),
                        ),
                      ],
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
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            calendarFormat: _calendarFormat,
                            // Mark every day that has ANY booking (all
                            // customers) so busy/available days are visible.
                            eventLoader: (day) =>
                                _getAppointmentsForDay(day, allAppointments),
                            startingDayOfWeek: StartingDayOfWeek.monday,
                            calendarStyle: const CalendarStyle(
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
                                border:
                                    Border.all(color: AppTheme.primaryGreen),
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
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                _buildTimeSlotGrid(
                                  context,
                                  _selectedDay,
                                  // Use all appointments to mark occupied slots correctly.
                                  allAppointments,
                                  myUid: uid,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    _legendDot(Colors.green, 'Available'),
                                    _legendDot(Colors.red, 'Occupied (locked)'),
                                    _legendDot(Colors.orange, 'Pending'),
                                    _legendDot(Colors.blue, 'Your booking'),
                                  ],
                                ),
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

  Widget _buildTimeSlotGrid(
    BuildContext context,
    DateTime? selectedDay,
    List<Appointment> appointments, {
    required String? myUid,
  }) {
    final dayAppointments = selectedDay != null
        ? _getAppointmentsForDay(selectedDay, appointments)
        : <Appointment>[];

    final timeSlots = [
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
          // Only pending/confirmed bookings occupy a slot. Finished records
          // (completed/cancelled/rejected) free the slot up again.
          final isOccupied = appointment != null &&
              AppointmentStatus.isActive(appointment.status);
          final isMine = appointment != null && appointment.ownerUid == myUid;

          return InkWell(
            // Occupied slots are automatically disabled for other customers:
            // they cannot be opened or interacted with. Own bookings and
            // free slots remain tappable (own bookings show details).
            onTap: isOccupied && !isMine
                ? null
                : () {
                    if (isOccupied) {
                      _showAppointmentDetails(context, appointment,
                          myUid: myUid);
                    }
                  },

            child: Container(
              decoration: BoxDecoration(
                color: isOccupied
                    ? _getStatusColor(appointment.status)
                        .withValues(alpha: 0.15)
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
                      color: isOccupied
                          ? _getStatusColor(appointment.status)
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOccupied
                        ? _getStatusText(appointment.status)
                        : 'Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOccupied
                          ? _getStatusColor(appointment.status)
                          : Colors.green,
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  String? _normalizeTime(String? time) {
    if (time == null) return null;
    final cleaned = time.trim().toUpperCase();

    final time24h = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');
    final m24 = time24h.firstMatch(cleaned);
    if (m24 != null) {
      final hour = int.tryParse(m24.group(1) ?? '');
      if (hour == null) return null;
      return _hourToSlot(hour);
    }

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
    if (hour24 < 8 || hour24 > 18) return null;
    if (hour24 == 12) return '12:00 PM';
    if (hour24 == 0) return '8:00 AM';
    if (hour24 < 12) return '$hour24:00 AM';
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

  void _showAppointmentDetails(
    BuildContext context,
    Appointment appointment, {
    required String? myUid,
  }) {
    // Privacy check: only show details for own appointments
    final bool isOwnAppointment =
        myUid != null && appointment.ownerUid == myUid;

    if (!isOwnAppointment) {
      // Show generic occupied message for other customers' appointments
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Slot'),
          content: const Text(
              'This time slot is occupied by another customer. Appointment details are private.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final petProvider = context.read<PetProvider>();

    final pet =
        petProvider.pets.where((p) => p.petId == appointment.petId).isNotEmpty
            ? petProvider.pets.firstWhere((p) => p.petId == appointment.petId)
            : null;

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
              _detailRow('Time', appointment.time),
              _detailRow('Status', appointment.status),
              _detailRow('Date', appointment.date),
              _detailRow(
                  'Pet', pet != null ? '${pet.name} (${pet.type})' : 'Unknown'),
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
}
