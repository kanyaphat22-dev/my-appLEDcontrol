import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBody extends StatefulWidget {
  const FavoriteBody({super.key});

  @override
  State<FavoriteBody> createState() => _FavoriteBodyState();
}

class _FavoriteBodyState extends State<FavoriteBody> {
  List<String> favoriteFloors = [];

  final List<String> floors = [
    'ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4', 'ชั้น 5',
    'ชั้น 6', 'ชั้น 7', 'ชั้น 8', 'ชั้น 9', 'ชั้น 10',
  ];

  final List<String> floorImages = List.filled(10, 'assets/logo.png');

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

  @override
  Widget build(BuildContext context) {
    final favoriteData = floors
        .asMap()
        .entries
        .where((entry) => favoriteFloors.contains(entry.value))
        .toList();

    return Column(
      children: [
        // Header เต็มขอบบน
        Container(
          width: double.infinity, // เต็มความกว้าง
          color: const Color.fromARGB(255, 131, 202, 246),
          child: SafeArea(
            bottom: false, // ไม่เว้นด้านล่าง
            child: Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'รายการโปรด',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Body รายการโปรด
        Expanded(
          child: favoriteData.isEmpty
              ? Center(
                  child: Text(
                    'ยังไม่มีรายการโปรด',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey('FavoriteBody'),
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteData.length,
                  itemBuilder: (context, index) {
                    final floorName = favoriteData[index].value;
                    final floorImage = floorImages[floors.indexOf(floorName)];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(context, '/room', arguments: floorName);
                        },
                        child: Container(
                          height: 80,
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
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12)),
                                child: Image.asset(
                                  floorImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  floorName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey, size: 18),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
