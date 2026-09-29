import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class AppInitProvider extends ChangeNotifier {
  bool isLoading = true;
  String? errorMessage;

  AppInitProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      errorMessage = null;
    } on FirebaseException catch (e) {
      errorMessage =
          'We couldn\'t connect to the service. Please check your connection and try again.';
      debugPrint('Firebase init error: ${e.message}');
    } catch (e) {
      errorMessage =
          'Something went wrong while starting the app. Please try again.';
      debugPrint('Firebase init error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Re-runs initialization after a failed startup (used by the splash Retry button).
  Future<void> retry() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await _init();
  }
}
