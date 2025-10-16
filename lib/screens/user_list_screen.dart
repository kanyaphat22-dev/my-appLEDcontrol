import 'package:flutter/material.dart';

class UserListScreen extends StatelessWidget {
  // ตัวอย่างข้อมูลผู้ใช้งานล่าสุด
  final List<Map<String, String>> users = [
    {'name': 'สมชาย ใจดี', 'role': 'อาจารย์', 'lastLogin': '2025-08-09 15:20'},
    {'name': 'นางสาวสุนิสา แสนสุข', 'role': 'นักศึกษา', 'lastLogin': '2025-08-09 14:45'},
    {'name': 'นายกิตติ พงษ์เจริญ', 'role': 'นักศึกษา', 'lastLogin': '2025-08-09 14:10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายชื่อผู้ใช้งานล่าสุด'),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(user['name']!),
            subtitle: Text('${user['role']} - เข้าใช้งานล่าสุด: ${user['lastLogin']}'),
          );
        },
      ),
    );
  }
}
