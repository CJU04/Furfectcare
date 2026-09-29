import 'package:flutter_test/flutter_test.dart';

/// The appointment service now dispatches all mutations through the
/// `saveAppointment` HTTPS callable (verified by
/// functions/test/scheduling_concurrency.test.js against the Firestore
/// emulator, plus `flutter analyze` for the Dart-side wiring).
///
/// A `flutter test` cannot reach the callable without mocking Firebase's
/// pigeon method channel, which only re-tests Firebase's own plumbing, so no
/// unit test lives here. If you add a pure decision function to the service,
/// test it directly in this file without Firebase mocks.
void main() {
  test('placeholder to keep this suite discoverable', () {
    expect(true, isTrue);
  });
}
