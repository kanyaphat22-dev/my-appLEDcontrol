import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'esp32_service.dart';
import 'notification_manager.dart';
import 'package:intl/intl.dart';

class ControlScreen extends StatefulWidget {
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool lightOn1 = false;
  bool lightOn2 = false;
  bool dualMode = false;

  String selectedSwitch = "SW1";

  TimeOfDay? scheduledOnTime;
  TimeOfDay? scheduledOffTime;
  Timer? onTimer;
  Timer? offTimer;
  Timer? statusTimer;

  String floor = "";
  String room = "";
  String roomKey = "";

  bool _isDropdownVisible = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  final GlobalKey _buttonKey = GlobalKey();

  List<Map<String, dynamic>> _webSchedules = [];
  List<String> selectedDays = [];

  DateTime? startDate;
  DateTime? endDate;
  bool scheduleEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (roomKey.isEmpty) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      floor = args['floor'] as String;
      room = args['room'] as String;
      roomKey = room;
      dualMode = room.contains("Hall") || room.contains("Corridor");
      _loadSavedTimesAndStatus();
      // ✅ โหลดตารางเวลาทันทีหลังรู้ว่า roomKey คือห้องไหน
    _loadWebSchedules();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLightStatusFromESP32();
    });
    statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      await _fetchLightStatusFromESP32();
    });
    
  }

  @override
  void dispose() {
    onTimer?.cancel();
    offTimer?.cancel();
    statusTimer?.cancel();
    _dropdownOverlay?.remove();
    super.dispose();
  }

  Future<void> _fetchLightStatusFromESP32() async {
    try {
      if (dualMode) {
        bool? s1 = await ESP32Service.getLightStatus("${roomKey}_1");
        bool? s2 = await ESP32Service.getLightStatus("${roomKey}_2");
        setState(() {
          if (s1 != null) lightOn1 = s1;
          if (s2 != null) lightOn2 = s2;
        });
      } else {
        bool s = await ESP32Service.getLightStatus(roomKey);
        setState(() => lightOn1 = s);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedTimesAndStatus() async {
    final prefs = await SharedPreferences.getInstance();
    selectedSwitch = prefs.getString('${roomKey}_selectedSwitch') ?? "SW1";
    final daysString = prefs.getString('${roomKey}_selectedDays');
    if (daysString != null && daysString.isNotEmpty) {
      selectedDays = daysString.split(',');
    }

    final startStr = prefs.getString('${roomKey}_startDate');
    final endStr = prefs.getString('${roomKey}_endDate');
    if (startStr != null && startStr.isNotEmpty)
      startDate = DateTime.tryParse(startStr);
    if (endStr != null && endStr.isNotEmpty)
      endDate = DateTime.tryParse(endStr);
    scheduleEnabled = prefs.getBool('${roomKey}_scheduleEnabled') ?? false;

    final onHour = prefs.getInt('${roomKey}_onHour');
    final onMinute = prefs.getInt('${roomKey}_onMinute');
    final offHour = prefs.getInt('${roomKey}_offHour');
    final offMinute = prefs.getInt('${roomKey}_offMinute');

    if (onHour != null && onMinute != null) {
      scheduledOnTime = TimeOfDay(hour: onHour, minute: onMinute);
    }
    if (offHour != null && offMinute != null) {
      scheduledOffTime = TimeOfDay(hour: offHour, minute: offMinute);
    }

    _scheduleTimers();
  }

  Future<void> _loadWebSchedules() async {
    final list = await ESP32Service.getSchedules(roomKey);
    setState(() => _webSchedules = list);
  }

  Future<void> _saveTimes() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('${roomKey}_selectedSwitch', selectedSwitch);
  prefs.setString('${roomKey}_selectedDays', selectedDays.join(','));
  prefs.setString('${roomKey}_startDate', startDate?.toIso8601String() ?? '');
  prefs.setString('${roomKey}_endDate', endDate?.toIso8601String() ?? '');
  prefs.setBool('${roomKey}_scheduleEnabled', scheduleEnabled);

  if (scheduledOnTime != null && scheduledOffTime != null) {
    prefs.setInt('${roomKey}_onHour', scheduledOnTime!.hour);
    prefs.setInt('${roomKey}_onMinute', scheduledOnTime!.minute);
    prefs.setInt('${roomKey}_offHour', scheduledOffTime!.hour);
    prefs.setInt('${roomKey}_offMinute', scheduledOffTime!.minute);

    final start =
        "${scheduledOnTime!.hour.toString().padLeft(2, '0')}:${scheduledOnTime!.minute.toString().padLeft(2, '0')}:00";
    final end =
        "${scheduledOffTime!.hour.toString().padLeft(2, '0')}:${scheduledOffTime!.minute.toString().padLeft(2, '0')}:00";

    // ✅ ถ้าไม่เลือกวันเลย ให้เป็น mode "on" และวันเดียวกัน
    final bool isOneTime = selectedDays.isEmpty;
    final mode = isOneTime ? "on" : "daily";

    // ✅ วันที่ที่ตั้ง (หรือวันนี้)
    final date = startDate ?? DateTime.now();
    final startDateStr = DateFormat('yyyy-MM-dd').format(date);
    final endDateStr = isOneTime
        ? startDateStr // ครั้งเดียว
        : (endDate != null
            ? DateFormat('yyyy-MM-dd').format(endDate!)
            : '');

    // ✅ แปลงวันที่เป็นชื่อวัน เช่น "Mon" "Sun"
    String weekdaysValue;
    if (isOneTime) {
      weekdaysValue = DateFormat('E').format(date); // → "Mon", "Tue", "Sun"
    } else {
      weekdaysValue = selectedDays.join(',');
    }

    // ✅ แปลงสวิตช์เป็น GPIO
int gpio = 26; // SW1 (ค่าเริ่มต้น)
if (selectedSwitch == "SW2") gpio = 25;

// ✅ ถ้าเลือกทั้งสองสวิตช์ ให้ส่งแยกสองคำสั่ง
if (selectedSwitch == "SW1+SW2") {
  await ESP32Service.setSchedule(
    roomKey: roomKey,
    mode: mode,
    startTime: start,
    endTime: end,
    weekdays: weekdaysValue,
    enabled: true,
    startDate: startDateStr,
    endDate: endDateStr,
    gpio: 26,
  );
  await ESP32Service.setSchedule(
    roomKey: roomKey,
    mode: mode,
    startTime: start,
    endTime: end,
    weekdays: weekdaysValue,
    enabled: true,
    startDate: startDateStr,
    endDate: endDateStr,
    gpio: 25,
  );
} else {
  // ✅ กรณีเลือกสวิตช์เดียว
  await ESP32Service.setSchedule(
    roomKey: roomKey,
    mode: mode,
    startTime: start,
    endTime: end,
    weekdays: weekdaysValue,
    enabled: true,
    startDate: startDateStr,
    endDate: endDateStr,
    gpio: gpio, // ✅ ส่ง gpio ตามที่เลือก
  );
}

    await _loadWebSchedules();
  }
}

  void _scheduleTimers() {
    onTimer?.cancel();
    offTimer?.cancel();
    if (!scheduleEnabled) return;

    final now = DateTime.now();

    if (scheduledOnTime != null) {
      final onDateTime = DateTime(
          now.year, now.month, now.day, scheduledOnTime!.hour, scheduledOnTime!.minute);
      final onDelay = onDateTime.isBefore(now)
          ? onDateTime.add(const Duration(days: 1)).difference(now)
          : onDateTime.difference(now);
      onTimer = Timer(onDelay, () => _sendCommand(true));
    }

    if (scheduledOffTime != null) {
      final offDateTime = DateTime(
          now.year, now.month, now.day, scheduledOffTime!.hour, scheduledOffTime!.minute);
      final offDelay = offDateTime.isBefore(now)
          ? offDateTime.add(const Duration(days: 1)).difference(now)
          : offDateTime.difference(now);
      offTimer = Timer(offDelay, () => _sendCommand(false));
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? (startDate ?? now) : (endDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'วว/ดด/ปปปป';
    final buddhistYear = date.year + 543;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/$buddhistYear';
  }

  Future<void> pickTime(BuildContext context, bool isOnTime) async {
    final now = DateTime.now();
    await showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 250,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: now,
          use24hFormat: true,
          onDateTimeChanged: (DateTime dt) {
            setState(() {
              if (isOnTime) {
                scheduledOnTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
              } else {
                scheduledOffTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
              }
            });
          },
        ),
      ),
    );
  }

  String formatTime(TimeOfDay? t) {
    if (t == null) return '-';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} น.';
  }

  Future<void> _sendCommand(bool turnOn, {int? fixedIndex}) async {
    if (dualMode) {
      if (fixedIndex != null) {
        await ESP32Service.sendCommand("${roomKey}_$fixedIndex", turnOn);
        setState(() {
          if (fixedIndex == 1)
            lightOn1 = turnOn;
          else
            lightOn2 = turnOn;
        });
        return;
      }

      if (selectedSwitch == "SW1+SW2") {
        await ESP32Service.sendCommand("${roomKey}_1", turnOn);
        await ESP32Service.sendCommand("${roomKey}_2", turnOn);
        setState(() {
          lightOn1 = turnOn;
          lightOn2 = turnOn;
        });
      } else {
        int index = selectedSwitch == "SW1" ? 1 : 2;
        await ESP32Service.sendCommand("${roomKey}_$index", turnOn);
        setState(() {
          if (index == 1)
            lightOn1 = turnOn;
          else
            lightOn2 = turnOn;
        });
      }
    } else {
      await ESP32Service.sendCommand(roomKey, turnOn);
      setState(() => lightOn1 = turnOn);
    }
  }

 Widget _buildSaveButton() {
  return ElevatedButton(
    onPressed: () async {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏳ กำลังบันทึก...',
              style: GoogleFonts.prompt(color: Colors.white)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );

      // ✅ บันทึก Schedule ไปยัง Server
      await _saveTimes();

      // ✅ โหลดข้อมูลตารางใหม่จากเซิร์ฟเวอร์
      await _loadWebSchedules();

      // ✅ ล้างค่าที่เก็บใน SharedPreferences ของห้องนี้
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${roomKey}_selectedSwitch');
      await prefs.remove('${roomKey}_selectedDays');
      await prefs.remove('${roomKey}_startDate');
      await prefs.remove('${roomKey}_endDate');
      await prefs.remove('${roomKey}_scheduleEnabled');
      await prefs.remove('${roomKey}_onHour');
      await prefs.remove('${roomKey}_onMinute');
      await prefs.remove('${roomKey}_offHour');
      await prefs.remove('${roomKey}_offMinute');

      // ✅ รีเซ็ตเฉพาะส่วน "สร้าง Schedule" ใน UI
      setState(() {
        selectedSwitch = "SW1";
        scheduledOnTime = null;
        scheduledOffTime = null;
        selectedDays.clear();
        startDate = null;
        endDate = null;
        scheduleEnabled = false;
      });

      // ✅ แจ้งเตือนสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ บันทึก Schedule สำเร็จ (รีเฟรชและล้างข้อมูลเก่าแล้ว)',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text('บันทึก Schedule',
        style: GoogleFonts.prompt(fontSize: 16, color: Colors.white)),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 131, 202, 246),
     leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Colors.black),
  onPressed: () async {
    statusTimer?.cancel();

    // 🔧 ล้างข้อมูล SharedPreferences ก่อนออก (กันเผื่อผู้ใช้ยังไม่ได้บันทึก)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${roomKey}_selectedSwitch');
    await prefs.remove('${roomKey}_selectedDays');
    await prefs.remove('${roomKey}_startDate');
    await prefs.remove('${roomKey}_endDate');
    await prefs.remove('${roomKey}_scheduleEnabled');
    await prefs.remove('${roomKey}_onHour');
    await prefs.remove('${roomKey}_onMinute');
    await prefs.remove('${roomKey}_offHour');
    await prefs.remove('${roomKey}_offMinute');

    Navigator.pop(context);
  },
),

        title: Text('ควบคุมไฟ - $floor $room',
            style: GoogleFonts.prompt(
                fontSize: 18, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildLightPanel(),
            const SizedBox(height: 30),
            _buildScheduleSetupBox(),
            const SizedBox(height: 25),
            _buildWebScheduleBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildLightPanel() {
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))
        ],
      ),
      child: dualMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLightColumn(1, lightOn1),
                _buildLightColumn(2, lightOn2),
              ],
            )
          : Center(child: _buildLightColumn(1, lightOn1)),
    );
  }

  Widget _buildLightColumn(int index, bool lightOn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(lightOn ? Icons.lightbulb : Icons.lightbulb_outline,
            color: lightOn ? Colors.yellow[600] : Colors.grey[400], size: 110),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () =>
              _sendCommand(index == 1 ? !lightOn1 : !lightOn2, fixedIndex: index),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: lightOn ? Colors.lightBlue : Colors.grey, width: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            lightOn ? 'ปิดไฟ $index' : 'เปิดไฟ $index',
            style: GoogleFonts.prompt(
                fontSize: 16,
                color: lightOn ? Colors.lightBlue : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSetupBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Text('สร้าง Schedule',
                  style: GoogleFonts.prompt(
                      fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('เลือกสวิตช์',
                  style: GoogleFonts.prompt(
                      fontSize: 14, color: Colors.grey[700])),
              SizedBox(width: 100, child: _buildSwitchSelector()),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('วันที่เริ่ม',
                        style: GoogleFonts.prompt(
                            fontSize: 12.5, color: Colors.grey[700])),
                    const SizedBox(height: 3),
                    InkWell(
                      onTap: () => pickDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.lightBlue.shade300, width: 1),
                          color: Colors.grey[50],
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatDate(startDate),
                          style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('วันที่สิ้นสุด',
                        style: GoogleFonts.prompt(
                            fontSize: 12.5, color: Colors.grey[700])),
                    const SizedBox(height: 3),
                    InkWell(
                      onTap: () => pickDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.lightBlue.shade300, width: 1),
                          color: Colors.grey[50],
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatDate(endDate),
                          style: GoogleFonts.prompt(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('วันทำงาน',
              style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var day in [
                  {'key': 'Mon', 'label': 'จ.'},
                  {'key': 'Tue', 'label': 'อ.'},
                  {'key': 'Wed', 'label': 'พ.'},
                  {'key': 'Thu', 'label': 'พฤ.'},
                  {'key': 'Fri', 'label': 'ศ.'},
                  {'key': 'Sat', 'label': 'ส.'},
                  {'key': 'Sun', 'label': 'อา.'},
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedDays.contains(day['key'])) {
                            selectedDays.remove(day['key']);
                          } else {
                            selectedDays.add(day['key']!);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding:
                            const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        decoration: BoxDecoration(
                          color: selectedDays.contains(day['key'])
                              ? Colors.lightBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: selectedDays.contains(day['key'])
                                  ? Colors.lightBlue
                                  : Colors.grey.shade400),
                        ),
                        child: Text(
                          day['label']!,
                          style: GoogleFonts.prompt(
                              fontSize: 10,
                              color: selectedDays.contains(day['key'])
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('เวลาเปิดไฟ: ${formatTime(scheduledOnTime)}',
                  style: GoogleFonts.prompt(fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.access_time, color: Colors.lightBlue),
                onPressed: () => pickTime(context, true),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('เวลาปิดไฟ: ${formatTime(scheduledOffTime)}',
                  style: GoogleFonts.prompt(fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.access_time, color: Colors.lightBlue),
                onPressed: () => pickTime(context, false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildWebScheduleBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📅 ตารางเวลาเปิด-ปิด",
              style: GoogleFonts.prompt(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (_webSchedules.isEmpty)
            Center(
                child: Text("ยังไม่มีตารางเวลา",
                    style: GoogleFonts.prompt(
                        fontSize: 16, color: Colors.grey))),
                   ..._webSchedules.map((s) {
  final switchName = (s['gpio'] != null)
      ? "SW${s['gpio'] == 25 ? '2' : '1'}"
      : "";
  final weekdaysRaw = (s['weekdays'] ?? '');
  final startTime = s['start_time'] ?? '';
  final endTime = s['end_time'] ?? '';
  final startDate = s['start_date'] ?? '';
  final endDate = s['end_date'] ?? '';
  final enabled = s['enabled'] == 1;

  // 🔹 แปลงชื่อวันอังกฤษ → ไทย
  final Map<String, String> dayMap = {
    'Mon': 'จ.',
    'Tue': 'อ.',
    'Wed': 'พ.',
    'Thu': 'พฤ.',
    'Fri': 'ศ.',
    'Sat': 'ส.',
    'Sun': 'อา.',
  };

  String weekdaysThai = '';
  if (weekdaysRaw.isNotEmpty) {
    weekdaysThai = weekdaysRaw
        .split(',')
        .map((d) => dayMap[d.trim()] ?? d.trim())
        .join(', ');
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: enabled ? const Color(0xFFD9F9D9) : Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              switchName,
              style: GoogleFonts.prompt(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                Icon(
                  enabled ? Icons.check_circle : Icons.cancel,
                  color: enabled ? Colors.green : Colors.red,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  enabled ? "เปิดใช้งาน" : "ปิดอยู่",
                  style: GoogleFonts.prompt(
                    fontSize: 10,
                    color: enabled ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text("📋วันทำงาน $weekdaysThai",
            style: GoogleFonts.prompt(fontSize: 10, color: Colors.black87)),
        Text("🕒เวลา $startTime - $endTime",
            style: GoogleFonts.prompt(fontSize: 10, color: Colors.black87)),
        Text("🗓️วันที่ $startDate ถึง $endDate",
            style: GoogleFonts.prompt(fontSize: 10, color: Colors.black87)),
      ],
    ),
  );
}).toList(),


        ],
      ),
    );
  }


  Widget _buildSwitchSelector() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _buttonKey,
        onTap: _toggleDropdown,
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.lightBlue.shade300, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8)
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(selectedSwitch,
              style: GoogleFonts.prompt(
                  fontSize: 8, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  void _toggleDropdown() {
    if (_isDropdownVisible) {
      _removeDropdown();
    } else {
      _showAnimatedDropdown();
    }
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    setState(() => _isDropdownVisible = false);
  }

  void _showAnimatedDropdown() {
    final overlay = Overlay.of(context);
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy + size.height + 6,
            width: size.width,
            child: _AnimatedDropdownMenu(
              selected: selectedSwitch,
              dualMode: dualMode,
              onSelect: (value) async {
                setState(() => selectedSwitch = value);
                
                _removeDropdown();
              },
            ),
          ),
        ],
      ),
    );

    overlay.insert(_dropdownOverlay!);
    setState(() => _isDropdownVisible = true);
  }
}

class _AnimatedDropdownMenu extends StatefulWidget {
  final String selected;
  final bool dualMode;
  final Function(String) onSelect;

  const _AnimatedDropdownMenu({
    required this.selected,
    required this.dualMode,
    required this.onSelect,
  });

  @override
  State<_AnimatedDropdownMenu> createState() =>
      _AnimatedDropdownMenuState();
}

class _AnimatedDropdownMenuState extends State<_AnimatedDropdownMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      "SW1",
      if (widget.dualMode) "SW2",
      if (widget.dualMode) "SW1+SW2",
    ];

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < options.length; i++) ...[
                  _buildOptionTile(options[i]),
                  if (i < options.length - 1)
                    Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8),
                      height: 0.5,
                      color: Colors.grey.shade300,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(String e) {
    final selected = widget.selected == e;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => widget.onSelect(e),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                e,
                style: GoogleFonts.prompt(
                  fontSize: 10,
                  color: selected ? Colors.lightBlue : Colors.black87,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check,
                  color: Colors.lightBlue, size: 14),
          ],
        ),
      ),
    );
  }
}
