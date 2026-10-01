import 'package:flutter/material.dart';

import 'package:cloud_radio_app/theme.dart';

/// 辞典页（预留骨架）：方言辞典 + AI 跟读，后续在这里接数据源
class DictPage extends StatelessWidget {
  const DictPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            children: [
              _buildSearchPreview(context),
              const SizedBox(height: 12),
              _featureCard(
                context,
                icon: Icons.menu_book_rounded,
                colors: const [kAccent, kAccentDeep],
                iconColor: kOnAccent,
                title: '方言辞典',
                desc: '接入国家语保工程采录展示平台（zhongguoyuyan.cn）的潮汕点语料，'
                    '"查字词 → 听真人读音"。',
              ),
              const SizedBox(height: 12),
              _featureCard(
                context,
                icon: Icons.record_voice_over_rounded,
                colors: const [Color(0xFF5B8DEF), Color(0xFF3E6BD6)],
                iconColor: Colors.white,
                title: 'AI 跟读',
                desc: '调用开源方言 TTS / API，把释义合成方言语音，跟读学习。',
              ),
              const SizedBox(height: 12),
              _noteCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
                  colors: [kAccent, kAccentDeep],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kAccent.withOpacity(.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: kOnAccent, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '潮汕话辞典',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '查字词 · 听真人读音 · AI 跟读',
                    style: TextStyle(fontSize: 11.5, color: kTextDim),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPreview(BuildContext context) {
    return TextField(
      readOnly: true,
      showCursor: false,
      onTap: () => _snack(context, '辞典功能开发中，敬请期待'),
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: kCardDeep,
        hintText: '查字词，例：食 / 落雨 / 厝',
        hintStyle: const TextStyle(color: kTextDim, fontSize: 13.5),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kTextDim),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required List<Color> colors,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kStar.withOpacity(.5)),
                      ),
                      child: const Text('规划中',
                          style: TextStyle(fontSize: 10, color: kStar)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: kTextDim.withOpacity(.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardDeep,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: kTextDim),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '本页为预留模块：后续接入语保工程数据源与方言 TTS 后，'
              '在这里提供查词、真人读音播放与 AI 跟读。',
              style: TextStyle(fontSize: 11.5, height: 1.6, color: kTextDim),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
