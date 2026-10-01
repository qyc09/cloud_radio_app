import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

import 'package:cloud_radio_app/controllers/player_controller.dart';
import 'package:cloud_radio_app/page/dict_page.dart';
import 'package:cloud_radio_app/page/favorites_page.dart';
import 'package:cloud_radio_app/page/radio_page.dart';
import 'package:cloud_radio_app/services/audio_handler.dart';
import 'package:cloud_radio_app/theme.dart';
import 'package:cloud_radio_app/widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // audio_service：Android/iOS 后台播放 + 通知栏遥控；
  // 不支持的平台（如 Windows 桌面）自动降级为裸播放器。
  RadioAudioHandler handler;
  try {
    handler = await AudioService.init(
      builder: () => RadioAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'app.chaoshan.radio.playback',
        androidNotificationChannelName: '潮汕电台播放',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    handler = RadioAudioHandler();
  }

  runApp(RadioApp(handler: handler));
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key, required this.handler});

  final RadioAudioHandler handler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '潮汕电台',
      debugShowCheckedModeBanner: false,
      theme: buildRadioTheme(),
      home: HomePage(handler: handler),
    );
  }
}

/// 底部三页外壳：电台 / 收藏 / 辞典 + 悬浮播放状态栏
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.handler});

  final RadioAudioHandler handler;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PlayerController _player;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _player = PlayerController(widget.handler);
    _player.onMessage = _snack;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _tab,
                children: [
                  RadioPage(controller: _player),
                  FavoritesPage(controller: _player),
                  const DictPage(),
                ],
              ),
            ),
          ),
          // 播放状态栏悬浮在导航栏上方
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: MiniPlayerBar(
              controller: _player,
              onOpenSleepSheet: _showSleepSheet,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: kCard,
        indicatorColor: kAccent.withOpacity(.18),
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radio_rounded),
            selectedIcon: Icon(Icons.radio_rounded),
            label: '电台',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: '收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: '辞典',
          ),
        ],
      ),
    );
  }

  // ---------- 倒计时弹窗 ----------

  void _showSleepSheet() {
    const presets = [15, 30, 45, 60, 90];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return AnimatedBuilder(
          animation: _player,
          builder: (context, _) {
            final remain = _player.sleepRemaining;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: kAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text('倒计时停止',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (remain != null)
                          Text('剩余 ${formatDuration(remain)}',
                              style: const TextStyle(
                                  fontSize: 12.5, color: kAccent)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('到时自动暂停播放',
                        style: TextStyle(fontSize: 12, color: kTextDim)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final m in presets)
                          GestureDetector(
                            onTap: () {
                              _player.setSleep(Duration(minutes: m));
                              Navigator.of(sheetCtx).pop();
                              _snack('将在 $m 分钟后自动暂停播放');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: kCardDeep,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(.06)),
                              ),
                              child: Text('$m 分钟',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                    if (remain != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _player.setSleep(null);
                            Navigator.of(sheetCtx).pop();
                            _snack('已取消倒计时');
                          },
                          icon: const Icon(Icons.timer_off, size: 18),
                          label: const Text('取消倒计时'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextDim,
                            side: BorderSide(
                                color: Colors.white.withOpacity(.12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: kCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }
}
