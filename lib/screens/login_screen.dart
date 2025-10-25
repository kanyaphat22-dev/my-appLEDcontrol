import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool _obscure = true;
  final Color logoBlue = const Color(0xFF2D9CC8);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color bottomColor = Color(0xFF2D9CC8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: bottomColor,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFd5f3ff),
                  bottomColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', width: size.width * 0.6),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Material(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: logoBlue,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      onSaved: (v) => username = v!.trim(),
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'กรุณากรอกชื่อผู้ใช้'
                                          : null,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z0-9_.\-]')),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'ชื่อผู้ใช้',
                                        labelStyle:
                                            TextStyle(color: logoBlue),
                                        prefixIcon: Icon(Icons.person,
                                            color: logoBlue, size: 28),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      obscureText: _obscure,
                                      onSaved: (v) => password = v ?? '',
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'กรุณากรอกรหัสผ่าน'
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: 'รหัสผ่าน',
                                        labelStyle:
                                            TextStyle(color: logoBlue),
                                        prefixIcon: Icon(Icons.lock,
                                            color: logoBlue, size: 28),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: logoBlue,
                                          ),
                                          onPressed: () {
                                            setState(
                                                () => _obscure = !_obscure);
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            side: BorderSide(
                                                color: logoBlue, width: 2),
                                          ),
                                          backgroundColor: logoBlue,
                                          shadowColor: Colors.black
                                              .withOpacity(0.2),
                                          elevation: 6,
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _formKey.currentState!.save();
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );

                                            final result =
                                                await AuthService.login(
                                              username: username,
                                              password: password,
                                            );
                                            Navigator.pop(context);

                                            if (result['success'] == true) {
                                              final prefs =
                                                  await SharedPreferences
                                                      .getInstance();
                                              final user = result['user'];

                                              await prefs.setString(
                                                  'user_id',
                                                  user['id'].toString());
                                              await prefs.setString('username',
                                                  user['username']);
                                              await prefs.setString('fullname',
                                                  user['fullname']);
                                              await prefs.setString(
                                                  'role', user['role']);

                                              // ✅ บันทึกสถานะล็อกอินไว้
                                              await prefs.setBool(
                                                  'isLoggedIn', true);
                                              await prefs.setBool(
                                                  'justLoggedIn', true);

                                              // ✅ ไปหน้า floor (MainScreen)
                                              if (context.mounted) {
                                                Navigator
                                                    .pushReplacementNamed(
                                                        context, '/floor');
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(result[
                                                        'message'] ??
                                                    'เข้าสู่ระบบล้มเหลว'),
                                              ));
                                            }
                                          }
                                        },
                                        child: const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                                color: Colors.black26,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: RichText(
                                        text: TextSpan(
                                          text: "Don't have an account  ",
                                          style: TextStyle(
                                              color: logoBlue, fontSize: 16),
                                          children: [
                                            TextSpan(
                                              text: "Register",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: logoBlue,
                                                letterSpacing: 1.5,
                                              ),
                                              recognizer:
                                                  TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.pushNamed(
                                                          context, '/signup');
                                                    },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
