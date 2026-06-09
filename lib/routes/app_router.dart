import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../views/screens/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/admin/admin_dashboard_screen.dart';
import '../screens/dashboard/customer/customer_dashboard_screen.dart';
import '../screens/dashboard/staff/staff_dashboard_screen.dart';
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
import '../views/screens/profile_settings_screen.dart';
import '../views/screens/dashboard_screen.dart';
import '../views/screens/product_catalog_screen.dart';

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
          if (auth.role != null && auth.role != UserRole.admin) return const AccessDeniedScreen();
          return const AdminDashboardScreen();
        });
      case customerDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null or matches customer
          if (auth.role != null && auth.role != UserRole.customer) return const AccessDeniedScreen();
          return const CustomerDashboardScreen();
        });
      case staffDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null or matches staff
          if (auth.role != null && auth.role != UserRole.staff) return const AccessDeniedScreen();
          return const StaffDashboardScreen();
        });
      case veterinarianDashboardRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          // Allow access if role is null (still loading) - dashboard will load its own data
          // Block only if role is explicitly set to something other than veterinarian
          if (auth.role != null && auth.role != UserRole.veterinarian) return const AccessDeniedScreen();
          return const VeterinarianDashboardScreen();
        });
      case userManagementRoute:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case petManagementRoute:
        return MaterialPageRoute(builder: (_) => const PetManagementScreen());
      case medicalHistoryRoute:
        return MaterialPageRoute(builder: (context) {
          final auth = context.watch<AuthProvider>();
          if (!auth.isSignedIn) return const LoginScreen();
          if (auth.role != null && auth.role != UserRole.admin &&
              auth.role != UserRole.staff && auth.role != UserRole.veterinarian) {
            return const AccessDeniedScreen();
          }
          return const MedicalHistoryScreen();
        });
      case salesPosRoute:
        return MaterialPageRoute(builder: (_) => const SalesPosScreen());
      case inventoryLogsRoute:
        return MaterialPageRoute(builder: (_) => const InventoryLogsScreen());
      case reportsRoute:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case appointmentManagementRoute:
        return MaterialPageRoute(builder: (_) => const AppointmentManagementScreen());
      case productInventoryRoute:
        return MaterialPageRoute(builder: (_) => const ProductInventoryScreen());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case profileSettingsRoute:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case productCatalogRoute:
        return MaterialPageRoute(builder: (_) => const ProductCatalogScreen());
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

