import 'package:flutter/material.dart';

/// Clinic hours + holiday/closure configuration.
///
/// - Booking hours are strictly 08:00-16:00 (last slot starts 15:30).
/// - Sundays are closed by default, plus Philippine regular holidays.
/// - Staff/admins can add one-off closure dates which instantly disable
///   that date (and every slot on it) across booking UIs.
class ClinicHours {
  ClinicHours._();

  static const int openHour = 8;
  static const int closeHour = 16;
  static const Duration slotLength = Duration(minutes: 30);
  static const int maxBookingsPerDay = 16;

  /// Sundays closed by default (weekday == DateTime.sunday).
  static bool isWeeklyClosure(DateTime day) => day.weekday == DateTime.sunday;

  /// Fixed Philippine regular holidays (month/day). Add observed dates in
  /// [extraClosures]. Year-agnostic on purpose so they recur annually.
  static const Set<String> _holidays = {
    '01-01', // New Year's Day
    '04-09', // Araw ng Kagitingan
    '05-01', // Labor Day
    '06-12', // Independence Day
    '11-30', // Bonifacio Day
    '12-25', // Christmas Day
    '12-30', // Rizal Day
  };

  static bool isHoliday(DateTime day) {
    final key =
        '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _holidays.contains(key);
  }

  static bool isClosedDay(DateTime day, {Set<String>? extraClosures}) {
    if (isWeeklyClosure(day) || isHoliday(day)) return true;
    if (extraClosures == null || extraClosures.isEmpty) return false;
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return extraClosures.contains(key);
  }

  static String closureReason(DateTime day, {Set<String>? extraClosures}) {
    if (isHoliday(day)) return 'Holiday — clinic closed';
    if (isWeeklyClosure(day)) return 'Closed on Sundays';
    if (extraClosures != null) {
      final key =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (extraClosures.contains(key)) return 'Clinic closed on this date';
    }
    return '';
  }

  /// All bookable start times for a day (08:00 … 15:30).
  static List<TimeOfDay> dailySlots() {
    final slots = <TimeOfDay>[];
    var minutes = openHour * 60;
    final endMinutes = closeHour * 60;
    while (minutes < endMinutes) {
      slots.add(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
      minutes += slotLength.inMinutes;
    }
    return slots;
  }

  static String formatSlot(TimeOfDay slot) {
    final h = slot.hour.toString().padLeft(2, '0');
    final m = slot.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// First N slots that are taken are removed; remaining ones stay enabled.
  static List<TimeOfDay> freeSlots(Set<String> takenHhMm) =>
      dailySlots().where((s) => !takenHhMm.contains(formatSlot(s))).toList();
}

/// Small animated helpers: loading shimmer rows, scale-in modal popups,
/// and a red-dot "new" badge for latest updates.
class AppAnimations {
  AppAnimations._();

  static Future<T?> showScaleDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => builder(context),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static Widget loadingRow({int lines = 3}) {
    return Column(
      children: List.generate(
        lines,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: Duration(milliseconds: 700 + i * 150),
            builder: (_, value, __) => Opacity(
              opacity: value,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Red dot badge shown on notification icons / cards with fresh updates.
  static Widget redDot({int? count, double size = 10}) {
    if (count != null && count <= 0) return const SizedBox.shrink();
    return Container(
      padding: count == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: count == null
          ? null
          : Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
