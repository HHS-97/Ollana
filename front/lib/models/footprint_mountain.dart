class footprintMountain {
  final int footprintId;
  final String mountainName;
  final String imgUrl;

  footprintMountain({
    required this.footprintId,
    required this.mountainName,
    required this.imgUrl,
  });

  factory footprintMountain.fromJson(Map<String, dynamic> json) {
    return footprintMountain(
      footprintId: json['footprintId'],
      mountainName: json['mountainName'],
      imgUrl: json['imgUrl'] ?? '',
    );
  }
}
