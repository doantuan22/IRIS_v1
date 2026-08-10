import 'package:flutter/material.dart';

/// Widget gốc của ứng dụng IRIS — cấu hình MaterialApp, theme và route ban đầu.
class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const Scaffold(
        body: Center(child: Text('IRIS — sàng lọc & đánh giá phát triển trẻ')),
      ),
    );
  }
}
