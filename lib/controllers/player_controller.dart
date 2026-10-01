import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_radio_app/api/radio_api.dart';
import 'package:cloud_radio_app/models/station.dart';
import 'package:cloud_radio_app/services/audio_handler.dart';

/// 全局状态中枢：电台列表 / 收藏 / 播放 / 倒计时。
/// 页面里用 AnimatedBuilder(animation: controller) 监听刷新。
class PlayerController extends ChangeNotifier {
  PlayerController(this._audio) {
    _subs.add(_audio.player.stream.playing.listen((v) {
      playing = v;
      _notify();
    }));
    _subs.add(_audio.player.stream.buffering.listen((v) {
      buffering = v;
      _notify();
    }));
    _subs.add(_audio.player.stream.error.listen((e) {
      onMessage?.call('播放出错：$e');
    }));
    loadFavorites();
  }

  final RadioAudioHandler _audio;
  final RadioApi _api = RadioApi();
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _sleepTicker;
  bool _disposed = false;

  /// UI 弹提示用的回调（SnackBar）
  void Function(String msg)? onMessage;

  // ---- 电台列表 ----
  List<Station>? all;
  bool loadingStations = false;
  String? loadError;

  // ---- 收藏 ----
  final Map<String, Station> favorites = {}; // key: contentId

  // ---- 播放状态 ----
  Station? now; // 当前选中的台
  Station? lastNow; // 收起状态栏动画期间占位用
  bool playing = false;
  bool buffering = false;

  // ---- 倒计时停止 ----
  DateTime? sleepEnd;

  bool get miniVisible => now != null;
  Station? get miniStation => now ?? lastNow;

  Duration? get sleepRemaining {
    final e = sleepEnd;
    if (e == null) return null;
    final d = e.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  // ---------- 电台列表 ----------

  Future<void> loadStations() async {
    loadingStations = true;
    loadError = null;
    _notify();
    try {
      all = await _api.fetchStations();
    } catch (e) {
      loadError = e.toString();
    }
    loadingStations = false;
    _notify();
  }

  // ---------- 收藏 ----------

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('favorite_stations');
      if (raw != null && raw.isNotEmpty) {
        final list = (json.decode(raw) as List)
            .map((e) => Station.fromStored(e as Map<String, dynamic>));
        for (final s in list) {
          favorites[s.contentId] = s;
        }
        _notify();
      }
    } catch (_) {
      // 收藏读取失败不影响主流程
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(favorites.values.map((s) => s.toJson()).toList());
      await prefs.setString('favorite_stations', raw);
    } catch (_) {}
  }

  bool isFav(Station s) => favorites.containsKey(s.contentId);

  void toggleFav(Station s) {
    if (favorites.containsKey(s.contentId)) {
      favorites.remove(s.contentId);
    } else {
      favorites[s.contentId] = s;
    }
    _notify();
    _saveFavorites();
  }

  // ---------- 播放 ----------

  Future<void> play(Station s) async {
    // 同一台再点一次 => 播放/暂停切换
    if (now?.contentId == s.contentId) {
      if (playing) {
        await _audio.pause();
      } else {
        await _audio.play();
      }
      return;
    }

    now = s;
    lastNow = s;
    buffering = true;
    _notify();
    try {
      // 流地址有时效，播放前实时刷新
      final freshList = await _api.fetchStations();
      all ??= freshList;
      final fresh = freshList.firstWhere(
        (x) => x.contentId == s.contentId,
        orElse: () => s,
      );
      if (fresh.bestUrl.isEmpty) {
        throw Exception('该电台暂无可用播放地址');
      }
      await _audio.open(fresh, fresh.bestUrl);
    } catch (e) {
      now = null;
      buffering = false;
      _notify();
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      onMessage?.call('播放失败：$msg');
    }
  }

  void togglePlay() {
    if (now == null) return;
    if (playing) {
      _audio.pause();
    } else {
      _audio.play();
    }
  }

  Future<void> stop() async {
    try {
      await _audio.stop();
    } catch (_) {}
    now = null;
    _notify();
  }

  // ---------- 倒计时停止 ----------

  /// d 为 null 表示取消倒计时
  void setSleep(Duration? d) {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    if (d == null) {
      sleepEnd = null;
      _notify();
      return;
    }
    sleepEnd = DateTime.now().add(d);
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = sleepRemaining;
      if (r == null) {
        _sleepTicker?.cancel();
        _sleepTicker = null;
        return;
      }
      if (r <= Duration.zero) {
        _sleepTicker?.cancel();
        _sleepTicker = null;
        sleepEnd = null;
        try {
          _audio.pause();
        } catch (_) {}
        onMessage?.call('倒计时结束，已暂停播放');
      }
      _notify();
    });
    _notify();
  }

  // ---------- 生命周期 ----------

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    _sleepTicker?.cancel();
    _audio.player.dispose();
    super.dispose();
  }
}
