import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_radio_app/models/station.dart';

class RadioApi {
  static const salt = 'f0fc4c668392f9f9a447e48584c214ee';
  static const base = 'https://ytmsout.radio.cn/web/appBroadcast/list';

  /// 签名: MD5(排序参数 + &timestamp=xx&key=盐值) 小写
  String _genSign(Map<String, String> params, String ts) {
    final keys = params.keys.toList()..sort();
    final paramStr = keys.map((k) => '$k=${params[k]}').join('&');
    return md5
        .convert(utf8.encode('$paramStr&timestamp=$ts&key=$salt'))
        .toString();
  }

  /// 获取省份电台列表（默认广东 440000）
  Future<List<Station>> fetchStations({String provinceCode = '440000'}) async {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final params = {'categoryId': '0', 'provinceCode': provinceCode};
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    final resp = await http.get(
      Uri.parse('$base?$query'),
      headers: {
        'Content-Type': 'application/json',
        'equipmentId': '0000',
        'platformCode': 'WEB',
        'timestamp': ts,
        'sign': _genSign(params, ts),
        'Origin': 'https://www.radio.cn', // 防盗链必需
        'Referer': 'https://www.radio.cn/',
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) Firefox/155.0',
      },
    ).timeout(const Duration(seconds: 10));

    // utf8 解码，防中文乱码
    final data = json.decode(utf8.decode(resp.bodyBytes));

    // 成功码是 0（不是 200）
    if (data['code'] != 0) {
      throw Exception('API错误 ${data['code']}: ${data['message']}');
    }

    // 递归提取含 contentId 的电台
    final stations = <Station>[];
    void walk(dynamic o) {
      if (o is List &&
          o.isNotEmpty &&
          o[0] is Map &&
          o[0]['contentId'] != null) {
        stations
            .addAll(o.map((e) => Station.fromJson(e as Map<String, dynamic>)));
      } else if (o is Map) {
        for (final v in o.values) {
          walk(v);
        }
      }
    }

    walk(data);
    return stations;
  }
}
