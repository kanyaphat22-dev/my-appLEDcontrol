import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'esp32_service.dart';
import 'notification_manager.dart';

class ControlScreen extends StatefulWidget {
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool lightOn = false;
  TimeOfDay? scheduledOnTime;
  TimeOfDay? scheduledOffTime;
  Timer? onTimer;
  Timer? offTimer;
  Timer? statusTimer;

  DateTime? lightOnTime;
  Timer? warningTimer;
  Timer? autoOffTimer;

  String floor = "";
  String room = "";
  String roomKey = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (roomKey.isEmpty) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      floor = args['floor'] as String;
      room = args['room'] as String;
      roomKey = "${floor}_${room}";
      _loadSavedTimesAndStatus();
    }
  }

  @override
  void initState() {
    super.initState();
    statusTimer = Timer.periodic(Duration(seconds: 3), (_) async {
      await _fetchLightStatusFromESP32();
    });
  }

  @override
  void dispose() {
    onTimer?.cancel();
    offTimer?.cancel();
    statusTimer?.cancel();
    warningTimer?.cancel();
    autoOffTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLightStatusFromESP32() async {
    try {
      bool status = await ESP32Service.getLightStatus(roomKey);
      if (!mounted) return;
      setState(() {
        lightOn = status;
        if (lightOn && lightOnTime == null) {
          onLightTurnedOn();
        }
      });
    } catch (e) {
      print('ไม่สามารถดึงสถานะไฟจาก ESP32: $e');
    }
  }

  Future<void> _loadSavedTimesAndStatus() async {
    final prefs = await SharedPreferences.getInstance();
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

    try {
      bool status = await ESP32Service.getLightStatus(roomKey);
      if (!mounted) return;
      setState(() {
        lightOn = status;
        if (lightOn) onLightTurnedOn();
      });
    } catch (e) {
      print('ไม่สามารถดึงสถานะไฟจริงจาก ESP32: $e');
      final savedLight = prefs.getBool('${roomKey}_lightOn') ?? false;
      if (!mounted) return;
      setState(() {
        lightOn = savedLight;
        if (lightOn) onLightTurnedOn();
      });
    }

    _scheduleTimers();
  }

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();

    if (scheduledOnTime != null) {
      prefs.setInt('${roomKey}_onHour', scheduledOnTime!.hour);
      prefs.setInt('${roomKey}_onMinute', scheduledOnTime!.minute);
    } else {
      prefs.remove('${roomKey}_onHour');
      prefs.remove('${roomKey}_onMinute');
    }

    if (scheduledOffTime != null) {
      prefs.setInt('${roomKey}_offHour', scheduledOffTime!.hour);
      prefs.setInt('${roomKey}_offMinute', scheduledOffTime!.minute);
    } else {
      prefs.remove('${roomKey}_offHour');
      prefs.remove('${roomKey}_offMinute');
    }

    prefs.setBool('${roomKey}_lightOn', lightOn);
    _scheduleTimers();
  }

  void _scheduleTimers() {
    onTimer?.cancel();
    offTimer?.cancel();
    final now = DateTime.now();

    if (scheduledOnTime != null) {
      final onDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledOnTime!.hour,
        scheduledOnTime!.minute,
      );
      final onDelay = onDateTime.isBefore(now)
          ? onDateTime.add(Duration(days: 1)).difference(now)
          : onDateTime.difference(now);

      onTimer = Timer(onDelay, () async {
        await ESP32Service.sendCommand(roomKey, true);
        onLightTurnedOn();
        await _saveTimes();
        if (mounted) setState(() => lightOn = true);
      });
    }

    if (scheduledOffTime != null) {
      final offDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledOffTime!.hour,
        scheduledOffTime!.minute,
      );
      final offDelay = offDateTime.isBefore(now)
          ? offDateTime.add(Duration(days: 1)).difference(now)
          : offDateTime.difference(now);

      offTimer = Timer(offDelay, () async {
        await _turnOffLight(isScheduled: true);
      });
    }
  }

  void onLightTurnedOn() {
    lightOnTime = DateTime.now();
    warningTimer?.cancel();
    autoOffTimer?.cancel();

    warningTimer = Timer(Duration(hours: 2), () {
      _showInAppWarning();
    });
  }

  void _showInAppWarning() {
    if (!lightOn) return;

    NotificationManager().addNotification('ไฟเปิดทิ้งไว้ 2 ชั่วโมง');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ไฟเปิดทิ้งไว้ 2 ชั่วโมงแล้ว!'),
        duration: Duration(minutes: 30),
        action: SnackBarAction(
          label: 'ปิดไฟทันที',
          onPressed: () async {
            await _turnOffLight();
          },
        ),
      ),
    );

    autoOffTimer = Timer(Duration(minutes: 30), () async {
      if (lightOn) await _turnOffLight();
    });
  }

  Future<void> _turnOffLight({bool isScheduled = false}) async {
    if (!mounted) return;
    setState(() {
      lightOn = false;
      if (isScheduled) {
        scheduledOnTime = null;   // ล้างเวลาเปิด
        scheduledOffTime = null;  // ล้างเวลาปิด
      }
    });

    await ESP32Service.sendCommand(roomKey, false);
    await _saveTimes();
    warningTimer?.cancel();
    autoOffTimer?.cancel();
    lightOnTime = null;
  }

  Future<void> pickTime(BuildContext context, bool isOnTime) async {
    // ใช้เวลาปัจจุบันเสมอ
    TimeOfDay initialTime = TimeOfDay.now();

    DateTime now = DateTime.now();
    DateTime initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    await showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 250,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: initialDateTime,
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
    await _saveTimes();
  }

  String formatTime(TimeOfDay? t) {
    if (t == null) return '-';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m น.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          'ควบคุมไฟ - $floor $room',
          style: GoogleFonts.prompt(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    lightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: lightOn ? Colors.yellow[600] : Colors.grey[400],
                    size: 150,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () async {
                      setState(() {
                        lightOn = !lightOn;
                      });
                      await ESP32Service.sendCommand(roomKey, lightOn);
                      await _saveTimes();

                      if (lightOn) {
                        onLightTurnedOn();
                      } else {
                        warningTimer?.cancel();
                        autoOffTimer?.cancel();
                        lightOnTime = null;
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: lightOn ? Colors.lightBlue : Colors.grey,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                    ),
                    child: Text(
                      lightOn ? 'ปิดไฟ' : 'เปิดไฟ',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        color: lightOn ? Colors.lightBlue : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'ตั้งเวลาควบคุมไฟ',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('เวลาเปิดไฟ: ${formatTime(scheduledOnTime)}'),
              trailing: Icon(Icons.access_time),
              onTap: () => pickTime(context, true),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('เวลาปิดไฟ: ${formatTime(scheduledOffTime)}'),
              trailing: Icon(Icons.access_time),
              onTap: () => pickTime(context, false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveTimes();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกตั้งเวลาเรียบร้อย')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'บันทึกเวลา',
                style: GoogleFonts.prompt(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
