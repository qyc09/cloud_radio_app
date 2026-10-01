import 'package:flutter/material.dart';

import 'package:cloud_radio_app/controllers/player_controller.dart';
import 'package:cloud_radio_app/theme.dart';
import 'package:cloud_radio_app/widgets/station_card.dart';

/// 收藏页：单独一页展示收藏的电台
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.controller});

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final favs = controller.favorites.values.toList();
        return Column(
          children: [
            _buildHeader(favs.length),
            Expanded(
              child: favs.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 104),
                      children: [
                        for (final s in favs)
                          StationCard(controller: controller, station: s),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2130), kBg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFC94D), Color(0xFFFF9F43)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kStar.withOpacity(.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded,
                  color: Color(0xFF3A2A05), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '我的收藏',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count 个电台 · 点击卡片播放',
                    style: const TextStyle(fontSize: 11.5, color: kTextDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kCardDeep,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child: const Icon(Icons.star_border_rounded,
                color: kTextDim, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('还没有收藏电台',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            '在电台页点击卡片右侧的星星，把喜欢的台收进来',
            style: TextStyle(fontSize: 12.5, color: kTextDim),
          ),
        ],
      ),
    );
  }
}
