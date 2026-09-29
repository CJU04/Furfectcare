import 'package:vetcare_connect/views/widgets/dashboard_action_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/appointment_provider.dart';
import 'package:vetcare_connect/providers/pet_provider.dart';
import 'package:vetcare_connect/providers/medical_history_provider.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class VeterinarianDashboardScreen extends StatefulWidget {
  const VeterinarianDashboardScreen({super.key});

  @override
  State<VeterinarianDashboardScreen> createState() =>
      _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState
    extends State<VeterinarianDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<FirebaseUserProvider>().loadUsers();
    context.read<AppointmentProvider>().loadAppointments();
    context.read<PetProvider>().loadPets();
    context.read<MedicalHistoryProvider>().loadMedicalHistories();
  }

  List<Appointment> _getAppointmentsForDay(
    DateTime day,
    List<Appointment> appointments,
  ) {
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
    final firebaseUserProvider = context.watch<FirebaseUserProvider>();
    final currentUser = firebaseUserProvider.currentUser;

    final appointmentProvider = context.watch<AppointmentProvider>();

    final petProvider = context.watch<PetProvider>();

    final medicalHistoryProvider = context.watch<MedicalHistoryProvider>();

    // Vet sees only their assigned appointments
    final String todayStr = DateTime.now().toString().split(' ')[0];
    final List<Appointment> myAppointments = currentUser?.uid == null
        ? <Appointment>[]
        : appointmentProvider.appointments
            .where((appt) => appt.assignedUserId.toString() == currentUser?.uid)
            .toList();

    final todayAppointments = myAppointments.where((appt) {
      return appt.date == todayStr;
    }).toList();

    final totalPets = petProvider.pets.length;

    final totalMedicalRecords = medicalHistoryProvider.medicalHistories.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Veterinarian Dashboard',
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(
        currentRoute: '/veterinarian',
      ),
      body: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final isWide = constraints.maxWidth > 600;
          final maxWidth = isWide ? 1000.0 : double.infinity;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Dr. ${auth.displayName ?? currentUser?.fullname ?? 'Veterinarian'}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Here\'s your schedule for today',
                            style: TextStyle(
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
                          'Today\'s Appointments',
                          todayAppointments.length.toString(),
                          Icons.calendar_today,
                          Colors.blue,
                          onTap: () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                        _buildStatCard(
                          'Pending',
                          myAppointments
                              .where((appt) => appt.status == 'pending')
                              .length
                              .toString(),
                          Icons.pending_actions,
                          Colors.orange,
                          onTap: () => Navigator.pushNamed(
                              context, '/appointment_management'),
                        ),
                        _buildStatCard(
                          'Total Pets',
                          totalPets.toString(),
                          Icons.pets,
                          Colors.green,
                          onTap: () =>
                              Navigator.pushNamed(context, '/pet_management'),
                        ),
                        _buildStatCard(
                          'Medical Records',
                          totalMedicalRecords.toString(),
                          Icons.medical_services,
                          Colors.teal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/medical_history'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

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
                          'Appointments',
                          Icons.calendar_today,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/appointment_management',
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Pet Records',
                          Icons.pets,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/pet_management',
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Medical History',
                          Icons.history,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/medical_history',
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Fuzzy Assessment',
                          Icons.analytics_rounded,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/fuzzy_assessment',
                            );
                          },
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
                            eventLoader: (day) =>
                                _getAppointmentsForDay(day, myAppointments),
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
                                    context, _selectedDay, myAppointments),
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

  Widget _buildTimeSlotGrid(BuildContext context, DateTime? selectedDay,
      List<Appointment> appointments) {
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

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    // Get assigned veterinarian/staff from users
    String assignedTo = 'Unassigned';
    if (appointment.assignedUserId != null &&
        appointment.assignedUserId!.isNotEmpty) {
      final firebaseUserProvider =
          Provider.of<FirebaseUserProvider>(context, listen: false);
      final assignedUser = firebaseUserProvider.users
          .where((u) => u.uid == appointment.assignedUserId)
          .firstOrNull;
      if (assignedUser != null) {
        assignedTo = '${assignedUser.name} (${assignedUser.role.value})';
      } else {
        // User not found in list, show the ID
        assignedTo = 'User: ${appointment.assignedUserId}';
      }
    }

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
              _detailRow('Date', appointment.date),
              _detailRow('Status', appointment.status),
              _detailRow('Assigned To', assignedTo),
              if (appointment.assignedUserId != null)
                _detailRow('Assigned ID', appointment.assignedUserId),
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

  Widget _detailRow(String label, String? value) {
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
            child: Text(value ?? '-', style: const TextStyle(fontSize: 13)),
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
