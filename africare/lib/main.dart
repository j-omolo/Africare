import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:africare/app/routes/app_routes.dart';
import 'package:africare/app/theme/app_theme.dart';
import 'package:africare/app/controllers/auth_controller.dart';
import 'package:africare/app/controllers/appointment_controller.dart';
import 'package:africare/app/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  await NotificationService().initialize();
  
  // Initialize controllers
  Get.put(AuthController());
  Get.put(AppointmentController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Africare',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
