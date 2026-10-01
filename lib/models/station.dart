/// 电台数据模型
class Station {
  final String title;
  final String contentId;
  final String? subtitle;
  final String? image;
  final String? mp3High;
  final String? mp3Low;
  final String? playUrl;

  Station({
    required this.title,
    required this.contentId,
    this.subtitle,
    this.image,
    this.mp3High,
    this.mp3Low,
    this.playUrl,
  });

  factory Station.fromJson(Map<String, dynamic> j) => Station(
        title: j['title'] ?? '',
        contentId: j['contentId']?.toString() ?? '',
        subtitle: j['subtitle'],
        image: j['image'],
        mp3High: j['mp3PlayUrlHigh'],
        mp3Low: j['mp3PlayUrlLow'],
        playUrl: j['playUrlLow'],
      );

  /// 序列化，存收藏用
  Map<String, dynamic> toJson() => {
        'title': title,
        'contentId': contentId,
        'subtitle': subtitle,
        'image': image,
      };

  /// 从收藏反序列化（流地址不存，播放时实时取）
  factory Station.fromStored(Map<String, dynamic> j) => Station(
        title: j['title'] ?? '',
        contentId: j['contentId']?.toString() ?? '',
        subtitle: j['subtitle'],
        image: j['image'],
      );

  /// 最优播放地址：MP3高 → MP3低 → m3u8
  String get bestUrl => mp3High ?? mp3Low ?? playUrl ?? '';
}
