import 'package:flutter/material.dart';

import 'package:cloud_radio_app/controllers/player_controller.dart';
import 'package:cloud_radio_app/models/station.dart';
import 'package:cloud_radio_app/theme.dart';
import 'package:cloud_radio_app/widgets/eq_bars.dart';
import 'package:cloud_radio_app/widgets/station_card.dart';

/// 方言区 → 市 → 区县 数据结构
class _CityNode {
  final String name;
  final String keyword; // 市区关键词
  final List<String> counties;
  const _CityNode(this.name, this.keyword, this.counties);
}

class _RegionNode {
  final String name;
  final String hint;
  final bool locked; // 预留分区，暂未开放
  final List<_CityNode> cities;
  const _RegionNode(this.name, this.hint, this.locked, this.cities);
}

/// 电台页：方言区折叠树（点击分区 → 三市 → 各区县）+ 搜索 + 台列表
class RadioPage extends StatefulWidget {
  const RadioPage({super.key, required this.controller});

  final PlayerController controller;

  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  final _searchCtrl = TextEditingController();

  static const List<_RegionNode> _regions = [
    _RegionNode('潮汕方言区', '闽语 · 潮汕片', false, [
      _CityNode('汕头市', '汕头', ['澄海', '潮阳', '潮南']),
      _CityNode('潮州市', '潮州', ['潮安', '饶平']),
      _CityNode('揭阳市', '揭阳', ['普宁', '揭东', '揭西', '惠来']),
    ]),
    _RegionNode('粤语区', '广府片 · 即将开放', true, []),
    _RegionNode('客家话区', '粤东片 · 即将开放', true, []),
  ];

  int _selRegion = 0;
  int? _selCity; // null = 整个方言区
  String? _selCountyKw; // null = 市级全部
  final Set<int> _expandedRegions = {0}; // 默认展开潮汕区
  final Set<String> _expandedCities = {};

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    if (c.all == null && !c.loadingStations) {
      c.loadStations();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- 过滤 ----------

  List<String> _activeKeywords() {
    final r = _regions[_selRegion];
    if (_selCity == null) {
      // 整个方言区：所有市/县关键词
      final kws = <String>[];
      for (final c in r.cities) {
        kws.add(c.keyword);
        kws.addAll(c.counties);
      }
      return kws;
    }
    final c = r.cities[_selCity!];
    if (_selCountyKw == null) {
      // 整市：市区 + 各区县
      return [c.keyword, ...c.counties];
    }
    return [_selCountyKw!];
  }

  List<Station> _filtered() {
    final all = widget.controller.all;
    if (all == null) return <Station>[];
    final kws = _activeKeywords();
    Iterable<Station> src =
        all.where((s) => kws.any((k) => s.title.contains(k)));
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty) {
      src = src
          .where((s) => s.title.contains(q) || (s.subtitle ?? '').contains(q));
    }
    return src.toList();
  }

