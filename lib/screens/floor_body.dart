import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloorBody extends StatefulWidget {
  const FloorBody({super.key});

  @override
  State<FloorBody> createState() => _FloorBodyState();
}

class _FloorBodyState extends State<FloorBody> {
  final List<String> floors = [
    'ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4', 'ชั้น 5',
    'ชั้น 6', 'ชั้น 7', 'ชั้น 8', 'ชั้น 9', 'ชั้น 10',
  ];

  final List<String> floorImages = List.filled(10, 'assets/logo.png');

  List<String> favoriteFloors = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteFloors = prefs.getStringList('favoriteFloors') ?? [];
    });
  }

  Future<void> _toggleFavorite(String floor) async {
    setState(() {
      if (favoriteFloors.contains(floor)) {
        favoriteFloors.remove(floor);
      } else {
        favoriteFloors.add(floor);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteFloors', favoriteFloors);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('FloorBody'),
      slivers: [
        // ชื่อหน้า My Home
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
            child: const Text(
              'My Home',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // กล่องหัวเรื่อง - ข้อความชิดซ้ายบน ไม่มีไอคอน
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF49C2F2), Color(0xFF7AD8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'แอปพลิเคชั่นควบคุมแสงสว่าง\nอาคารศรีวิศววิทยา',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ชื่อ Section Floor
        SliverToBoxAdapter(
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Floor',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Grid ของชั้น
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 30,
              mainAxisSpacing: 30,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final isFavorite = favoriteFloors.contains(floors[index]);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pushNamed(context, '/room',
                          arguments: floors[index]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 1)
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    floorImages[index],
                                    width: 90,
                                    height: 90,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  floors[index],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _toggleFavorite(floors[index]),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? const Color.fromARGB(255, 134, 229, 248)
                                    : Colors.grey,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: floors.length,
            ),
          ),
        ),
      ],
    );
  }
}
