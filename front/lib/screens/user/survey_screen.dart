// lib/screens/user/survey_screen.dart

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/app_state.dart';
import '../../widgets/custom_app_bar.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  String? _selectedTheme;
  String? _selectedExperience;
  String? _selectedRegion;
  bool _isLoading = false;
  
  // 배경 그라데이션 색상
  final List<Color> _gradientColors = const [
    Color(0xFFF9FCFB),
    Color(0xFFEDF7F2),
  ];

  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF3D7A64);
  final Color _backgroundColor = const Color(0xFFF5F9F7);
  final Color _accentColor = const Color(0xFFFF8551);
  final Color _textColor = const Color(0xFF333333);

  final List<String> _themes = ['단풍', '아름다운', '계곡'];
  final List<String> _experiences = ['초급', '중급', '고급'];
  final List<String> _regions = [
    '전국',
    '서울',
    '경기',
    '강원',
    '충청',
    '경상',
    '전라',
  ];

  // 테마에 맞는 아이콘 매핑
  final Map<String, IconData> _themeIcons = {
    '단풍': Icons.eco,
    '아름다운': Icons.landscape,
    '계곡': Icons.water,
  };

  // 경험에 맞는 아이콘 매핑
  final Map<String, IconData> _experienceIcons = {
    '초급': Icons.hiking,
    '중급': Icons.trending_up,
    '고급': Icons.flag,
  };

  // 지역에 맞는 아이콘 매핑
  final Map<String, IconData> _regionIcons = {
    '전국': Icons.public,
    '서울': Icons.location_city,
    '경기': Icons.apartment,
    '강원': Icons.terrain,
    '충청': Icons.grass,
    '경상': Icons.park,
    '전라': Icons.waves,
  };

  Future<void> _submitSurvey() async {
    // ▶ 입력값 유효성 확인
    if (_selectedTheme == null ||
        _selectedExperience == null ||
        _selectedRegion == null) {
      debugPrint('▶ _submitSurvey: 선택값 없음'); // 디버그
      _showErrorSnackBar('모든 항목을 선택해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    final userId = appState.userId;
    final token = appState.accessToken;

    debugPrint('▶ userId: $userId, token: ${token?.substring(0, 10)}...');

    if (userId == null || token == null) {
      debugPrint('▶ _submitSurvey: userId 또는 token null');
      _showErrorSnackBar('인증 정보가 없습니다. 다시 로그인해주세요.');
      setState(() => _isLoading = false);
      return;
    }

    final endpoint = '${dotenv.get('AI_BASE_URL')}/submit_survey/$userId';
    debugPrint('▶ 요청 URL: $endpoint');

    try {
      final bodyMap = {
        'theme': _selectedTheme,
        'experience': _selectedExperience,
        'region': _selectedRegion,
      };
      final bodyJson = jsonEncode(bodyMap);
      debugPrint('▶ 요청 바디: $bodyJson');

      final resp = await http
          .post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: bodyJson,
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('요청이 시간 초과되었습니다.');
      });

      debugPrint('▶ HTTP 상태 코드: ${resp.statusCode}');
      final respBody = utf8.decode(resp.bodyBytes);
      debugPrint('▶ 응답 바디(raw): $respBody');

      if (resp.statusCode == 200) {
        final data = jsonDecode(respBody) as Map<String, dynamic>;
        debugPrint('▶ 파싱된 응답: $data');

        final msg = data['message'] as String?;
        if (msg != null) {
          await _showSuccessDialog(msg);
          context.read<AppState>().setSurveyCompleted(true);
          Navigator.of(context).pop();
        } else {
          throw Exception('알 수 없는 응답 형식');
        }
      } else {
        debugPrint('▶ 서버 에러 발생');
        final errData = jsonDecode(respBody) as Map<String, dynamic>?;
        debugPrint('▶ 에러 파싱: $errData');
        final errMsg = errData?['message'] as String? ?? '설문 저장 실패';
        throw Exception(errMsg);
      }
    } on TimeoutException {
      debugPrint('❌ Timeout');
      _showErrorSnackBar('요청 시간이 초과되었습니다.');
    } catch (e) {
      debugPrint('❌ 예외 발생: $e');
      _showErrorSnackBar('에러: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _primaryColor),
            const SizedBox(width: 12),
            const Text('완료'),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: _primaryColor),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required String? selectedValue,
    required List<String> options,
    required Function(String?) onChanged,
    Map<String, IconData>? itemIcons,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 드롭다운 대신 커스텀 UI 사용
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // 커스텀 드롭다운 모달 표시
                    _showCustomSelectionModal(
                      context: context,
                      title: title,
                      options: options,
                      selectedValue: selectedValue,
                      onChanged: onChanged,
                      itemIcons: itemIcons,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (selectedValue != null && itemIcons != null && itemIcons.containsKey(selectedValue))
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(itemIcons[selectedValue], color: _primaryColor, size: 20),
                              ),
                            Text(
                              selectedValue ?? '선택',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: _primaryColor,
                          size: 24,
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
    );
  }

  // 커스텀 선택 모달 표시 함수
  void _showCustomSelectionModal({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onChanged,
    Map<String, IconData>? itemIcons,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selectedValue;
                    
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      leading: isSelected 
                          ? Icon(Icons.check_circle, color: _primaryColor) 
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      trailing: itemIcons != null && itemIcons.containsKey(option)
                          ? Icon(itemIcons[option], color: _primaryColor)
                          : null,
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allFieldsSelected = _selectedTheme != null && 
                           _selectedExperience != null && 
                           _selectedRegion != null;
    
    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 헤더 이미지와 제목
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset('lib/assets/images/logo.png'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '맞춤 등산로 추천',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '당신에게 맞는 최적의 등산로를 찾기 위해\n아래 정보를 알려주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 테마 선택
                _buildSelectionCard(
                  title: '테마',
                  icon: Icons.filter_vintage,
                  selectedValue: _selectedTheme,
                  options: _themes,
                  onChanged: (val) => setState(() => _selectedTheme = val),
                  itemIcons: _themeIcons,
                ),
                
                const SizedBox(height: 16),
                
                // 난이도 선택
                _buildSelectionCard(
                  title: '난이도',
                  icon: Icons.terrain,
                  selectedValue: _selectedExperience,
                  options: _experiences,
                  onChanged: (val) => setState(() => _selectedExperience = val),
                  itemIcons: _experienceIcons,
                ),
                
                const SizedBox(height: 16),
                
                // 지역 선택
                _buildSelectionCard(
                  title: '지역',
                  icon: Icons.place,
                  selectedValue: _selectedRegion,
                  options: _regions,
                  onChanged: (val) => setState(() => _selectedRegion = val),
                  itemIcons: _regionIcons,
                ),
                
                const SizedBox(height: 32),
                
                // 제출 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: (allFieldsSelected && !_isLoading) ? _submitSurvey : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: _primaryColor.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,                            children: [
                              Text(
                                '제출하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}