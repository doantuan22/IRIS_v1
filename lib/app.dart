import 'package:flutter/material.dart';

import 'features/child_profile/child_list_page.dart';

/// Widget gốc của ứng dụng IRIS — cấu hình MaterialApp, theme và route ban đầu.
class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const ChildListPage(),
    );
  }
}
