import 'package:baseer/first_sceens/splash_screen.dart';
import 'package:baseer/first_sceens/welcome_screen.dart';
import 'package:baseer/notifications/notifications_screen.dart';
import 'package:baseer/pharmacist_screens/pharmacist_home.dart';
import 'package:baseer/pharmacist_screens/view_patients.dart';
import 'package:baseer/reports_screen.dart';
import 'package:baseer/user_screens/edit_medical_report.dart';
import 'package:baseer/user_screens/medical_report.dart';
import 'package:baseer/user_screens/medication_reminder_screen.dart';
import 'package:baseer/user_screens/scan_screen.dart';
import 'package:baseer/user_screens/user_home.dart';
import 'package:baseer/user_screens/view_medicines_screen.dart';
import 'package:baseer/user_screens/view_pharmacists.dart';
import 'package:flutter/material.dart';
import 'auth_screeens/ProfileScreen.dart';
import 'admin_screens/admin_home.dart';
import 'admin_screens/admin_notification.dart';
import 'admin_screens/user_info.dart';
import 'admin_screens/view_users.dart';
import 'auth_screeens/forget_password_screen.dart';
import 'auth_screeens/login_screen.dart';
import 'auth_screeens/register_screen.dart';
import 'chat_screen.dart';

class UserInfoArgs {
  final String userId;
  final Map<String, dynamic> userData;

  UserInfoArgs({required this.userId, required this.userData});
}
class PharmacistInfoArgs {
  final String userId;
  final Map<String, dynamic> userData;

  PharmacistInfoArgs({required this.userId, required this.userData});
}

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgetPassword = '/forgetPassword';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String pharmacistHome = '/pharmacistHome';
  static const String userHome = '/userHome';
  static const String viewUsers = '/viewUsers';
  static const String viewPatient = '/viewPatient';
  static const String scanMedicine = '/scanMedicine';
  static const String viewPharmacists = '/viewPatient';
  static const String viewPharmacist = '/viewPharmacist';
  static const String medicalReport = '/medicalReport';
  static const String editMedicalReport = '/editMedicalReport';
  static const String userInfoScreen = '/userInfoScreen';
  static const String viewMedicines = '/viewMedicines';
  static const String medicationReminder = '/medicationReminder';
  static const String chatScreen = '/chatScreen';
  static const String calenderScreen = '/calenderScreen';
  static const adminNotifications = '/adminNotifications';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    welcome: (context) => const WelcomeScreen(),
    profile: (context) => const ProfileScreen(),
    admin: (context) => const AdminDashboard(),
    splash: (context) => const SplashScreen(),
    register: (context) => const SignUpScreen(),
    forgetPassword: (context) => const ForgotPasswordScreen(),
    userHome: (context) => const UserDashboardScreen(),
    pharmacistHome: (context) => const PharmacistDashboardScreen(),
    viewUsers: (context) => const PharmacistListScreen(),
    viewPatient: (context) => const AllPatientsScreen(),
    viewPharmacist: (context) => const PharmacistScreen(),
    medicalReport : (context) => const MedicalReportScreen(),
    editMedicalReport  : (context) => const EditMedicalReportScreen(),
    userInfoScreen: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as UserInfoArgs;
      return UserInfoScreen(
        userId: args.userId,
        userData: args.userData,
      );
    },
    chatScreen  : (context) => const ChatsListScreen(),
    calenderScreen  : (context) => const CalendarScreen(),
    viewMedicines: (context) => const ViewMedicinesScreen(),
    medicationReminder: (context) => const MedicationReminderScreen(),
     adminNotifications: (context) => const AdminNotificationsScreen(),
    notifications: (context) => const NotificationsScreen(),
    scanMedicine: (context) => const ScanMedicineScreen(),

  };
}
