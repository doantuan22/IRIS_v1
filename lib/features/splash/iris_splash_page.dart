import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/iris_theme.dart';
import '../../core/widgets/iris_ui.dart';
import '../../data/local/database.dart';
import '../../domain/services/ai_connectivity_service.dart';

/// Splash ngắn, không chờ kết nối AI chặn khởi động ứng dụng.
class IrisSplashPage extends StatefulWidget {
  final VoidCallback onReady;
  const IrisSplashPage({super.key, required this.onReady});
  @override
  State<IrisSplashPage> createState() => _IrisSplashPageState();
}

class _IrisSplashPageState extends State<IrisSplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumExposure = Duration(seconds: 3);
  late final AnimationController _brandController;
  bool _started = false;
  bool _ready = false;

  String _connectivityLabel(AiConnectivityState state) {
    if (state.isChecking || (!state.isConnected && !state.hasIssue)) {
      return 'Đang kiểm tra kết nối AI...';
    }
    return state.isConnected
        ? 'Kết nối AI thành công'
        : 'Kết nối AI đang gặp vấn đề';
  }

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
    unawaited(AiConnectivityService.instance.checkInitialConnectivity());
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    try {
      await AppDatabase.instance.database;
    } catch (error) {
      debugPrint('IRIS bootstrap failed: $error');
    }
    final remaining = _minimumExposure - DateTime.now().difference(startedAt);
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
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [IrisColors.canvas, IrisColors.primarySoft],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            const IrisPageBackdrop(),
            Center(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _brandController,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(
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
                        const IrisBrandWordmark(fontSize: 64),
                        const SizedBox(height: IrisSpacing.sm),
                        Text(
                          'PHÁT TRIỂN CÙNG CON',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: IrisColors.blue700,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: IrisSpacing.xl),
                        Container(
                          width: 82,
                          height: 82,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: IrisColors.surface.withValues(alpha: .85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: IrisColors.primarySoft,
                              width: 2,
                            ),
                            boxShadow: IrisShadows.soft,
                          ),
                          child: const SizedBox(
                            width: 45,
                            height: 45,
                            child: CircularProgressIndicator(strokeWidth: 4),
                          ),
                        ),
                        const SizedBox(height: IrisSpacing.lg),
                        Text(
                          'Đang khởi động hệ thống',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: IrisColors.navy800),
                        ),
                        const SizedBox(height: IrisSpacing.sm),
                        ValueListenableBuilder<AiConnectivityState>(
                          valueListenable:
                              AiConnectivityService.instance.stateNotifier,
                          builder: (context, state, _) {
                            final color = state.isConnected
                                ? IrisColors.success
                                : state.hasIssue
                                ? IrisColors.danger
                                : IrisColors.primary;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: IrisSpacing.xs),
                                Text(
                                  _connectivityLabel(state),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: IrisSpacing.md),
                        SizedBox(
                          width: 220,
                          child: LinearProgressIndicator(
                            value: _ready ? 1 : .62,
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
          ],
        ),
      ),
    ),
  );
}
