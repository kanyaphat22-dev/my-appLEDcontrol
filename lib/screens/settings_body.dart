import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  final String appVersion = "1.0.0";

  final String baseUrl = "http://172.26.30.10/webcontrol/web";
  final String logoutApiUrl = "http://172.26.30.10/webcontrol/web/logout.php";

  String username = "";
  String email = "-";

  @override
  void initState() {
    super.initState();
    _loadUsernameAndFetchUserInfo();
  }

  // ✅ โหลด username จาก SharedPreferences แล้วไปดึงข้อมูลจาก API
  Future<void> _loadUsernameAndFetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      setState(() => username = savedUsername);
      debugPrint("✅ โหลด username จาก SharedPreferences: $username");
      _fetchUserInfo(savedUsername);
    } else {
      debugPrint("⚠️ ไม่พบ username ใน SharedPreferences");
    }
  }

  // ✅ ดึงข้อมูล email จากเซิร์ฟเวอร์
  Future<void> _fetchUserInfo(String username) async {
    try {
      final url = "$baseUrl/get_user_info.php?username=$username";
      debugPrint("🌐 GET → $url");

      final response = await http.get(Uri.parse(url));
      debugPrint("📩 Response → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          setState(() {
            email = data["email"] ?? "-";
          });
        } else {
          debugPrint("⚠️ ${data["message"]}");
        }
      } else {
        debugPrint("⚠️ Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching user info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // 🔵 แถบหัวข้อ
            Container(
              width: double.infinity,
              color: const Color(0xFF83CAF6),
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 80,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: const Text(
                    'การตั้งค่า',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // ⚙️ เนื้อหา
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 👤 ข้อมูลบัญชี
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blueAccent,
                          child:
                              Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username.isEmpty ? "กำลังโหลด..." : username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.grey),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ℹ️ เกี่ยวกับแอป
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: "เกี่ยวกับแอป",
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 160),
                ],
              ),
            ),
          ],
        ),

        // 🚪 ปุ่มออกจากระบบ
        Positioned(
          left: 20,
          right: 20,
          bottom: kBottomNavigationBarHeight + 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  spreadRadius: 0.5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                await _sendLogoutToServer();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                "ออกจากระบบ",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16)),
              ),
              trailing ??
                  const Icon(Icons.arrow_forward_ios,
                      size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("เกี่ยวกับแอป"),
        content: Text("เวอร์ชัน: $appVersion\nAPI Base: $baseUrl"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ปิด"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLogoutToServer() async {
    try {
      await http.get(Uri.parse(logoutApiUrl));
      debugPrint("📤 Logout sent to server successfully.");
    } catch (e) {
      debugPrint("❌ Error sending logout: $e");
    }
  }
}
