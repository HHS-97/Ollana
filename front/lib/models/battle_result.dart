class BattleResult {
  final String mountainName;
  final String result; // W, S, L
  final String date;
  final String opponentProfile;
  final String opponentNickname;

  BattleResult({
    required this.mountainName,
    required this.result,
    required this.date,
    required this.opponentProfile,
    required this.opponentNickname,
  });

  factory BattleResult.fromJson(Map<String, dynamic> json) {
    return BattleResult(
      mountainName: json['mountain']['mountainName'],
      result: json['result'],
      date: json['date'],
      opponentProfile: json['opponent']['profile'],
      opponentNickname: json['opponent']['nickname'],
    );
  }
}
