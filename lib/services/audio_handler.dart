import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

import 'package:cloud_radio_app/models/station.dart';

/// audio_service 后台播放处理器：
/// - Android/iOS：注册为前台媒体服务，退到桌面/锁屏继续播放，
///   通知栏与锁屏显示台名、封面和播放/暂停/停止按钮；
/// - 不支持 audio_service 的桌面平台（Windows 等）：
///   main() 里做了降级，直接实例化本类当裸播放器用。
class RadioAudioHandler extends BaseAudioHandler {
  final Player player = Player();

  RadioAudioHandler() {
    // 播放状态 → 系统媒体中心
    player.stream.playing.listen((p) {
      playbackState.add(playbackState.value.copyWith(
        playing: p,
        processingState: AudioProcessingState.ready,
        controls: p
            ? const [MediaControl.pause, MediaControl.stop]
            : const [MediaControl.play, MediaControl.stop],
      ));
    });
    // 缓冲状态
    player.stream.buffering.listen((b) {
      playbackState.add(playbackState.value.copyWith(
        processingState:
            b ? AudioProcessingState.buffering : AudioProcessingState.ready,
      ));
    });
  }

  /// 播放一个流地址，并同步通知栏媒体信息
  Future<void> open(Station s, String url) async {
    mediaItem.add(MediaItem(
      id: 'chaoshan_${s.contentId}',
      album: '潮汕电台',
      title: s.title,
      artist:
          (s.subtitle != null && s.subtitle!.isNotEmpty) ? s.subtitle! : '网络电台',
      artUri: (s.image != null && s.image!.isNotEmpty)
          ? Uri.tryParse(s.image!)
          : null,
    ));
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.buffering,
      playing: true,
    ));
    await player.open(Media(url)); // open 默认自动播放
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}
