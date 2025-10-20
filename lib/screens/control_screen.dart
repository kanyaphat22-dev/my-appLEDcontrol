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
  bool lightOn1 = false;
  bool lightOn2 = false;
  bool dualMode = false;

  String selectedSwitch = "SW1";

  TimeOfDay? scheduledOnTime;
  TimeOfDay? scheduledOffTime;
  Timer? onTimer;
  Timer? offTimer;
  Timer? statusTimer;

  Timer? checkTimer1;
  Timer? checkTimer2;

  String floor = "";
  String room = "";
  String roomKey = "";

  bool _isDropdownVisible = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (roomKey.isEmpty) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      floor = args['floor'] as String;
      room = args['room'] as String;
      roomKey = "${floor}_${room}";
      dualMode = room.contains("Hall") || room.contains("Corridor");
      _loadSavedTimesAndStatus();
    }
  }

  @override
  void initState() {
    super.initState();
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
    checkTimer1?.cancel();
    checkTimer2?.cancel();
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
    super.dispose();
  }

  // ✅ ป้องกัน setState หลัง dispose
  @override
  void setState(VoidCallback fn) {
    if (!mounted) {
      debugPrint("⚠️ setState ถูกเรียกหลัง dispose ที่ ${DateTime.now()}");
      return;
    }
    super.setState(fn);
  }

  Future<void> _fetchLightStatusFromESP32() async {
    if (!mounted) return;

    try {
      if (dualMode) {
        bool skip1 = checkTimer1 != null && checkTimer1!.isActive;
        bool skip2 = checkTimer2 != null && checkTimer2!.isActive;

        bool? status1;
        bool? status2;

        if (!skip1) status1 = await ESP32Service.getLightStatus("${roomKey}_1");
        if (!skip2) status2 = await ESP32Service.getLightStatus("${roomKey}_2");

        if (!mounted) return;
        setState(() {
          if (status1 != null) lightOn1 = status1;
          if (status2 != null) lightOn2 = status2;
        });
      } else {
        bool skip = checkTimer1 != null && checkTimer1!.isActive;
        if (!skip) {
          bool status = await ESP32Service.getLightStatus(roomKey);
          if (!mounted) return;
          setState(() => lightOn1 = status);
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('ไม่สามารถดึงสถานะไฟจาก ESP32: $e');
    }
  }

  Future<void> _loadSavedTimesAndStatus() async {
    final prefs = await SharedPreferences.getInstance();

    selectedSwitch = prefs.getString('${roomKey}_selectedSwitch') ?? "SW1";

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

  Future<void> _saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('${roomKey}_selectedSwitch', selectedSwitch);

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
          ? onDateTime.add(const Duration(days: 1)).difference(now)
          : onDateTime.difference(now);

      onTimer = Timer(onDelay, () async {
        if (!mounted) return;
        await _sendCommand(true,
            fixedIndex: selectedSwitch == "SW1" ? 1 : 2);
        await _saveTimes();
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
          ? offDateTime.add(const Duration(days: 1)).difference(now)
          : offDateTime.difference(now);

      offTimer = Timer(offDelay, () async {
        if (!mounted) return;
        await _sendCommand(false,
            fixedIndex: selectedSwitch == "SW1" ? 1 : 2);

        final prefs = await SharedPreferences.getInstance();
        prefs.remove('${roomKey}_onHour');
        prefs.remove('${roomKey}_onMinute');
        prefs.remove('${roomKey}_offHour');
        prefs.remove('${roomKey}_offMinute');

        if (!mounted) return;
        setState(() {
          scheduledOnTime = null;
          scheduledOffTime = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⏰ ถึงเวลาปิดไฟแล้ว ระบบล้างเวลาที่ตั้งไว้เรียบร้อย'),
            ),
          );
        }
      });
    }
  }

  Future<void> _sendCommand(bool turnOn, {int? fixedIndex}) async {
    if (!mounted) return;
    if (dualMode) {
      int index = fixedIndex ?? (selectedSwitch == "SW1" ? 1 : 2);
      String target = "${roomKey}_$index";
      await ESP32Service.sendCommand(target, turnOn);
      if (!mounted) return;
      setState(() {
        if (index == 1) {
          lightOn1 = turnOn;
        } else {
          lightOn2 = turnOn;
        }
      });
    } else {
      await ESP32Service.sendCommand(roomKey, turnOn);
      if (!mounted) return;
      setState(() => lightOn1 = turnOn);
    }
  }

  Future<void> _toggleLight(int index) async {
    if (!mounted) return;
    if (dualMode) {
      if (index == 1) {
        lightOn1 = !lightOn1;
        await ESP32Service.sendCommand("${roomKey}_1", lightOn1);
        if (!mounted) return;
        setState(() {});

        if (lightOn1) {
          checkTimer1?.cancel();
          checkTimer1 = Timer(const Duration(seconds: 5), () async {
            if (!mounted) return;
            bool actualStatus =
                await ESP32Service.getLightStatus("${roomKey}_1");
            if (!mounted) return;
            if (!actualStatus) {
              setState(() => lightOn1 = false);
              print("⚠️ หลอด 1 ไม่ติดจริง ดับในแอป");
            }
          });
        } else {
          checkTimer1?.cancel();
        }
      } else {
        lightOn2 = !lightOn2;
        await ESP32Service.sendCommand("${roomKey}_2", lightOn2);
        if (!mounted) return;
        setState(() {});

        if (lightOn2) {
          checkTimer2?.cancel();
          checkTimer2 = Timer(const Duration(seconds: 5), () async {
            if (!mounted) return;
            bool actualStatus =
                await ESP32Service.getLightStatus("${roomKey}_2");
            if (!mounted) return;
            if (!actualStatus) {
              setState(() => lightOn2 = false);
              print("⚠️ หลอด 2 ไม่ติดจริง ดับในแอป");
            }
          });
        } else {
          checkTimer2?.cancel();
        }
      }
    } else {
      lightOn1 = !lightOn1;
      await ESP32Service.sendCommand(roomKey, lightOn1);
      if (!mounted) return;
      setState(() {});

      if (lightOn1) {
        checkTimer1?.cancel();
        checkTimer1 = Timer(const Duration(seconds: 5), () async {
          if (!mounted) return;
          bool actualStatus = await ESP32Service.getLightStatus(roomKey);
          if (!mounted) return;
          if (!actualStatus) {
            setState(() => lightOn1 = false);
            print("⚠️ หลอดไม่ติดจริง ดับในแอป");
          }
        });
      } else {
        checkTimer1?.cancel();
      }
    }

    await _saveTimes();
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
    if (mounted) setState(() => _isDropdownVisible = false);
  }

  void _showAnimatedDropdown() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _dropdownOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: position.dx,
          top: position.dy + size.height + 6,
          width: size.width,
          child: _AnimatedDropdownMenu(
            selected: selectedSwitch,
            dualMode: dualMode,
            onSelect: (value) async {
              if (!mounted) return;
              setState(() => selectedSwitch = value);
              await _saveTimes();
              _removeDropdown();
            },
          ),
        );
      },
    );

    if (mounted) {
      overlay.insert(_dropdownOverlay!);
      setState(() => _isDropdownVisible = true);
    }
  }

  Future<void> pickTime(BuildContext context, bool isOnTime) async {
    if (!mounted) return;
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
      builder: (_) => SizedBox(
        height: 250,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: initialDateTime,
          use24hFormat: true,
          onDateTimeChanged: (DateTime dt) {
            if (!mounted) return;
            setState(() {
              if (isOnTime) {
                scheduledOnTime =
                    TimeOfDay(hour: dt.hour, minute: dt.minute);
              } else {
                scheduledOffTime =
                    TimeOfDay(hour: dt.hour, minute: dt.minute);
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
        backgroundColor: const Color.fromARGB(255, 131, 202, 246),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            statusTimer?.cancel();
            checkTimer1?.cancel();
            checkTimer2?.cancel();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'ควบคุมไฟ - $floor $room',
          style: GoogleFonts.prompt(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 280,
              padding:
                  const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
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
            ),
            const SizedBox(height: 30),

            // 🔹 ตั้งเวลา
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 15,
                      offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('ตั้งเวลาควบคุมไฟ',
                        style: GoogleFonts.prompt(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  Text('กรุณาเลือกสวิทซ์',
                      style: GoogleFonts.prompt(
                          fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: GestureDetector(
                      key: _buttonKey,
                      onTap: _toggleDropdown,
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.lightBlue.shade300, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          selectedSwitch,
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    tileColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('เวลาเปิดไฟ: ${formatTime(scheduledOnTime)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => pickTime(context, true),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    tileColor: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('เวลาปิดไฟ: ${formatTime(scheduledOffTime)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => pickTime(context, false),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveTimes();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกตั้งเวลาเรียบร้อย')),
                      );
                      _scheduleTimers();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('บันทึกเวลา',
                        style: GoogleFonts.prompt(
                            fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightColumn(int index, bool lightOn) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          lightOn ? Icons.lightbulb : Icons.lightbulb_outline,
          color: lightOn ? Colors.yellow[600] : Colors.grey[400],
          size: 110,
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => _toggleLight(index),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: lightOn ? Colors.lightBlue : Colors.grey,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
          ),
          child: Text(
            lightOn
                ? (dualMode ? 'ปิดไฟ $index' : 'ปิดไฟ')
                : (dualMode ? 'เปิดไฟ $index' : 'เปิดไฟ'),
            style: GoogleFonts.prompt(
              fontSize: 16,
              color: lightOn ? Colors.lightBlue : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// 🔹 Dropdown menu animation widget
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
  State<_AnimatedDropdownMenu> createState() => _AnimatedDropdownMenuState();
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
    _fade =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween(begin: const Offset(0, -0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = ["SW1", if (widget.dualMode) "SW2"];
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((e) {
                final isSelected = widget.selected == e;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onSelect(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e, style: GoogleFonts.prompt(fontSize: 16)),
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.lightBlue),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
