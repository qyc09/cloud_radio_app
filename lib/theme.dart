import 'package:flutter/material.dart';

/// ---------- 全局主题色 ----------
const Color kBg = Color(0xFF0C121D); // 页面背景（深夜蓝）
const Color kCard = Color(0xFF17202F); // 卡片
const Color kCardDeep = Color(0xFF111826); // 输入框 / 芯片
const Color kAccent = Color(0xFF2CD9C0); // 主色（青碧）
const Color kAccentDeep = Color(0xFF1FA98F);
const Color kOnAccent = Color(0xFF06231E); // 主色上的深色文字
const Color kStar = Color(0xFFFFC94D); // 收藏星
const Color kTextDim = Color(0xFF8B96A9); // 弱文字
const Color kLive = Color(0xFFFF5C7A); // 直播红点

ThemeData buildRadioTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(
        primary: kAccent,
        secondary: kAccent,
        surface: kCard,
      ),
    );
