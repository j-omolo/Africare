import 'package:get/get.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/doctor/doctor_details_screen.dart';
import '../screens/appointment/book_appointment_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment_success/payment_success_screen.dart';
import '../screens/health/health_tracking_screen.dart';
import '../screens/analytics/health_analytics_screen.dart';
import '../screens/insurance/insurance_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/appointment/appointments_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String doctorDetails = '/doctor-details';
  static const String bookAppointment = '/book-appointment';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String healthTracking = '/health-tracking';
  static const String healthAnalytics = '/health-analytics';
  static const String insurance = '/insurance';
  static const String appointments = '/appointments';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: home, page: () => HomeScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: register, page: () => RegisterScreen()),
    GetPage(
      name: doctorDetails, 
      page: () {
        final doctor = Get.arguments['doctor'];
        return DoctorDetailsScreen(doctor: doctor);
      },
    ),
    GetPage(
      name: bookAppointment, 
      page: () {
        final doctor = Get.arguments['doctor'];
        final isVideoConsultation = Get.arguments['isVideoConsultation'] ?? false;
        return BookAppointmentScreen(
          doctor: doctor,
          isVideoConsultation: isVideoConsultation,
        );
      },
    ),
    GetPage(
      name: payment, 
      page: () {
        final appointment = Get.arguments['appointment'];
        return PaymentScreen(appointment: appointment);
      },
    ),
    GetPage(
      name: paymentSuccess, 
      page: () {
        final appointment = Get.arguments['appointment'];
        return PaymentSuccessScreen(appointment: appointment);
      },
    ),
    GetPage(name: healthTracking, page: () => HealthTrackingScreen()),
    GetPage(name: healthAnalytics, page: () => HealthAnalyticsScreen()),
    GetPage(name: insurance, page: () => InsuranceScreen()),
    GetPage(name: appointments, page: () => AppointmentsScreen()),
  ];
}
