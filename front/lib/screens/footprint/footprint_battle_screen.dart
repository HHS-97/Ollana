import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/battle_result.dart';
import '../../services/my_footprint_service.dart';

class FootprintBattleScreen extends StatefulWidget {
  final String token;

  const FootprintBattleScreen({super.key, required this.token});

  @override
  State<FootprintBattleScreen> createState() => _FootprintBattleScreenState();
}

class _FootprintBattleScreenState extends State<FootprintBattleScreen> {
  final ScrollController _scrollController = ScrollController();
  List<BattleResult> _battleResults = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _lastPage = false;
  int totalElements = 0;
  late final MyFootprintService _footprintService;

  // 테마 색상 정의
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF6E85B7);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF333333);
  final Color _textSecondaryColor = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFEEEEEE);
  final Color _winColor = const Color(0xFF52A486);  // 승리 색상
  final Color _drawColor = const Color(0xFFAADC64);  // 무승부 색상 (프로세스 바용)
  final Color _drawTextColor = const Color(0xFF76AB46);  // 무승부 텍스트 색상 
  final Color _drawCardColor = const Color(0x80E6F5D2);  // 무승부 카드 헤더 색상
  final Color _loseColor = Colors.grey.shade600; // 패배 색상
  final Color _goldColor = const Color(0xFFFFD700); // 왕관 색상

  @override
  void initState() {
    super.initState();
    _footprintService = MyFootprintService();
    _fetchBattleResults();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.9 &&
          !_isLoading &&
          !_lastPage) {
        _fetchBattleResults(page: _currentPage + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBattleResults({int page = 0}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _footprintService.getBattleResults(widget.token, page: page);
      
      setState(() {
        if (page == 0) {
          _battleResults = result['battleResults'] as List<BattleResult>;
        } else {
          _battleResults.addAll(result['battleResults'] as List<BattleResult>);
        }
        _currentPage = page;
        _lastPage = result['isLast'] as bool;
        totalElements = result['totalElements'] as int;
      });
    } catch (e) {
      debugPrint('대결 결과 API 호출 에러: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getResultText(String result) {
    switch (result) {
      case 'W':
        return '승리';
      case 'L':
        return '패배';
      case 'S':
        return '무승부';
      default:
        return '';
    }
  }

  Color _getResultColor(String result, bool isMe) {
    if (result == 'S') return _drawTextColor; // 무승부는 더 진한 녹색
    if ((result == 'W' && isMe) || (result == 'L' && !isMe)) {
      return _winColor; // 승리는 녹색
    }
    return _loseColor; // 패배는 회색
  }

  // 승자 판별 함수
  bool _isWinner(String result, bool isMe) {
    if (result == 'S') return true; // 무승부면 둘 다 승자
    if (result == 'W' && isMe) return true; // 내가 이겼을 때
    if (result == 'L' && !isMe) return true; // 상대가 이겼을 때
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = context.watch<AppState>().profileImageUrl;
    final nickname = context.watch<AppState>().nickname;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(
          '대결 결과',
          style: TextStyle(
            color: _textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _textPrimaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _battleResults.isEmpty
          ? _buildLoadingView()
          : _battleResults.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // 상단 요약 영역
                    _buildSummarySection(),
                    
                    // 대결 목록 타이틀
                    _buildHeaderTitle(),

                    // 대결 결과 목록
                    Expanded(
                      child: RefreshIndicator(
                        color: _primaryColor,
                        onRefresh: () async {
                          setState(() {
                            _battleResults = [];
                            _currentPage = 0;
                            _lastPage = false;
                          });
                          await _fetchBattleResults();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _battleResults.length + (!_lastPage && _isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _battleResults.length && !_lastPage && _isLoading) {
                              return _buildLoadingItem();
                            }
                            final result = _battleResults[index];
                            return _buildBattleCard(result, profileImageUrl, nickname);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummarySection() {
    // 승/무/패 횟수 계산
    final wins = _battleResults.where((r) => r.result == 'W').length;
    final draws = _battleResults.where((r) => r.result == 'S').length;
    final losses = _battleResults.where((r) => r.result == 'L').length;
    final total = wins + draws + losses;
    
    // 백분율 계산
    final winPercent = total > 0 ? (wins / total * 100).toInt() : 0;
    final drawPercent = total > 0 ? (draws / total * 100).toInt() : 0;
    final lossPercent = total > 0 ? (losses / total * 100).toInt() : 0;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 원형 그래프
            if (total > 0) ...[
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: PieChartPainter(
                    winPercent: wins / total,
                    drawPercent: draws / total,
                    losePercent: losses / total,
                    winColor: _winColor,
                    drawColor: _drawColor,
                    loseColor: _loseColor,
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        size: 28,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '0회',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(width: 20),
            
            // 통계 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow('승리', wins, winPercent, _winColor),
                  const SizedBox(height: 12),
                  _buildStatRow('무승부', draws, drawPercent, _drawColor),
                  const SizedBox(height: 12),
                  _buildStatRow('패배', losses, lossPercent, _loseColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 통계 행 위젯
  Widget _buildStatRow(String label, int count, int percent, Color color) {
    return Row(
      children: [
        // 색상 표시
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        
        // 레이블
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: _textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const Spacer(),
        
        // 카운트
        Text(
          '$count회',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: count == 0 ? color.withOpacity(0.5) : color,
          ),
        ),
        
        const SizedBox(width: 8),
      ],
    );
  }
  
  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '대결 기록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              '총 $totalElements개',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleCard(BattleResult result, String? myProfile, String? nickname) {
    final myResultColor = _getResultColor(result.result, true);
    final opponentResultColor = _getResultColor(result.result, false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 산 이름과 날짜가 있는 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getResultBackgroundColor(result.result),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terrain,
                      size: 16,
                      color: _getResultForegroundColor(result.result),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.mountainName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  result.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // 대결 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 내 프로필
                Expanded(
                  child: Column(
                    children: [
                      _buildProfileAvatar(
                        myProfile,
                        isWinner: _isWinner(result.result, true),
                        resultColor: myResultColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nickname ?? '나',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // VS 텍스트만 표시 (박스와 결과 뱃지 제거)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "VS",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textSecondaryColor,
                    ),
                  ),
                ),
                
                // 상대방 프로필
                Expanded(
                  child: Column(
                    children: [
                      _buildProfileAvatar(
                        result.opponentProfile,
                        isWinner: _isWinner(result.result, false),
                        resultColor: opponentResultColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.opponentNickname,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Color _getResultBackgroundColor(String result) {
  // 테마 색상(0xFF52A486)의 채도와 명도를 낮춘 버전 사용
  return const Color(0xFF52A486).withOpacity(0.1);
}

  Color _getResultForegroundColor(String result) {
    switch (result) {
      case 'W':
        return _winColor;
      case 'L':
        return _loseColor;
      case 'S':
        return _drawTextColor; // 여기는 더 진한 색상 사용
      default:
        return Colors.grey;
    }
  }

  // 프로필 아바타 위젯
  Widget _buildProfileAvatar(String? imageUrl, {required bool isWinner, required Color resultColor}) {
    const double avatarRadius = 30;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 프로필 아바타
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isWinner ? _goldColor : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (isWinner)
                BoxShadow(
                  color: resultColor.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.white,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty 
                ? Icon(Icons.person, size: 28, color: Colors.grey[400]) 
                : null,
          ),
        ),
        
        // 승리자 표시 (작은 왕관 아이콘)
        if (isWinner)
          Positioned(
            top: -8,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                size: 16,
                color: _goldColor,
              ),
            ),
          ),
      ],
    );
  }
  
  // 로딩 인디케이터
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(_primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '대결 결과를 불러오는 중...',
            style: TextStyle(
              fontSize: 16,
              color: _textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 목록 하단 로딩 아이템
  Widget _buildLoadingItem() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF52A486),
          ),
        ),
      ),
    );
  }

  // 빈 상태 화면
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 50,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 대결 기록이 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '친구와 등산 대결을 해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 빈 결과 목록
  Widget _buildEmptyList() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 40,
                    color: _textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '대결 결과를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: _textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 원형 그래프 커스텀 페인터
class PieChartPainter extends CustomPainter {
  final double winPercent;
  final double drawPercent;
  final double losePercent;
  final Color winColor;
  final Color drawColor;
  final Color loseColor;

  PieChartPainter({
    required this.winPercent,
    required this.drawPercent,
    required this.losePercent,
    required this.winColor,
    required this.drawColor,
    required this.loseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // 그래프 그리기 설정
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2; // -90도에서 시작 (12시 방향)
    
    // 승리 부분 그리기
    if (winPercent > 0) {
      final winPaint = Paint()
        ..color = winColor
        ..style = PaintingStyle.fill;
      
      final winSweepAngle = 2 * pi * winPercent;
      canvas.drawArc(rect, startAngle, winSweepAngle, true, winPaint);
    }
    
    // 무승부 부분 그리기
    if (drawPercent > 0) {
      final drawPaint = Paint()
        ..color = drawColor
        ..style = PaintingStyle.fill;
      
      final drawStartAngle = startAngle + (2 * pi * winPercent);
      final drawSweepAngle = 2 * pi * drawPercent;
      canvas.drawArc(rect, drawStartAngle, drawSweepAngle, true, drawPaint);
    }
    
    // 패배 부분 그리기
    if (losePercent > 0) {
      final losePaint = Paint()
        ..color = loseColor
        ..style = PaintingStyle.fill;
      
      final loseStartAngle = startAngle + (2 * pi * winPercent) + (2 * pi * drawPercent);
      final loseSweepAngle = 2 * pi * losePercent;
      canvas.drawArc(rect, loseStartAngle, loseSweepAngle, true, losePaint);
    }
    
    // 원 테두리 그리기
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, borderPaint);
    
    // 내부 중앙 원 테두리 그리기 (반지름의 75%)
    final innerRadius = radius * 0.7;
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}