import 'package:flutter/material.dart';
import 'notification_manager.dart';

class NotificationBody extends StatefulWidget {
  const NotificationBody({super.key});

  @override
  State<NotificationBody> createState() => _NotificationBodyState();
}

class _NotificationBodyState extends State<NotificationBody> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: NotificationManager().notifications,
      builder: (context, notifications, _) {
        return Column(
          children: [
            // 🔵 Header
            Container(
              width: double.infinity,
              color: const Color(0xFF83CAF6),
              child: SafeArea(
                bottom: false,
                child: Container(
                  height: 80, // ✅ ความสูงกำลังดี
                  alignment: Alignment.bottomLeft, // ✅ ชิดล่างมากขึ้น
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), // ✅ ดันฟอนต์ลงเล็กน้อย
                  child: const Text(
                    'การแจ้งเตือน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // 🧾 Body
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Text(
                        'ยังไม่มีการแจ้งเตือน',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final noti = notifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
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
                                const Icon(
                                  Icons.notifications,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        noti["title"]!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        noti["time"]!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
