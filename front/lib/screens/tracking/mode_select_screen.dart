// mode_select_screen.dart: 모드 선택 화면
// - 다양한 트래킹 모드 제공 (나 vs 나, 나 vs 친구, 나 vs AI추천, 일반 등산)
// - 모드 선택 후 실시간 트래킹 시작

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../services/mode_service.dart';
import 'friend_search_screen.dart';
import 'package:logger/logger.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  // 선택된 기록 ID
  int? _selectedRecordId;
  final logger = Logger();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // 기본 배경색 흰색
        elevation: 0,
        titleSpacing: 0,
        scrolledUnderElevation: 0, // 스크롤해도 그림자 없음
        title: Text(
          '등산 모드 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF52A486)),
          onPressed: () {
            // 등산로 선택 화면으로 돌아가기 (산 정보 유지)
            appState.backToRouteSelect();
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(70), // 추가 공간 확보
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF52A486).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF52A486).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 산 아이콘
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFF52A486).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.terrain,
                      color: Color(0xFF52A486),
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 10),
                  // 산 이름과 등산로 이름
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.selectedMountain ?? '선택된 산 없음',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          appState.selectedRoute?.name ?? '선택된 등산로 없음',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 모드 선택 카드 영역
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // 나 vs 나 모드
                  _buildEnhancedModeCard(
                    title: '나 vs 나',
                    description: '과거의 나와 경쟁하며 등산해보세요!\n이전 기록을 갱신할 수 있어요',
                    icon: Icons.history,
                    color: Color(0xFF52A486),
                    onTap: () => _showTrackingOptionsModal(context, appState),
                  ),

                  const SizedBox(height: 16),

                  // 나 vs 친구 모드
                  _buildEnhancedModeCard(
                    title: '나 vs 친구',
                    description: '친구와 경쟁하며 등산해보세요!\n친구의 기록과 실시간으로 비교할 수 있어요',
                    icon: Icons.people,
                    color: Color(0xFF52A486),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendSearchScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 일반 등산 모드
                  _buildEnhancedModeCard(
                    title: '일반 등산',
                    description: '경쟁 없이 편안하게 등산해보세요!\n기본적인 등산 정보만 제공돼요',
                    icon: Icons.directions_walk,
                    color: Color(0xFF52A486),
                    onTap: () async {
                      try {
                        await appState.startTracking(
                          '일반 등산',
                          recordId: null,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('등산 시작 중 오류가 발생했습니다: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                Color(0xFF52A486).withOpacity(0.2), // 외곽선 색상을 산/등산로 카드와 동일하게 설정
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 색상 부분 - 아이콘 및 텍스트 크기 축소
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), // 상단 컨테이너 색상은 유지
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 아이콘 크기 축소
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white, // 아이콘 배경은 흰색 유지
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20.0,
                        ),
                      ),
                      SizedBox(width: 14),
                      // 타이틀 텍스트 크기 축소
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),

                // 하단 설명 부분 - 배경색 흰색 명시
                Container(
                  color: Colors.white, // 하단 부분 배경색 흰색으로 명시
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12.0,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '시작하기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
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

  Future<void> _showTrackingOptionsModal(
      BuildContext context, AppState appState) async {
    final modeService = ModeService();
    _selectedRecordId = null;

    try {
      // 로딩 표시 - 간결한 디자인
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      // 이전 등산 기록 목록 가져오기
      final mountainId = appState.selectedRoute?.mountainId ?? 0;
      final pathId = appState.selectedRoute?.id ?? 0;
      final token = appState.accessToken ?? '';

      final recordsList = await modeService.getMyTrackingOptions(
        mountainId: mountainId.toInt(),
        pathId: pathId.toInt(),
        token: token,
      );

      // 로딩 다이얼로그 닫기
      if (!mounted) return;
      if (context.mounted) Navigator.of(context).pop();

      if (recordsList.isEmpty) {
        // 이전 기록이 없는 경우
        if (!mounted) return;
        if (context.mounted) {
          _showNoRecordsDialog(context);
        }
        return;
      }

      // 이전 기록이 있는 경우 목록 표시 - 디자인 개선
      if (!mounted) return;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  insetPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 부분
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFF52A486).withOpacity(0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history,
                                  color: Color(0xFF52A486),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '이전 등산 기록',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '비교할 기록을 선택해주세요',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 목록 부분
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            itemCount: recordsList.length,
                            itemBuilder: (context, index) {
                              final record = recordsList[index];
                              final recordId = record['recordId'];
                              final date = record['date'];
                              final time = record['time'];

                              final isSelected = _selectedRecordId == recordId;

                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRecordId = recordId;
                                    });

                                    // 디버그 출력 및 앱 상태 업데이트 (기존 코드)
                                    logger.d('===== 선택한 과거 기록 정보 =====');
                                    logger.d('기록 ID: $recordId');
                                    logger.d('날짜: $date');
                                    logger.d('시간(분): $time');
                                    logger.d('시간(포맷): ${_formatMinutes(time)}');
                                    logger
                                        .d('최대 심박수: ${record['maxHeartRate']}');
                                    logger
                                        .d('평균 심박수: ${record['avgHeartRate']}');
                                    logger.d('=============================');

                                    appState.setPreviousRecordData(
                                      date: date,
                                      time: time,
                                      maxHeartRate: record['maxHeartRate'],
                                      avgHeartRate: record['avgHeartRate'],
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFF52A486).withOpacity(0.1)
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected
                                            ? Color(0xFF52A486)
                                            : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        // 선택 표시 원
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? Color(0xFF52A486)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Color(0xFF52A486)
                                                  : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 14,
                                                )
                                              : null,
                                        ),
                                        SizedBox(width: 12),

                                        // 날짜와 시간 정보
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                date,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? Color(0xFF52A486)
                                                      : Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${_formatMinutes(time)}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
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
                              );
                            },
                          ),
                        ),

                        // 버튼 영역
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 취소 버튼
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '취소',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),

                              // 시작하기 버튼
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _selectedRecordId != null
                                        ? () {
                                            Navigator.of(context).pop();

                                            // 선택된 기록 정보 출력 (기존 코드)
                                            final recordId = _selectedRecordId;
                                            final selectedRecord =
                                                recordsList.firstWhere(
                                              (record) =>
                                                  record['recordId'] ==
                                                  recordId,
                                              orElse: () => {
                                                'recordId': 0,
                                                'date': '알 수 없음',
                                                'time': 0
                                              },
                                            );

                                            debugPrint(
                                                '===== 시작하는 과거 기록 최종 정보 =====');
                                            debugPrint(
                                                '기록 ID: ${selectedRecord['recordId']}');
                                            debugPrint(
                                                '날짜: ${selectedRecord['date']}');
                                            debugPrint(
                                                '시간(분): ${selectedRecord['time']}');
                                            debugPrint(
                                                '시간(포맷): ${_formatMinutes(selectedRecord['time'])}');
                                            debugPrint('시작하는 모드: 나 vs 나');
                                            debugPrint(
                                                '====================================');

                                            appState.startTracking(
                                              '나 vs 나',
                                              recordId: _selectedRecordId,
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF52A486),
                                      disabledBackgroundColor:
                                          Colors.grey.shade300,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '시작하기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    } catch (e) {
      // 오류 처리
      debugPrint('등산 기록 목록 조회 오류: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showNoRecordsDialog(context);
      }
    }
  }

  // 기록이 없는 경우 표시할 다이얼로그 - 디자인 개선
  void _showNoRecordsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 아이콘
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF3F3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF5151),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),

                // 제목
                Text(
                  '등산 기록 없음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 12),

                // 내용
                Text(
                  '선택하신 등산로의 기록이 없어요\n일반 모드로 먼저 등산해 보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),

                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF52A486),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 분 형식 변환 (예: 72분 -> 1h 12m)
  String _formatMinutes(num minutes) {
    final int hrs = (minutes / 60).floor();
    final int mins = (minutes % 60).toInt();

    if (hrs > 0) {
      return '${hrs}시간 ${mins}분';
    } else {
      return '${mins}분';
    }
  }

  Widget _buildModeCardVertical({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 왼쪽: 아이콘
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30.0,
                ),
              ),

              // 중앙: 제목과 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 제목
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),

                    // 설명
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 오른쪽: 화살표 아이콘
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
