import 'package:flutter/material.dart';

import 'core/theme/iris_theme.dart';
import 'features/home/home_page.dart';

/// Widget gốc của ứng dụng IRIS — cấu hình MaterialApp, theme và route ban đầu.
class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS',
      debugShowCheckedModeBanner: false,
      theme: IrisTheme.light,
      home: const HomePage(),
    );
  }
}
