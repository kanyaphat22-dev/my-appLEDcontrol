import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/main_screen.dart';
import 'screens/room_screen.dart';
import 'screens/control_screen.dart';
import 'screens/user_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ โหลด SharedPreferences ก่อนรันแอป
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  final primaryColor = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Light Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.blueAccent),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // ✅ ถ้าเคยล็อกอิน → ไปหน้า MainScreen ทันที
      // ✅ ถ้ายังไม่เคย → ไปหน้า SplashScreen
      initialRoute: isLoggedIn ? '/floor' : '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/floor': (context) => const MainScreen(),
        '/room': (context) => RoomScreen(),
        '/control': (context) => ControlScreen(),
        '/users': (context) => UserListScreen(),
      },
    );
  }
}
