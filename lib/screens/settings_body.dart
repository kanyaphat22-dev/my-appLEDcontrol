import 'package:flutter/material.dart';
import 'login_screen.dart'; // 🔹 import หน้า Login ของคุณ

class SettingsBody extends StatefulWidget {
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  String selectedLanguage = "ไทย";
  bool isDarkMode = false; // ปุ่มเปิด/ปิดโหมดแสดงผล

  // 🔹 สมมติว่าเรากำหนดค่า API IP ไว้ตรงนี้
  final String apiIp = "http://192.168.1.100:3000";
  final String appVersion = "1.0.0";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 131, 202, 246),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'การตั้งค่า',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section: Account
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
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Kanyaphat",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "user@email.com",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // ไปหน้าแก้ไขโปรไฟล์
                      },
                      icon: const Icon(Icons.edit, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: App Settings - ภาษา
              _buildSettingItem(
                icon: Icons.language,
                title: "ภาษา",
                trailing: DropdownButton<String>(
                  value: selectedLanguage,
                  items: ["ไทย", "English"].map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                    });
                  },
                ),
              ),

              // Section: โหมดแสดงผล - Switch เปิด/ปิด
              _buildSettingItem(
                icon: Icons.brightness_6,
                title: "โหมดแสดงผล",
                trailing: SizedBox(
                  width: 60,
                  child: Switch(
                    value: isDarkMode,
                    onChanged: (val) {
                      setState(() {
                        isDarkMode = val;
                        // TODO: เปลี่ยน Theme ของแอปที่นี่
                      });
                    },
                    activeColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section: About
              _buildSettingItem(
                icon: Icons.info_outline,
                title: "เกี่ยวกับแอป",
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 20),

              // Logout
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // 🔹 เคลียร์ session/token ที่เก็บไว้ก่อน (ถ้ามี)

                  // 🔹 เด้งไปหน้า Login และลบ stack ทั้งหมด
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "ออกจากระบบ",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
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
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16),
                ),
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

  // 🔹 ฟังก์ชันแสดง Dialog เกี่ยวกับแอป
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 190,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "เกี่ยวกับแอป",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text("เวอร์ชัน: $appVersion",
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("API Server: $apiIp",
                      style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("ปิด"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
