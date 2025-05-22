import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../models/app_state.dart';
import '../screens/recommend/ai_recommendation_screen.dart';
import '../screens/recommend/theme_recommendation_screen.dart';
import '../screens/recommend/location_recommendation_screen.dart';
import '../screens/user/survey_screen.dart';
import './status_container.dart';
import '../../screens/user/login_screen.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final PageController _pageController = PageController();
  int _currentStatusPage = 0;
  bool _isLoading = false;
  bool _isTooltipVisible = false; // 툴팁 표시 여부를 관리하는 상태
  OverlayEntry? _overlayEntry; // 오버레이 엔트리

  // HomeBody 클래스의 initState 메서드 수정
  @override
  void initState() {
    super.initState();
    // 안전하게 비동기 작업 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // dispose 메서드 추가
  @override
  void dispose() {
    _removeTooltip();
    _pageController.dispose();
    super.dispose();
  }

  // 데이터 초기화 메서드 수정 (등산지수 로드 제거)
  Future<void> _initializeData() async {
    // UI가 멈추지 않도록 지연 추가
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // 비동기 작업 시작
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();
      
      // 설문 상태 가져오기
      await Future.microtask(() => appState.fetchSurveyStatus());
    } catch (e) {
      // 오류 처리
      debugPrint('데이터 초기화 실패: $e');
      if (mounted) {
        Future.microtask(() {
          _showErrorSnackBar('데이터를 불러오는 중 오류가 발생했습니다');
        });
      }
    } finally {
      // 작업 완료, 로딩 상태 해제
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 툴팁 토글 함수
  void _toggleTooltip(BuildContext context) {
    if (_overlayEntry != null) {
      _removeTooltip();
    } else {
      _showTooltip(context);
    }
  }

  // 등급 아이콘 사이의 화살표
  Widget _buildLevelIconArrow() {
    return Icon(
      Icons.arrow_forward_ios,
      color: Colors.white.withOpacity(0.5),
      size: 12,
    );
  }

  Widget _buildXpProgressRow(String label, int xpRequired, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$xpRequired XP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        // 진행도 바
        Stack(
          children: [
            // 배경 바
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // 진행도 표시
            Container(
              height: 6,
              width: progress * (MediaQuery.of(context).size.width * 0.85 - 32 - 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 개선된 XP 진행도 섹션
  Widget _buildXpProgressSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '등급 상승 필요 경험치',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          
          // 경험치 요구사항을 시각적으로 보여주는 프로그레스 바 형태로
          _buildXpProgressRow('씨앗 → 새싹', 100, 0.125),
          SizedBox(height: 10),
          _buildXpProgressRow('새싹 → 나무', 300, 0.375),
          SizedBox(height: 10),
          _buildXpProgressRow('나무 → 열매', 500, 0.625),
          SizedBox(height: 10),
          _buildXpProgressRow('열매 → 산', 800, 1.0),
        ],
      ),
    );
  }

  Widget _buildLevelIconsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLevelIcon('씨앗', 'lib/assets/images/level_one.png'),
          _buildLevelIconArrow(),
          _buildLevelIcon('새싹', 'lib/assets/images/level_two.png'),
          _buildLevelIconArrow(),
          _buildLevelIcon('나무', 'lib/assets/images/level_three.png'),
          _buildLevelIconArrow(),
          _buildLevelIcon('열매', 'lib/assets/images/level_four.png'),
          _buildLevelIconArrow(),
          _buildLevelIcon('산', 'lib/assets/images/level_five.png'),
        ],
      ),
    );
  }

  Widget _buildGradeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHelpSectionTitle('등급이란?'),
        SizedBox(height: 12),
        
        // 설명 텍스트
        _buildHelpText(
          '산에 오를수록 레벨이 올라가는 시스템'
        ),
        SizedBox(height: 16),
        
        // 등급 아이콘 표시 - 조금 더 크고 눈에 띄게
        _buildLevelIconsRow(),
        
        SizedBox(height: 22),
        
        // 경험치 필요량 설명 - 새로운 디자인으로 변경
        _buildXpProgressSection(),
      ],
    );
  }

  // 경험치 획득 행 위젯 개선
  Widget _buildExperienceGainRow(String difficulty, String xp, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Text(
          difficulty,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            xp,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // 경험치 획득 설명 섹션 개선
  Widget _buildExperienceGainSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHelpSectionTitle('경험치 획득 기준'),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildExperienceGainRow('쉬운 산', '20 XP', Icons.hiking),
              Divider(
                height: 16, 
                color: Colors.white.withOpacity(0.2), 
                thickness: 1,
              ),
              _buildExperienceGainRow('보통 산', '40 XP', Icons.landscape),
              Divider(
                height: 16, 
                color: Colors.white.withOpacity(0.2), 
                thickness: 1,
              ),
              _buildExperienceGainRow('어려운 산', '60 XP', Icons.terrain),
            ],
          ),
        ),
      ],
    );
  }

  void _showTooltip(BuildContext context) {
    _removeTooltip(); // 기존 툴팁이 있다면 제거

    final size = MediaQuery.of(context).size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.02), // 배경에 미세한 어두움 추가
          child: SafeArea(
            child: Stack(
              children: [
                // 전체 화면 도움말 컨텐츠
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(255, 131, 193, 162).withOpacity(0.95),
                        Color.fromARGB(255, 113, 186, 152).withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더 부분 수정 - 중첩된 Row 제거
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬로 변경
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 14),
                          Text(
                            '도움말',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 30),
                      
                      // 도움말 내용 (스크롤 가능)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 등급 설명 (개선된 디자인)
                                _buildGradeInfoSection(),
                                
                                SizedBox(height: 30),
                                
                                // 경험치 획득 설명 (개선된 디자인)
                                _buildExperienceGainSection(),
                                
                                // 하단 여백
                                SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 하단 닫기 버튼
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _removeTooltip,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home,
                              color: Color.fromARGB(255, 113, 186, 152),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '홈으로 돌아가기',
                              style: TextStyle(
                                color: Color.fromARGB(255, 113, 186, 152),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // 도움말 섹션 제목 위젯
  Widget _buildHelpSectionTitle(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.white,
            width: 3,
          ),
        ),
      ),
      padding: EdgeInsets.only(left: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18, // 약간 더 큰 글꼴
        ),
      ),
    );
  }

  // 도움말 텍스트 위젯
  Widget _buildHelpText(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16, // 더 큰 글꼴
          height: 1.5,
        ),
      ),
    );
  }

  // 등급 아이콘 위젯
  Widget _buildLevelIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLevelIcon('씨앗', 'lib/assets/images/level_one.png'),
        _buildLevelIcon('새싹', 'lib/assets/images/level_two.png'),
        _buildLevelIcon('나무', 'lib/assets/images/level_three.png'),
        _buildLevelIcon('열매', 'lib/assets/images/level_four.png'),
        _buildLevelIcon('산', 'lib/assets/images/level_five.png'),
      ],
    );
  }

  // 개별 등급 아이콘 위젯
  Widget _buildLevelIcon(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: EdgeInsets.all(6),
          child: Image.asset(
            imagePath,
            width: 24,
            height: 24,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 경험치 행 위젯
  Widget _buildExperienceRow(String difficulty, String xp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          difficulty,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            xp,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // 툴팁 제거 함수
  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // AI 추천 화면으로 이동하는 메서드
  Future<void> _navigateToAiRecommendation() async {
    if (!mounted) return;

    final appState = context.read<AppState>();

    // 설문 완료 여부 확인
    if (!appState.surveyCompleted) {
      _showSurveyDialog();
    } else {
      // 로딩 표시
      final loadingOverlay = _showLoadingOverlay(context);

      try {
        // 필요한 데이터 로드
        await Future.delayed(const Duration(milliseconds: 300));
        loadingOverlay.remove();

        if (mounted) {
          // 화면 전환
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiRecommendationScreen()),
          );
        }
      } catch (e) {
        loadingOverlay.remove();
        if (mounted) {
          _showErrorSnackBar('추천 데이터를 불러오는 중 오류가 발생했습니다');
        }
      }
    }
  }

  // 로딩 오버레이 표시 메서드 - 텍스트 없이 아이콘만 표시
OverlayEntry _showLoadingOverlay(BuildContext context) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Container(
      color: Colors.black.withOpacity(0.3),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Container(
            width: 80,  // 크기 축소 (텍스트가 없으므로)
            height: 80, // 크기 축소 (텍스트가 없으므로)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            // 로딩 아이콘만 표시
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: const Color(0xFF52A486),
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  return overlayEntry;
}

  // 설문 안내 다이얼로그 표시
  void _showSurveyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 아이콘
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B792).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF64B792),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              
              // 제목
              const Text(
                '설문 작성 안내',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              
              // 내용
              const Text(
                '맞춤형 산 추천을 받으시려면\n간단한 설문이 필요해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              
              // 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '나중에 할게요',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _navigateToSurvey();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64B792),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '설문하기',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 설문 화면으로 이동
  Future<void> _navigateToSurvey() async {
    if (!mounted) return;

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SurveyScreen()),
      );

      // 설문이 완료되었으면 상태 갱신
      if (result == true && mounted) {
        // 로딩 표시
        final loadingOverlay = _showLoadingOverlay(context);

        try {
          // 설문 상태 다시 가져오기
          await Future.microtask(() async {
            await context.read<AppState>().fetchSurveyStatus();
          });

          loadingOverlay.remove();

          if (mounted && context.read<AppState>().surveyCompleted) {
            // 설문 완료 상태라면 바로 AI 추천 화면으로 이동
            await Future.delayed(const Duration(milliseconds: 300));
            _navigateToAiRecommendation();
          }
        } catch (e) {
          loadingOverlay.remove();
          if (mounted) {
            _showErrorSnackBar('설문 상태 업데이트 중 오류가 발생했습니다');
          }
        }
      }
    } catch (e) {
      debugPrint('설문 화면 이동 오류: $e');
      if (mounted) {
        _showErrorSnackBar('설문 화면을 불러오는 중 오류가 발생했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // 플로팅 버튼 색상 수정
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () {
            _toggleTooltip(context);
          },
          backgroundColor: Color.fromARGB(255, 113, 186, 152),
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Icon(
            Icons.help_outline,  // 항상 고정된 아이콘 사용
            color: Colors.white,
            size: 24,
          ),
          mini: true,
        ),
      ),

      body: Container(
        color: const Color(0xFFFAFAFA),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 영역
                _buildHeaderSection(appState),
                
                // 컨텐츠 영역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (appState.isLoggedIn) ...[
                        const SizedBox(height: 24),
                        
                        // 상태 컨테이너
                        StatusContainer(
                          pageController: _pageController,
                          currentStatusPage: _currentStatusPage,
                          onPageChanged: (i) => setState(() => _currentStatusPage = i),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 맞춤형 추천 섹션
                        _buildSectionHeader(
                          title: '맞춤형 추천',
                          icon: Icons.favorite_rounded,
                          color: const Color(0xFFFF7043),
                        ),
                        const SizedBox(height: 16),
                        _buildRecommendationCard(
                          title: '나만의 산 추천',
                          description: '취향에 맞는 산을 찾아보세요',
                          image: 'lib/assets/images/ai_recommend.png',
                          backgroundColor: const Color(0xFF64B792),
                          onTap: _navigateToAiRecommendation,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        _buildLoginPrompt(),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // 테마별 추천 섹션
                      _buildSectionHeader(
                        title: '주제별 추천',
                        icon: Icons.category_rounded,
                        color: const Color(0xFF42A5F5),
                      ),
                      const SizedBox(height: 16),
                      
                      // 테마별 카드 그리드
                      SizedBox(
                        height: 140, // 고정 높이
                        child: Row(
                          children: [
                            // 테마별 카드
                            Expanded(
                              child: _buildSmallRecommendationCard(
                                title: '테마별 산 추천',
                                icon: Icons.landscape_rounded,
                                backgroundColor: const Color(0xFF26A69A),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ThemeRecommendationScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // 지역별 카드
                            Expanded(
                              child: _buildSmallRecommendationCard(
                                title: '지역별 산 추천',
                                icon: Icons.map_rounded,
                                backgroundColor: const Color.fromARGB(255, 147, 193, 168),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LocationRecommendationScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 로딩 표시기
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF64B792),
                            ),
                          ),
                        ),
                      
                      // 여백
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(AppState appState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 등산 관련 메시지
          Row(
            children: [
              const Icon(
                Icons.hiking_rounded,
                size: 18,
                color: Color(0xFF64B792),
              ),
              const SizedBox(width: 8),
              Text(
                '어떤 산행을 계획하고 계신가요?',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title, 
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF64B792).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Color(0xFF64B792),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '로그인을 하고 당신만을 위한\n산 추천을 받아보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B792),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required String image,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Ink(
            height: 160,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      Icons.terrain,
                      size: 150,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // 내용
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'AI 추천',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                description,
                                style: TextStyle(
                                  fontSize: 10, // 글자 크기를 14에서 12로 줄임
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3, // 줄 간격도 약간 줄임
                                ),
                                maxLines: 1, // 한 줄로만 표시
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: backgroundColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallRecommendationCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      icon,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // 내용
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '자세히 보기',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 삼각형 클리퍼 추가 (툴팁의 말풍선 꼬리 부분)
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}