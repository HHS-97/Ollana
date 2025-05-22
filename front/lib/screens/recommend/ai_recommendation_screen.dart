import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/ai_recommendation_service.dart';
import '../../utils/ai_utils.dart';
import '../../widgets/recommend/ai_recommendation_card.dart';
import '../../widgets/recommend/mountain_detail_dialog.dart';

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({Key? key}) : super(key: key);

  @override
  _AiRecommendationScreenState createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> with SingleTickerProviderStateMixin {
  late final Future<Map<String, dynamic>> _futureRecos;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF3D7A64);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _accentColor = const Color(0xFFFFA270);
  final Color _textColor = const Color(0xFF333333);
  
  // 배경 그라데이션 색상
  final List<Color> _gradientColors = const [
    Color(0xFFF9FCFB),
    Color(0xFFEEF8F3),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('▶ initState: AiRecommendationService 호출');
    _futureRecos = AiRecommendationService().fetchRecommendation(context);
    
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> mountain) {
    // 산의 난이도에 따른 색상 가져오기
    final level = mountain['level'] as String? ?? 'M';
    final levelColor = RecommendationCard.getLevelColor(level);
    
    showDialog(
      context: context,
      builder: (_) => MountainDetailDialog(
        mountain: mountain,
        primaryColor: levelColor, // 난이도별 색상 적용
        textColor: _textColor,
      ),
    );
  }
    
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                    _futureRecos = AiRecommendationService().fetchRecommendation(context);
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
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                '다른 조건으로 다시 시도해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
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
        title: const Text(
          'AI 산 추천',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 메인 헤더 (배너 형식)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.landscape_rounded,
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
                              '당신만을 위한',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '맞춤 산 추천',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.7),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '당신의 등산 경험과 선호도를 기반으로 추천된 산들입니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 추천 목록 영역
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _futureRecos,
              builder: (ctx, snap) {
                debugPrint('   FutureBuilder 상태=${snap.connectionState}');
                
                if (snap.connectionState != ConnectionState.done) {
                  debugPrint('   → 로딩 중...');
                  return _buildLoadingView();
                }
                
                if (snap.hasError) {
                  debugPrint('⚠️ 에러: ${snap.error}');
                  return _buildErrorView(snap.error.toString());
                }

                final data = snap.data!;
                final recs = data['recommendations'] as List;
                debugPrint('   🔥 추천 개수: ${recs.length}');

                if (recs.isEmpty) {
                  debugPrint('⚠️ 추천 리스트 비어 있음');
                  return _buildEmptyView();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  itemCount: recs.length,
                  itemBuilder: (context, index) {
                    final rec = recs[index] as Map<String, dynamic>;
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final delay = 0.2 + (index * 0.1);
                        final curvedAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(delay, 1.0, curve: Curves.easeOutQuint),
                        );
                        final itemFade = curvedAnimation.value;
                        final itemSlide = (1.0 - curvedAnimation.value) * 50;
                        
                        return Opacity(
                          opacity: itemFade,
                          child: Transform.translate(
                            offset: Offset(0, itemSlide),
                            child: child,
                          ),
                        );
                      },
                      child: RecommendationCard(
                        mountain: rec,
                        fadeAnimation: _fadeAnimation,
                        index: index,
                        onTap: () => _showDetailDialog(context, rec),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}