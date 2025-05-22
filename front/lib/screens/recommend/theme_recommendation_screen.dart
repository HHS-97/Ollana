// lib/screens/recommend/theme_recommendation_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/recommend/theme_recommendation_card.dart';
import '../../widgets/recommend/mountain_detail_dialog.dart';

Map<String, dynamic> _parseJson(String body) => jsonDecode(body);

class ThemeRecommendationScreen extends StatefulWidget {
  const ThemeRecommendationScreen({Key? key}) : super(key: key);

  static const themes = ['계곡', '아름다운', '단풍'];

  @override
  _ThemeRecommendationScreenState createState() =>
      _ThemeRecommendationScreenState();
}

class _ThemeRecommendationScreenState extends State<ThemeRecommendationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, Future<Map<String, dynamic>>> _futures;
  
  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF3D7A64);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _accentColor = const Color(0xFFFFA270);
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ThemeRecommendationScreen.themes.length,
      vsync: this,
    );
    // 각 테마별 API 호출 Future 캐싱 (토큰 없이)
    _futures = {
      for (var theme in ThemeRecommendationScreen.themes)
        theme: _fetchByKeyword(theme),
    };
  }

  Future<Map<String, dynamic>> _fetchByKeyword(String keyword) async {
    final url = Uri.parse(
      '${dotenv.get('AI_BASE_URL')}/recommend_by_keyword',
    );

    try {
      final resp = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'keyword': keyword}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('요청 시간이 초과되었습니다.'),
          );

      if (resp.statusCode != 200) {
        throw Exception('서버 오류 (${resp.statusCode})');
      }

      // 바디를 UTF-8로 디코딩
      final bodyString = utf8.decode(resp.bodyBytes);
      // JSON 파싱 isolate 분리
      final data = await compute(_parseJson, bodyString);
      data['recommendations'] ??= [];
      return data;
    } catch (e) {
      debugPrint('⚠️ _fetchByKeyword 에러: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: _accentColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  // 현재 탭에 해당하는 테마 데이터 리로드
                  final currentTheme = ThemeRecommendationScreen.themes[_tabController.index];
                  _futures[currentTheme] = _fetchByKeyword(currentTheme);
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, 
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 70,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '추천된 산이 없습니다',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '다른 테마를 선택해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '테마별 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: ThemeRecommendationScreen.themes
                  .map((t) => Tab(text: t))
                  .toList(),
              labelColor: _primaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: _primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 테마 설명 헤더 (배너 형식)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                final index = _tabController.animation!.value.round();
                final theme = ThemeRecommendationScreen.themes[index];
                String description;
                IconData icon;
                
                // 테마별 설명과 아이콘 지정
                switch (theme) {
                  case '계곡':
                    description = '시원한 계곡이 있는 산을 찾고 계신가요? 물소리를 들으며 하이킹을 즐겨보세요.';
                    icon = Icons.waves;
                    break;
                  case '단풍':
                    description = '가을의 아름다운 단풍을 감상할 수 있는 산들을 모았습니다.';
                    icon = Icons.eco;
                    break;
                  case '아름다운':
                    description = '놀라운 경치와 아름다운 풍경을 자랑하는 산들을 만나보세요.';
                    icon = Icons.filter_hdr;
                    break;
                  default:
                    description = '당신의 취향에 맞는 테마별 산을 추천해드립니다.';
                    icon = Icons.landscape;
                }
                
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$theme 테마',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ThemeRecommendationScreen.themes.map((theme) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _futures[theme],
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return _buildLoadingView();
                    }
                    
                    if (snap.hasError) {
                      return _buildErrorView(snap.error.toString());
                    }
                    
                    final data = snap.data!;
                    final recs = data['recommendations'] as List;
                    
                    if (recs.isEmpty) {
                      return _buildEmptyView();
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      itemCount: recs.length,
                      itemBuilder: (ctx, i) {
                        final rec = recs[i] as Map<String, dynamic>;
                        return ThemeRecommendationCard(
                          mountain: rec,
                          index: i,
                          onTap: () {
                            // 산의 난이도에 따른 색상 가져오기
                            final level = rec['level'] as String? ?? 'M';
                            final levelColor = ThemeRecommendationCard.getLevelColor(level);
                            
                            showDialog(
                              context: context,
                              builder: (_) => MountainDetailDialog(
                                mountain: rec,
                                primaryColor: levelColor, // 난이도별 색상 적용
                                textColor: _textColor,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}