import 'package:flutter_test/flutter_test.dart';
import 'package:vetcare_connect/models/appointment.dart';
import 'package:vetcare_connect/utils/appointment_slot_offer_selector.dart';

void main() {
  Appointment booking(
    String id,
    String time, {
    String status = 'confirmed',
    String date = '2026-10-01',
    String? owner,
  }) =>
      Appointment(
        appointmentId: id,
        petId: 'pet-$id',
        ownerUid: owner ?? id,
        date: date,
        time: time,
        reason: 'Checkup',
        status: status,
      );

  final cancelled = booking('cancelled', '09:00', status: 'cancelled');
  Appointment? select(
    List<Appointment> appointments, {
    Set<String> declined = const {},
    DateTime? now,
    Appointment? source,
  }) =>
      AppointmentSlotOfferSelector.nextCandidate(
        cancelledAppointment: source ?? cancelled,
        appointments: appointments,
        now: now ?? DateTime(2026, 10, 1, 8),
        declinedOwnerUids: declined,
      );

  test('selects earliest later scheduled booking without mutating input', () {
    final later = booking('later', '11:00');
    final next = booking('next', '09:30', status: 'scheduled');
    final input = [later, cancelled, next];
    expect(select(input), same(next));
    expect(input, [later, cancelled, next]);
    expect(next.time, '09:30');
  });

  test('skips declined customers and cancelling owner', () {
    final next = booking('next', '11:00');
    expect(
        select([
          booking('same-owner', '09:30', owner: 'cancelled'),
          booking('declined', '10:00', owner: 'customer'),
          booking('another-pet', '10:30', owner: 'customer'),
          next,
        ], declined: {
          'customer'
        }),
        same(next));
  });

  test('excludes pending, terminal, earlier and next-day appointments', () {
    expect(
        select([
          booking('pending', '09:30', status: 'pending'),
          booking('complete', '10:00', status: 'completed'),
          booking('rejected', '11:00', status: 'rejected'),
          booking('earlier', '08:00'),
          booking('tomorrow', '09:30', date: '2026-10-02'),
        ]),
        isNull);
  });

  test('blocks occupied and overlapping slots including pending bookings', () {
    for (final time in ['08:45', '09:00', '09:15']) {
      expect(
          select([
            booking('occupied', time, status: 'pending'),
            booking('next', '10:00'),
          ]),
          isNull,
          reason: time);
    }
    expect(
        select([booking('adjacent', '08:30'), booking('next', '09:30')])
            ?.appointmentId,
        'next');
  });

  test('rejects stale cancellation snapshots and non-cancelled source', () {
    expect(
        select([
          cancelled.copyWith(status: 'confirmed'),
          booking('next', '10:00')
        ]),
        isNull);
    expect(
        select([booking('next', '10:00')],
            source: cancelled.copyWith(status: 'pending')),
        isNull);
  });

  test('rejects past slots and slots starting now', () {
    for (final now in [DateTime(2026, 10, 1, 9), DateTime(2026, 10, 2)]) {
      expect(select([booking('next', '10:00')], now: now), isNull);
    }
  });

  test('rejects malformed source dates and times', () {
    for (final source in [
      cancelled.copyWith(date: '2026-02-31'),
      cancelled.copyWith(date: ''),
      cancelled.copyWith(time: '24:00'),
      cancelled.copyWith(time: '09:60'),
      cancelled.copyWith(time: ''),
    ]) {
      expect(select([booking('next', '10:00')], source: source), isNull);
    }
  });

  test('uncertain active time blocks an offer on the same day', () {
    expect(select([booking('broken', 'invalid'), booking('next', '10:00')]),
        isNull);
  });

  test('excludes missing identifiers and resolves tied times deterministically',
      () {
    final a = booking('a', '10:00');
    final b = booking('b', '10:00');
    expect(
        select([
          booking('', '09:30'),
          booking('no-owner', '09:30', owner: ''),
          b,
          a
        ]),
        same(a));
    expect(select([a, b]), same(a));
  });

  test('accepts legacy ISO dates and cancellation status aliases', () {
    expect(
        select([booking('next', '10:00', date: '2026-10-01T00:00:00.000')],
                source: cancelled.copyWith(status: 'canceled'))
            ?.appointmentId,
        'next');
    expect(select([]), isNull);
  });
}
