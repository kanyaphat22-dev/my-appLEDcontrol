import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/floor_body.dart';
import '../screens/favorite_body.dart';
import '../screens/notification_body.dart';
import '../screens/settings_body.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _pages = const [
    FloorBody(),
    FavoriteBody(),
    NotificationBody(),
    SettingsBody(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeBottom: true,
      removeTop: true,
      context: context,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,

          // ✅ เนื้อหาหลัก
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              final beginOffset = _selectedIndex > _previousIndex
                  ? const Offset(1, 0)
                  : const Offset(-1, 0);
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              );
              final offsetAnimation = Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(curvedAnimation);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            child: _pages[_selectedIndex],
            layoutBuilder: (currentChild, previousChildren) => currentChild!,
          ),

          // ✅ แถบล่าง (ปรับให้สูงขึ้น + ไอคอนขยับขึ้น)
          bottomNavigationBar: Container(
            height: 72, // ⬆ เพิ่มจาก 60 → 72
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(30, 0, 0, 0),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surfaceTint: Colors.transparent,
                    ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.blueAccent,
                unselectedItemColor: const Color.fromARGB(255, 45, 45, 45),
                type: BottomNavigationBarType.fixed,
                iconSize: 28, // ⬆ ขยายไอคอนเล็กน้อย
                selectedFontSize: 12, // ⬆ ขนาดฟอนต์เล็กน้อย
                unselectedFontSize: 12,
                onTap: _onItemTapped,
                items: [
                  _navItem(Icons.home_outlined, Icons.home, 'หน้าหลัก', 0),
                  _navItem(Icons.favorite_border, Icons.favorite, 'รายการโปรด', 1),
                  _navItem(Icons.notifications_none, Icons.notifications, 'แจ้งเตือน', 2),
                  _navItem(Icons.settings_outlined, Icons.settings, 'ตั้งค่า', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(
      IconData outlineIcon, IconData filledIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0), // ⬆ ยกไอคอนขึ้นนิดนึง
        child: Icon(
          _selectedIndex == index ? filledIcon : outlineIcon,
        ),
      ),
      label: label,
    );
  }
}
