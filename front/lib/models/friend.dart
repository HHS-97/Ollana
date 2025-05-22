class Friend {
  final num id;
  final String nickname;
  final bool isPossible;
  final String? profileImg; 

  Friend({required this.id, required this.nickname, required this.isPossible, this.profileImg,});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
        id: json['id'],
        nickname: json['nickname'],
        isPossible: json['isPossible'],
        profileImg: json['profileImg'],);
  }
}
