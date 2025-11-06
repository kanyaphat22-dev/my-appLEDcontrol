import 'dart:convert';
import 'package:http/http.dart' as http;

class ESP32Service {
  // 🌐 URL ของ PHP API (แก้ให้ตรงกับเครื่องของคุณ)
  static const String phpApiBase = "http://172.24.13.135/web/api.php";

  // 🧩 Mapping รายชื่อห้องกับบอร์ดและ GPIO
  static final Map<String, Map<String, dynamic>> roomMap = {
    // ================= ชั้น 2 =================
    'F2_Hall': {'esp_name': 'ESP32_003', 'gpio': 26},
    'F2_Hall_1': {'esp_name': 'ESP32_003', 'gpio': 26},
    'F2_Hall_2': {'esp_name': 'ESP32_003', 'gpio': 25},
    'F2_Corridor': {'esp_name': 'ESP32_004', 'gpio': 25},
    'F2_Canteen': {'esp_name': 'ESP32_005', 'gpio': 25},

    // ================= ชั้น 10 =================
    'F10_Hall': {'esp_name': 'ESP32_001', 'gpio': 26}, // ✅ ตัวหลัก
    'F10_Hall_1': {'esp_name': 'ESP32_001', 'gpio': 26},
    'F10_Hall_2': {'esp_name': 'ESP32_001', 'gpio': 25},

    'F10_Corridor': {'esp_name': 'ESP32_002', 'gpio': 26}, // ✅ ตัวหลัก
    'F10_Corridor_1': {'esp_name': 'ESP32_002', 'gpio': 26},
    'F10_Corridor_2': {'esp_name': 'ESP32_002', 'gpio': 25},
  };

  // ====== 🔘 ส่งคำสั่งเปิด/ปิดไฟ ======
  static Future<void> sendCommand(String roomKey, bool turnOn) async {
    final cleanKey = roomKey.replaceAll(RegExp(r'ชั้น\s*\d+_'), '');
    final info = roomMap[roomKey] ?? roomMap[cleanKey];

    if (info == null) {
      print('❌ ไม่พบข้อมูลของห้อง $roomKey หรือ $cleanKey ใน roomMap');
      return;
    }

    final espName = info['esp_name'];
    final gpio = info['gpio'];
    final status = turnOn ? 1 : 0;

    final url =
        "$phpApiBase?cmd=update&esp_name=$espName&gpio=$gpio&status=$status";

    try {
      print("⚙️ ส่งคำสั่งไปยัง $espName (GPIO: $gpio) "
          "ให้${turnOn ? 'เปิด' : 'ปิด'}ไฟ...");

      final start = DateTime.now(); // 🕒 เริ่มจับเวลา
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      final end = DateTime.now(); // 🕒 เวลาหลังได้รับการตอบกลับ
      final diffMs = end.difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        print("✅ ส่งคำสั่งสำเร็จ ($roomKey → ${turnOn ? 'เปิด' : 'ปิด'})");
        print("⏱️ ดีเลย์จาก Flutter → Server: ${diffMs} ms "
            "(${(diffMs / 1000).toStringAsFixed(3)} วินาที)");
      } else {
        print("⚠️ เซิร์ฟเวอร์ตอบกลับผิดพลาด: ${res.statusCode}");
      }
    } catch (e) {
      print("🚫 ส่งคำสั่งไม่สำเร็จ: $e");
    }
  }

  // ====== 💡 ดึงสถานะไฟจาก PHP API ======
  static Future<bool> getLightStatus(String roomKey) async {
    final cleanKey = roomKey.replaceAll(RegExp(r'ชั้น\s*\d+_'), '');
    final info = roomMap[roomKey] ?? roomMap[cleanKey];

    if (info == null) {
      print('❌ ไม่พบข้อมูลของห้อง $roomKey หรือ $cleanKey ใน roomMap');
      return false;
    }

    final espName = info['esp_name'];
    final gpio = info['gpio'];
    final url = "$phpApiBase?cmd=get_status&esp_name=$espName&gpio=$gpio";

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == true;
      }
    } catch (e) {
      print("🚫 ดึงสถานะไฟไม่สำเร็จ: $e");
    }
    return false;
  }

  // ====== 📅 ดึงตารางเวลา ======
  static Future<List<Map<String, dynamic>>> getSchedules(String roomKey) async {
    final cleanKey = roomKey.replaceAll(RegExp(r'ชั้น\s*\d+_'), '');
    final info = roomMap[roomKey] ?? roomMap[cleanKey];
    if (info == null) return [];

    final espName = info['esp_name'];
    final url = "$phpApiBase?cmd=get_schedule&esp_name=$espName";

    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      print("🚫 ดึงตารางเวลาไม่สำเร็จ: $e");
    }
    return [];
  }

  // ====== ✅ ตั้งเวลาผ่าน API (บันทึกลงฐานข้อมูล) ======
  static Future<bool> setSchedule({
    required String roomKey,
    required String mode,
    required String startTime,
    required String endTime,
    String? weekdays,
    bool enabled = true,
    String? startDate, // ✅ วันที่เริ่มต้น
    String? endDate, // ✅ วันที่สิ้นสุด
    int? gpio, // ✅ เพิ่มพารามิเตอร์รับ GPIO จาก ControlScreen
  }) async {
    final cleanKey = roomKey.replaceAll(RegExp(r'ชั้น\s*\d+_'), '');
    final info = roomMap[roomKey] ?? roomMap[cleanKey];
    if (info == null) {
      print("❌ ไม่พบ roomKey: $roomKey ใน roomMap");
      return false;
    }

    final espName = info['esp_name'];
    // ✅ ใช้ GPIO ที่ส่งมาจาก ControlScreen ถ้ามี
    final usedGpio = gpio ?? info['gpio'];

    final url = "$phpApiBase?cmd=set_schedule";

    final body = jsonEncode({
      "esp_name": espName,
      "gpio": usedGpio,
      "mode": mode,
      "start_time": startTime,
      "end_time": endTime,
      "weekdays": weekdays ?? "",
      "enabled": enabled ? 1 : 0,
      "start_date": startDate ?? "",
      "end_date": endDate ?? "",
    });

    print("📤 กำลังส่ง Schedule: $body");

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("📡 Response จาก Server: $data");
        return data['success'] == true;
      } else {
        print("⚠️ Server ตอบกลับด้วยสถานะ: ${res.statusCode}");
      }
    } catch (e) {
      print("🚫 เกิดข้อผิดพลาดในการบันทึกตารางเวลา: $e");
    }

    return false;
  }
}
