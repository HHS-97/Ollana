import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/app_state.dart';
import 'status_info_pages.dart';
import 'experience_bar.dart';

class StatusContainer extends StatefulWidget {
  final PageController pageController;
  final int currentStatusPage;
  final ValueChanged<int> onPageChanged;

  const StatusContainer({
    Key? key,
    required this.pageController,
    required this.currentStatusPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  _StatusContainerState createState() => _StatusContainerState();
}

class _StatusContainerState extends State<StatusContainer> {
  String _grade = 'SEED';
  int _exp = 0;

  @override
  void initState() {
    super.initState();
    _fetchFootprint();
  }

  Future<void> _fetchFootprint() async {
    try {
      final baseUrl = dotenv.env['BASE_URL']!;
      final url = Uri.parse('$baseUrl/footprint/main');
      final token = Provider.of<AppState>(context, listen: false).accessToken;

      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
      });

      if (resp.statusCode == 200) {
        final body =
            json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final user = body['data']?['user'] as Map<String, dynamic>?;
        if (user != null) {
          setState(() {
            _grade = user['grade'] as String? ?? 'SEED';
            _exp = (user['exp'] as num?)?.toInt() ?? 0;
          });
          debugPrint('▶ grade=$_grade, exp=$_exp');
        }
      } else {
        debugPrint('▶ Footprint API error: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('▶ Footprint API exception: $e');
    }
  }

  String _assetForGrade(String grade) {
    switch (grade) {
      case 'SEED':
        return 'lib/assets/images/level_one.png';
      case 'SPROUT':
        return 'lib/assets/images/level_two.png';
      case 'TREE':
        return 'lib/assets/images/level_three.png';
      case 'FRUIT':
        return 'lib/assets/images/level_four.png';
      case 'MOUNTAIN':
        return 'lib/assets/images/level_five.png';
      default:
        return 'lib/assets/images/level_one.png';
    }
  }
  
  String _koreanGradeName(String grade) {
    switch (grade) {
      case 'SEED':
        return '씨앗';
      case 'SPROUT':
        return '새싹';
      case 'TREE':
        return '나무';
      case 'FRUIT':
        return '열매';
      case 'MOUNTAIN':
        return '산';
      default:
        return '씨앗';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeAsset = _assetForGrade(_grade);
    final koreanGrade = _koreanGradeName(_grade);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8F5EC), // 연한 민트 그린
            Color(0xFFDCEFE2), // 연한 민트색
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24), // 더 둥글게
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64B792).withOpacity(0.15), // 녹색 계열 그림자
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 등급 배지 + 등급명 + 경험치 프로그레스 바
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 뱃지 (맨 위)
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.asset(badgeAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 등급명 + 경험치 값 (중간) - 수정된 부분
                  Row(
                    mainAxisSize: MainAxisSize.min, // 최소 공간만 사용하도록 변경
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 등급명 컨테이너
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // 패딩 축소
                          vertical: 3
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF52A486),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF52A486).withOpacity(0.25),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          koreanGrade,
                          style: const TextStyle(
                            fontSize: 10, // 폰트 크기 축소
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4), // 간격 축소
                      // 경험치 컨테이너
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // 패딩 축소
                          vertical: 3
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_exp}xp',
                          style: const TextStyle(
                            fontSize: 10, // 폰트 크기 축소
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 경험치 바 (맨 아래)
                  SizedBox(
                    width: 90,
                    child: ExperienceBar(currentXp: _exp, grade: _grade),
                  ),
                ],
              ),
            ),
          ),


          // 오른쪽: PageView + 인디케이터
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // 더 둥글게
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 페이지뷰
                    SizedBox(
                      height: 140,
                      child: PageView(
                        controller: widget.pageController,
                        onPageChanged: widget.onPageChanged,
                        physics: const BouncingScrollPhysics(), // 스크롤 효과 추가
                        children: const [
                          FirstStatusInfo(),
                          SecondStatusInfo(),
                        ],
                      ),
                    ),
                    
                    // 페이지 인디케이터 - 디자인 개선
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (i) {
                          final isActive = i == widget.currentStatusPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 8, // 활성 상태 더 넓게
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? const Color(0xFF4CAF50)  // 활성 색상 변경
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}