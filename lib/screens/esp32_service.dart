import 'dart:convert';
import 'package:http/http.dart' as http;

class ESP32Service {
  // 🧩 IP ของห้องทดลองจริง
  static final Map<String, String> roomIPs = {
    'F10_Lift': '192.168.1.601',
    'F10_Hall_1': '172.26.30.11',
    'F10_Hall_2': '172.26.30.11',
    'F10_Corridor_1': '172.26.30.12',
    'F10_Corridor_2': '172.26.30.12',
  };

  // 🌐 URL ของ PHP API
  static const String phpApiBase = "http://172.26.30.10/webcontrol/web/api";

  // ====== ส่งคำสั่งเปิด/ปิดไฟ ======
  static Future<void> sendCommand(String roomKey, bool turnOn) async {
    final ip = roomIPs[roomKey];
    if (ip == null) {
      print('❌ ไม่พบ IP ของ $roomKey');
      return;
    }

    final isSwitch2 = roomKey.endsWith('_2');
    final index = isSwitch2 ? '2' : '1';
    final command = turnOn ? 'on$index' : 'off$index';
    final status = turnOn ? 'on' : 'off';
    final url = 'http://$ip/$command';

    try {
      final resEsp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (resEsp.statusCode == 200) print('✅ ส่งคำสั่งสำเร็จ ($roomKey)');
    } catch (e) {
      print('🚫 เชื่อมต่อ ESP32 ไม่สำเร็จ: $e');
    }

    try {
      final updateUrl = "$phpApiBase/update_status.php?room=$roomKey&status=$status";
      await http.get(Uri.parse(updateUrl)).timeout(const Duration(seconds: 3));
      print('📡 อัปเดตสถานะในเว็บสำเร็จ ($roomKey → $status)');
    } catch (e) {
      print('🚫 เชื่อมต่อ PHP API ไม่สำเร็จ: $e');
    }
  }

  // ====== ดึงสถานะไฟจาก ESP ======
  static Future<bool> getLightStatus(String roomKey) async {
    final ip = roomIPs[roomKey];
    if (ip == null) return false;
    final isSwitch2 = roomKey.endsWith('_2');
    final index = isSwitch2 ? '2' : '1';
    final url = 'http://$ip/status$index';

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['lightOn'] as bool? ?? false;
      }
    } catch (e) {
      print('🚫 ดึงสถานะไฟไม่สำเร็จ: $e');
    }
    return false;
  }

  // ====== ดึงตารางเวลาจากเว็บ ======
  static Future<List<Map<String, dynamic>>> getSchedules(String roomKey) async {
    final url = "$phpApiBase/get_schedule.php?room=$roomKey";
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['schedules'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('🚫 ดึงตารางเวลาไม่สำเร็จ: $e');
    }
    return [];
  }

  // ====== บันทึกตารางเวลาใหม่ ======
  static Future<bool> setSchedule({
    required String roomKey,
    required String mode,
    required String startTime,
    required String endTime,
    bool enabled = true,
  }) async {
    final url = "$phpApiBase/set_schedule.php";
    final body = jsonEncode({
      'room': roomKey,
      'mode': mode,
      'start_time': startTime,
      'end_time': endTime,
      'enabled': enabled ? 1 : 0,
    });
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['ok'] == true;
      }
    } catch (e) {
      print('🚫 บันทึกตารางเวลาไม่สำเร็จ: $e');
    }
    return false;
  }
}