  String get _pathLabel {
    final r = _regions[_selRegion];
    if (_selCity == null) return '${r.name} · 全部';
    final c = r.cities[_selCity!];
    if (_selCountyKw == null) return '${r.name} · ${c.name} · 全部';
    if (_selCountyKw == c.keyword) return '${r.name} · ${c.name} · 市区';
    return '${r.name} · ${c.name} · $_selCountyKw';
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        return Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(c)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF11302C), kBg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: const Icon(Icons.podcasts, color: kOnAccent, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '潮汕电台',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '按方言区域收听 · 家乡的声音',
                        style: TextStyle(fontSize: 11.5, color: kTextDim),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '刷新列表',
                  onPressed: widget.controller.loadStations,
                  icon: const Icon(Icons.refresh_rounded, color: kTextDim),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSearch(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14.5),
      cursorColor: kAccent,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: kCardDeep,
        hintText: '搜索电台 / 节目…',
        hintStyle: const TextStyle(color: kTextDim, fontSize: 13.5),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kTextDim),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
                child:
                    const Icon(Icons.close_rounded, size: 18, color: kTextDim),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: _searchBorder(Colors.transparent),
        enabledBorder: _searchBorder(Colors.white.withOpacity(.05)),
        focusedBorder: _searchBorder(kAccent.withOpacity(.5)),
      ),
    );
  }

  OutlineInputBorder _searchBorder(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c),
      );

  Widget _buildBody(PlayerController c) {
    final stations = _filtered();
    return RefreshIndicator(
      color: kAccent,
      backgroundColor: kCard,
      onRefresh: c.loadStations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 104),
        children: [
          _buildTree(),
          const SizedBox(height: 10),
          if (c.loadingStations)
            _buildLoading()
          else if (c.loadError != null)
            _buildError(c)
          else ...[
            _buildPathRow(stations.length),
            if (stations.isEmpty)
              _buildEmptyInline()
            else
              ...stations.map((s) => StationCard(controller: c, station: s)),
          ],
        ],
      ),
    );
  }

  // ---------- 方言区折叠树 ----------

  Widget _buildTree() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _regions.length; i++) _buildRegionTile(i),
        ],
      ),
    );
  }

  Widget _buildRegionTile(int ri) {
    final r = _regions[ri];

    // 预留分区（锁定态）
    if (r.locked) {
      return Opacity(
        opacity: .55,
        child: InkWell(
          onTap: () => _snack('「${r.name}」即将开放，敬请期待'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kCardDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.lock_outline, size: 16, color: kTextDim),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      Text(r.hint,
                          style:
                              const TextStyle(fontSize: 11, color: kTextDim)),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: kTextDim),
              ],
            ),
          ),
        ),
      );
    }

    final expanded = _expandedRegions.contains(ri);
    final selected = _selRegion == ri && _selCity == null;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              expanded ? _expandedRegions.remove(ri) : _expandedRegions.add(ri);
              _selRegion = ri;
              _selCity = null;
              _selCountyKw = null;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: [kAccent, kAccentDeep])
                        : null,
                    color: selected ? null : kCardDeep,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.record_voice_over_outlined,
                    size: 17,
                    color: selected ? kOnAccent : kTextDim,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? kAccent : Colors.white.withOpacity(.9),
                        ),
                      ),
                      Text(r.hint,
                          style:
                              const TextStyle(fontSize: 11, color: kTextDim)),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      const Icon(Icons.expand_more, size: 20, color: kTextDim),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              children: [
                for (var ci = 0; ci < r.cities.length; ci++)
                  _buildCityTile(ri, ci),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCityTile(int ri, int ci) {
    final r = _regions[ri];
    final city = r.cities[ci];
    final key = '$ri-$ci';
    final expanded = _expandedCities.contains(key);
    final selected = _selRegion == ri && _selCity == ci && _selCountyKw == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              expanded ? _expandedCities.remove(key) : _expandedCities.add(key);
              // 点市 = 选中该市全部
              _selRegion = ri;
              _selCity = ci;
              _selCountyKw = null;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_city_rounded,
                  size: 16,
                  color: selected ? kAccent : kTextDim,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    city.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? kAccent : Colors.white.withOpacity(.85),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child:
                      const Icon(Icons.expand_more, size: 18, color: kTextDim),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCountyChip(ri, ci, '市区', city.keyword),
                for (final county in city.counties)
                  _buildCountyChip(ri, ci, county, county),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCountyChip(int ri, int ci, String label, String kw) {
    final selected = _selRegion == ri && _selCity == ci && _selCountyKw == kw;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selRegion = ri;
          _selCity = ci;
          _selCountyKw = kw;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [kAccent, kAccentDeep])
              : null,
          color: selected ? null : kCardDeep,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? Colors.transparent : Colors.white.withOpacity(.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? kOnAccent : kTextDim,
          ),
        ),
      ),
    );
  }

  // ---------- 列表区 ----------

  Widget _buildPathRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Row(
        children: [
          const Icon(Icons.place, size: 13, color: kTextDim),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _pathLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: kTextDim),
            ),
          ),
          Text('$count 台',
              style: const TextStyle(fontSize: 11.5, color: kTextDim)),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          EqBars(active: true, maxHeight: 22),
          SizedBox(height: 14),
          Text('正在加载电台列表…', style: TextStyle(fontSize: 12.5, color: kTextDim)),
        ],
      ),
    );
  }

  Widget _buildError(PlayerController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kCardDeep,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(.06)),
              ),
              child:
                  const Icon(Icons.wifi_off_rounded, color: kTextDim, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('列表加载失败',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              c.loadError ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: kTextDim),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: c.loadStations,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重新加载'),
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: kOnAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInline() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kCardDeep,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.06)),
            ),
            child:
                const Icon(Icons.search_off_rounded, color: kTextDim, size: 28),
          ),
          const SizedBox(height: 12),
          const Text('没有找到电台',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('换个区县或关键词试试',
              style: TextStyle(fontSize: 12, color: kTextDim)),
        ],
      ),
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
