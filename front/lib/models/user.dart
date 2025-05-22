class User {
  final String nickname;
  final String email;
  final String imageUrl;
  final bool agree;

  User({
    required this.nickname,
    required this.email,
    required this.imageUrl,
    required this.agree,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nickname: json['nickname'] ?? '닉네임 없음',
      email: json['email'] ?? '이메일 없음',
      imageUrl: json['imageUrl'] ??
          'https://olliaio.s3.ap-northeast-2.amazonaws.com/profile/default_pofile_img.png',
      agree: json['agree'] ?? false, // agree 값이 없으면 false로 기본 설정
    );
  }
}