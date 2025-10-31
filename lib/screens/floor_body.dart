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
  bool _showLoginSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool justLoggedIn = prefs.getBool('justLoggedIn') ?? false;

    if (justLoggedIn) {
      _showLoginNotification();
      prefs.setBool('justLoggedIn', false);
    }
  }

  Future<void> _showLoginNotification() async {
    setState(() => _showLoginSuccess = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showLoginSuccess = false);
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
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: true,
      bottom: true,
      child: Stack(
        children: [
          CustomScrollView(
            key: const PageStorageKey('FloorBody'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 🔹 หัวข้อ My Home
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: const Text(
                    'My Home',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // 🔹 รูปภาพด้านบน
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/engineer.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),

              // 🔹 หัวข้ออาคาร
              SliverToBoxAdapter(
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'อาคารศรีวิศววิทยา',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 🔹 Grid รายการชั้น
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 35,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final isFavorite =
                          favoriteFloors.contains(floors[index]);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushNamed(context, '/room',
                                arguments: floors[index]);
                          },
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // ✅ ป้องกัน overflow ด้วย FittedBox
                                Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.asset(
                                            floorImages[index],
                                            width: 90,
                                            height: 90,
                                          ),
                                        ),
                                        const SizedBox(height: 6), // 🔹 ลดช่องว่างลง
                                        Text(
                                          floors[index],
                                          style: const TextStyle(
                                            fontSize: 16, // ✅ ปรับขนาดฟอนต์ให้เล็กลง
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                          ? const Color.fromARGB(
                                              255, 134, 229, 248)
                                          : Colors.grey,
                                      size: 26, // 🔹 ลดขนาดไอคอนให้สมดุลกับฟอนต์
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

              // 🔹 Spacer ด้านล่าง
              SliverToBoxAdapter(
                child: SizedBox(height: bottomInset + 20),
              ),
            ],
          ),

          // ✅ แจ้งเตือนเข้าสู่ระบบสำเร็จ
          if (_showLoginSuccess)
            Positioned(
              top: 85,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showLoginSuccess ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'เข้าสู่ระบบสำเร็จ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
