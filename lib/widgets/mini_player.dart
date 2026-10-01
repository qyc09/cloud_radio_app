import 'package:flutter/material.dart';

import 'package:cloud_radio_app/controllers/player_controller.dart';
import 'package:cloud_radio_app/models/station.dart';
import 'package:cloud_radio_app/theme.dart';
import 'package:cloud_radio_app/widgets/eq_bars.dart';

/// 时长格式化：29:59 或 1:00:00
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  if (h >= 1) return '$h:${two(m)}:${two(s)}';
  return '${d.inMinutes}:${two(s)}';
}

/// 底部悬浮播放状态栏：封面 + 台名 + 实时状态（含倒计时剩余）
/// + 倒计时入口 + 播放/暂停 + 停止收起
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({
    super.key,
    required this.controller,
    this.onOpenSleepSheet,
  });

  final PlayerController controller;
  final VoidCallback? onOpenSleepSheet;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final visible = controller.now != null;
        final s = controller.miniStation;
        if (s == null) return const SizedBox.shrink();

        final remain = controller.sleepRemaining;
        final suffix = remain != null ? ' · ${formatDuration(remain)} 后停止' : '';
        final status = controller.buffering
            ? '缓冲中…$suffix'
            : controller.playing
                ? '正在直播$suffix'
                : '已暂停$suffix';

        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            offset: visible ? Offset.zero : const Offset(0, 1.5),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              opacity: visible ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.08)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x73000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildArt(s),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (controller.playing &&
                                  !controller.buffering) ...[
                                const PulseDot(),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  status,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: kTextDim,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: '倒计时停止',
                      onPressed: onOpenSleepSheet,
                      icon: Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: remain != null ? kAccent : kTextDim,
                      ),
                    ),
                    _buildPlayButton(),
                    IconButton(
                      tooltip: '停止播放',
                      onPressed: controller.stop,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: kTextDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArt(Station s) {
    final hasImg = s.image != null && s.image!.isNotEmpty;
    return Container(
      width: 46,
      height: 46,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(colors: [kAccent, kAccentDeep]),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: hasImg
          ? Image.network(
              s.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.podcasts, color: kOnAccent, size: 22),
            )
          : const Icon(Icons.podcasts, color: kOnAccent, size: 22),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: controller.togglePlay,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAccent, kAccentDeep],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kAccent.withOpacity(.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: controller.buffering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: kOnAccent,
                ),
              )
            : Icon(
                controller.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: kOnAccent,
                size: 28,
              ),
      ),
    );
  }
}
