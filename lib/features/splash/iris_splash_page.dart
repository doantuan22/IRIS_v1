import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/iris_assets.dart';
import '../../core/theme/iris_theme.dart';
import '../../data/local/database.dart';

/// Lớp khởi động ngắn của IRIS. Màn hình chỉ tồn tại trong lúc preload asset
/// thương hiệu và mở kết nối SQLite mà ứng dụng vốn cần trước khi vào Home.
class IrisSplashPage extends StatefulWidget {
  final VoidCallback onReady;

  const IrisSplashPage({super.key, required this.onReady});

  @override
  State<IrisSplashPage> createState() => _IrisSplashPageState();
}

class _IrisSplashPageState extends State<IrisSplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumExposure = Duration(milliseconds: 360);

  late final AnimationController _brandController;
  bool _started = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _brandController = AnimationController(
      vsync: this,
      duration: IrisMotion.screen,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _brandController.value = 1;
    } else {
      _brandController.forward();
    }
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    try {
      await Future.wait([
        AppDatabase.instance.database,
        precacheImage(const AssetImage(IrisAssets.mascotSplashHeart), context),
      ]);
    } catch (error) {
      // Không giữ người dùng ở Splash vô hạn nếu một tác vụ bootstrap lỗi.
      // HomePage vẫn thực hiện lại các Future dữ liệu hiện có và tự hiển thị
      // trạng thái lỗi của từng luồng nếu cần.
      debugPrint('IRIS bootstrap failed: $error');
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumExposure - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;
    setState(() => _ready = true);
    widget.onReady();
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [IrisColors.canvas, IrisColors.primarySoft],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mascotHeight = (constraints.maxHeight * 0.30)
                  .clamp(136.0, 220.0)
                  .toDouble();
              return Stack(
                children: [
                  const _SplashBackdrop(),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(IrisSpacing.xl),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _brandController,
                          curve: Curves.easeOut,
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1).animate(
                            CurvedAnimation(
                              parent: _brandController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: Semantics(
                            label: 'Đang khởi tạo ứng dụng IRIS',
                            liveRegion: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: IrisSpacing.md,
                                    vertical: IrisSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: IrisColors.surface,
                                    borderRadius: IrisRadii.pillBorder,
                                    border: Border.all(
                                      color: IrisColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    'IRIS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: IrisColors.navy900,
                                          letterSpacing: 1.8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: IrisSpacing.xl),
                                Image.asset(
                                  IrisAssets.mascotSplashHeart,
                                  height: mascotHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                  semanticLabel:
                                      'Gấu IRIS đang ôm biểu tượng trái tim',
                                ),
                                const SizedBox(height: IrisSpacing.xl),
                                Text(
                                  'Đồng hành cùng sự phát triển của trẻ',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: IrisColors.navy800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: IrisSpacing.sm),
                                Text(
                                  _ready ? 'Sẵn sàng' : 'Đang chuẩn bị…',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: IrisSpacing.md),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 220,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: _ready ? 1 : 0.62,
                                    minHeight: 6,
                                    borderRadius: IrisRadii.pillBorder,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -84,
            right: -64,
            child: _BackdropOrb(size: 220, color: IrisColors.splashGlow),
          ),
          Positioned(
            bottom: -112,
            left: -76,
            child: _BackdropOrb(size: 252, color: IrisColors.primarySoft),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
