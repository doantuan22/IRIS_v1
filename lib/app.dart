import 'package:flutter/material.dart';

import 'core/theme/iris_theme.dart';
import 'features/home/home_page.dart';
import 'features/splash/iris_splash_page.dart';

/// Widget gốc của ứng dụng IRIS — cấu hình MaterialApp, theme và route ban đầu.
class IrisApp extends StatefulWidget {
  const IrisApp({super.key});

  @override
  State<IrisApp> createState() => _IrisAppState();
}

class _IrisAppState extends State<IrisApp> {
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRIS',
      debugShowCheckedModeBanner: false,
      theme: IrisTheme.light,
      home: AnimatedSwitcher(
        duration: IrisMotion.screen,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _isReady
            ? const HomePage(key: ValueKey('iris-home'))
            : IrisSplashPage(
                key: const ValueKey('iris-splash'),
                onReady: () => setState(() => _isReady = true),
              ),
      ),
    );
  }
}
