import 'package:flutter/material.dart';

import 'package:cloud_radio_app/controllers/player_controller.dart';
import 'package:cloud_radio_app/models/station.dart';
import 'package:cloud_radio_app/theme.dart';
import 'package:cloud_radio_app/widgets/eq_bars.dart';

/// 电台卡片：台标 + 台名 + 收藏星标；点击播放，再点当前台切换播放/暂停
class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.controller,
    required this.station,
  });

  final PlayerController controller;
  final Station station;

  @override
  Widget build(BuildContext context) {
    final s = station;
    final fav = controller.isFav(s);
    final isNow = controller.now?.contentId == s.contentId;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => controller.play(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isNow ? kAccent.withOpacity(.55) : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                _buildLogo(s, isNow),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isNow
                                    ? kAccent
                                    : Colors.white.withOpacity(.92),
                              ),
                            ),
                          ),
                          if (isNow) ...[
                            const SizedBox(width: 8),
                            EqBars(
                              active:
                                  controller.playing && !controller.buffering,
                              maxHeight: 13,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.subtitle ?? 'ID: ${s.contentId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextDim.withOpacity(.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: fav ? '取消收藏' : '收藏',
                  onPressed: () => controller.toggleFav(s),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: Icon(
                      fav ? Icons.star_rounded : Icons.star_border_rounded,
                      key: ValueKey<bool>(fav),
                      size: 24,
                      color: fav ? kStar : kTextDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Station s, bool isNow) {
    final hasImg = s.image != null && s.image!.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isNow
            ? const LinearGradient(colors: [kAccent, kAccentDeep])
            : const LinearGradient(colors: [kCardDeep, kCardDeep]),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: hasImg
          ? Image.network(
              s.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.radio_rounded,
                color: kTextDim,
              ),
              loadingBuilder: (ctx, child, prog) => prog == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kTextDim,
                        ),
                      ),
                    ),
            )
          : Icon(
              isNow ? Icons.graphic_eq_rounded : Icons.radio_rounded,
              color: isNow ? kOnAccent : kTextDim,
              size: 24,
            ),
    );
  }
}
