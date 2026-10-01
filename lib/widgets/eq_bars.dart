import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cloud_radio_app/theme.dart';

/// 律动均衡条：正在播放的卡片、加载动画使用
class EqBars extends StatefulWidget {
  const EqBars({
    super.key,
    this.active = true,
    this.maxHeight = 14,
    this.color = kAccent,
  });

  final bool active;
  final double maxHeight;
  final Color color;

  @override
  State<EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<EqBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            double h = 4;
            if (widget.active) {
              final phase = _c.value * 2 * math.pi + i * 1.35;
              h = 4 + math.sin(phase).abs() * (widget.maxHeight - 4);
            }
            return Container(
              width: 3.5,
              height: h,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

/// 直播脉冲红点
class PulseDot extends StatefulWidget {
  const PulseDot({super.key});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kLive,
            boxShadow: [
              BoxShadow(
                color: kLive.withOpacity(.35 + .3 * math.sin(t * 2 * math.pi)),
                blurRadius: 6,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
