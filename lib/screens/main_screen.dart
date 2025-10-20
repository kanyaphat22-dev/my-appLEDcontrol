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

          // ✅ แถบล่าง (บางลง + ไม่มีเงาเวลากด)
          bottomNavigationBar: Container(
            height: 60,
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
                splashColor: Colors.transparent, // 🚫 ปิด splash เวลากด
                highlightColor: Colors.transparent, // 🚫 ปิด highlight เวลากด
                splashFactory: NoSplash.splashFactory, // 🚫 ปิด ripple effect
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surfaceTint: Colors.transparent, // 🚫 ปิด tint เงา
                    ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.blueAccent,
                unselectedItemColor: const Color.fromARGB(255, 45, 45, 45),
                type: BottomNavigationBarType.fixed,
                iconSize: 26,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                onTap: _onItemTapped,
                items: [
                  BottomNavigationBarItem(
                    icon: _selectedIndex == 0
                        ? const Icon(Icons.home)
                        : const Icon(Icons.home_outlined),
                    label: 'หน้าหลัก',
                  ),
                  BottomNavigationBarItem(
                    icon: _selectedIndex == 1
                        ? const Icon(Icons.favorite)
                        : const Icon(Icons.favorite_border),
                    label: 'รายการโปรด',
                  ),
                  BottomNavigationBarItem(
                    icon: _selectedIndex == 2
                        ? const Icon(Icons.notifications)
                        : const Icon(Icons.notifications_none),
                    label: 'แจ้งเตือน',
                  ),
                  BottomNavigationBarItem(
                    icon: _selectedIndex == 3
                        ? const Icon(Icons.settings)
                        : const Icon(Icons.settings_outlined),
                    label: 'ตั้งค่า',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
