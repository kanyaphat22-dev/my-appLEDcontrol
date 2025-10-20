import 'package:flutter/material.dart';

class RoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลชั้นจาก arguments
    final String floor = ModalRoute.of(context)!.settings.arguments as String;
    final floorNumber = int.tryParse(floor.replaceAll(RegExp(r'[^0-9]'), ''));

    final buildingNumber = '66'; // เลขตึกนำ
    List<Map<String, String>> rooms = [];

    if (floorNumber != null) {
      // ✅ ชั้น 1–4 (เฉพาะพื้นที่พิเศษ)
      if (floorNumber == 1) {
        rooms = [
          {'label': 'หน้าลิฟท์', 'value': 'F1_Lift'},
          {'label': 'ลานจอดรถ', 'value': 'F1_Parking'},
        ];
      } else if (floorNumber == 2) {
        rooms = [
          {'label': 'หน้าลิฟท์', 'value': 'F2_Lift'},
          {'label': 'ห้องสโมสร', 'value': 'F2_Club'},
          {'label': 'ห้องชมรมดนตรี', 'value': 'F2_MusicRoom'},
          {'label': 'ทางเดินหน้าห้อง', 'value': 'F2_Corridor'},
          {'label': 'บริเวณโรงอาหาร', 'value': 'F2_Canteen'},
        ];
      } else if (floorNumber == 3) {
        rooms = [
          {'label': 'หน้าลิฟท์', 'value': 'F3_Lift'},
          {'label': 'สำนักงานคณะวิศวกรรมศาสตร์', 'value': 'F3_Office'},
          {'label': 'ห้องประชุมศรีวิศว', 'value': 'F3_SriWiswa'},
          {'label': 'ห้องประชุมกัลปพฤษ', 'value': 'F3_Kanlapapruk'},
        ];
      } else if (floorNumber == 4) {
        rooms = [
          {'label': 'หน้าลิฟท์', 'value': 'F4_Lift'},
          {'label': 'ห้อง Co-Working Spaces', 'value': 'F4_CoWorking'},
          {'label': 'ห้องควบคุม', 'value': 'F4_ControlRoom'},
        ];
      }

      // ✅ ชั้น 5–10 (เหมือนเดิม)
      else if (floorNumber >= 5) {
        // เพิ่ม "หน้าลิฟท์" สำหรับชั้น 5-10
        if (floorNumber <= 10) {
          rooms.add({'label': 'หน้าลิฟท์', 'value': 'F${floorNumber}_Lift'});
        }

        // ห้องพิเศษบนสุด
        rooms.addAll([
          {'label': 'ห้องโถง', 'value': 'F${floorNumber}_Hall'},
          {'label': 'ทางเดิน', 'value': 'F${floorNumber}_Corridor'},
        ]);

        // ✅ กำหนดจำนวนห้องปกติตามชั้น
        int roomCount = 9; // ค่าเริ่มต้น
        if (floorNumber == 10) roomCount = 9;
        if (floorNumber == 9) roomCount = 9;
        if (floorNumber == 8) roomCount = 8;
        if (floorNumber == 7) roomCount = 9;
        if (floorNumber == 6) roomCount = 7;
        if (floorNumber == 5) roomCount = 10;

        // ✅ สร้างห้องปกติ
        final normalRooms = List.generate(roomCount, (index) {
          final roomNumber = (index + 1).toString().padLeft(2, '0');
          final fullNumber = '$buildingNumber${floorNumber}$roomNumber';
          return {'label': 'ห้อง $fullNumber', 'value': fullNumber};
        });

        rooms.addAll(normalRooms);
      }
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
                style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                        boxShadow: const [
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
