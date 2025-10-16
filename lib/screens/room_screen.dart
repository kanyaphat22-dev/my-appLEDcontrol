import 'package:flutter/material.dart';

class RoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลชั้นจาก arguments
    final String floor = ModalRoute.of(context)!.settings.arguments as String;
    final floorNumber = int.tryParse(floor.replaceAll(RegExp(r'[^0-9]'), ''));

    final buildingNumber = '66'; // เลขตึกนำ
    List<Map<String, String>> rooms = [];

    if (floorNumber != null && floorNumber >= 5) {
      // เพิ่ม "หน้าลิฟท์" สำหรับชั้น 5-10
      if (floorNumber <= 10) {
        rooms.add({'label': 'หน้าลิฟท์', 'value': 'F${floorNumber}_Lift'});
      }

      // ห้องพิเศษบนสุด
      rooms.addAll([
        {'label': 'ห้องโถง', 'value': 'F${floorNumber}_Hall'},
        {'label': 'ทางเดิน', 'value': 'F${floorNumber}_Corridor'},
      ]);

      // ห้องปกติ 9 ห้อง
      final normalRooms = List.generate(9, (index) {
        final roomNumber = (index + 1).toString().padLeft(2, '0');
        final fullNumber = '$buildingNumber${floorNumber}$roomNumber';
        return {'label': 'ห้อง $fullNumber', 'value': fullNumber};
      });

      rooms.addAll(normalRooms);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกห้อง - $floor'),
        backgroundColor: const Color.fromARGB(255, 131, 202, 246),
      ),
      body: rooms.isEmpty
          ? Center(
              child: Text(
                'ชั้นนี้ไม่มีห้องให้เลือก',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/control',
                        arguments: {
                          'floor': floor,
                          'room': room['value'], // ส่งค่า roomKey ไปหน้า Control
                        },
                      );
                    },
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            room['label']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
