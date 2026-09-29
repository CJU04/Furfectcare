import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../views/screens/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/admin/admin_dashboard_screen.dart';
import '../screens/dashboard/customer/customer_dashboard_screen.dart';
import '../screens/dashboard/staff/staff_dashboard_screen.dart';
import '../algorithms/ui/fuzzy_assessment.dart';
import '../screens/dashboard/veterinarian/veterinarian_dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../views/screens/access_denied_screen.dart';
import '../views/screens/user_management_screen.dart';
import '../views/screens/pet_management_screen.dart';
import '../views/screens/medical_history_screen.dart';
import '../views/screens/sales_pos_screen.dart';
import '../views/screens/inventory_logs_screen.dart';
import '../views/screens/reports_screen.dart';
import '../views/screens/appointment_management_screen.dart';
import '../views/screens/product_inventory_screen.dart';
import '../views/screens/settings_screen.dart';
import '../views/screens/notification_center_screen.dart';
import '../views/screens/profile_settings_screen.dart';
import '../views/screens/dashboard_screen.dart';
import '../views/screens/product_catalog_screen.dart';
import '../views/screens/product_history_screen.dart';
import '../views/screens/medical_documents_screen.dart';

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';

  static const String adminDashboardRoute = '/admin';
  static const String customerDashboardRoute = '/customer';
  static const String staffDashboardRoute = '/staff';
  static const String veterinarianDashboardRoute = '/veterinarian';

  static const String userManagementRoute = '/user_management';
  static const String petManagementRoute = '/pet_management';
  static const String medicalHistoryRoute = '/medical_history';
  static const String salesPosRoute = '/sales_pos';
  static const String inventoryLogsRoute = '/inventory_logs';
  static const String reportsRoute = '/reports';
  static const String appointmentManagementRoute = '/appointment_management';
  static const String productInventoryRoute = '/product_inventory';
  static const String settingsRoute = '/settings';
  static const String profileSettingsRoute = '/profile_settings';
  static const String dashboardRoute = '/dashboard';
  static const String productCatalogRoute = '/product_catalog';
  static const String productHistoryRoute = '/product_history';
  static const String fuzzyAssessmentRoute = '/fuzzy_assessment';
  static const String notificationCenterRoute = '/notifications';
  static const String medicalDocumentsRoute = '/medical_documents';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case adminDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null or matches admin
          if (auth.role != null && auth.role != UserRole.admin)
            return const AccessDeniedScreen();
          return const AdminDashboardScreen();
        });
      case customerDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null or matches customer
          if (auth.role != null && auth.role != UserRole.customer)
            return const AccessDeniedScreen();
          return const CustomerDashboardScreen();
        });
      case staffDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null or matches staff
          if (auth.role != null && auth.role != UserRole.staff)
            return const AccessDeniedScreen();
          return const StaffDashboardScreen();
        });
      case veterinarianDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null (still loading) - dashboard will load its own data
          // Block only if role is explicitly set to something other than veterinarian
          if (auth.role != null && auth.role != UserRole.veterinarian)
            return const AccessDeniedScreen();
          return const VeterinarianDashboardScreen();
        });
      case fuzzyAssessmentRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != null && auth.role != UserRole.veterinarian)
            return const AccessDeniedScreen();
          return const FuzzyAssessmentScreen();
        });
      case userManagementRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != null && auth.role != UserRole.admin)
            return const AccessDeniedScreen();
          return const UserManagementScreen();
        });
      case petManagementRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const PetManagementScreen();
        });
      case medicalHistoryRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != null &&
              auth.role != UserRole.admin &&
              auth.role != UserRole.staff &&
              auth.role != UserRole.veterinarian) {
            return const AccessDeniedScreen();
          }
          return const MedicalHistoryScreen();
        });
      case salesPosRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role == UserRole.customer) return const AccessDeniedScreen();
          return const SalesPosScreen();
        });
      case inventoryLogsRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != UserRole.staff &&
              auth.role != UserRole.admin &&
              auth.role != UserRole.veterinarian)
            return const AccessDeniedScreen();
          return const InventoryLogsScreen();
        });
      case reportsRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != UserRole.staff &&
              auth.role != UserRole.admin &&
              auth.role != UserRole.veterinarian)
            return const AccessDeniedScreen();
          return const ReportsScreen();
        });
      case appointmentManagementRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return AppointmentManagementScreen(
              recordId: settings.arguments is Map
                  ? (settings.arguments as Map)['recordId'] as String?
                  : null);
        });
      case productInventoryRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const ProductInventoryScreen();
        });
      case settingsRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const SettingsScreen();
        });
      case profileSettingsRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const ProfileSettingsScreen();
        });
      case productCatalogRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const ProductCatalogScreen();
        });
      case productHistoryRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return ProductHistoryScreen(
              recordId: settings.arguments is Map
                  ? (settings.arguments as Map)['recordId'] as String?
                  : null);
        });
      case notificationCenterRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const NotificationCenterScreen();
        });
      case medicalDocumentsRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Medical documents are staff-facing only; customers manage
          // vaccination proofs from their pet records instead.
          if (auth.role != null &&
              auth.role != UserRole.admin &&
              auth.role != UserRole.staff &&
              auth.role != UserRole.veterinarian) {
            return const AccessDeniedScreen();
          }
          return const MedicalDocumentsScreen();
        });
      case dashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          return const DashboardScreen();
        });

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
