import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/app_state.dart';
import '../../models/mountain_map.dart';
import '../../services/mountain_map_service.dart';
import '../../utils/app_colors.dart';
import 'mountain_detail_screen.dart';

class MountainMapScreen extends StatefulWidget {
  const MountainMapScreen({Key? key}) : super(key: key);

  @override
  State<MountainMapScreen> createState() => _MountainMapScreenState();
}

class _MountainMapScreenState extends State<MountainMapScreen> with SingleTickerProviderStateMixin {
  final MountainMapService _mountainMapService = MountainMapService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  // 애니메이션 컨트롤러 추가
  late AnimationController _animationController;
  
  NaverMapController? _mapController;
  List<MountainMap> _mountains = [];
  bool _isLoading = true;
  MountainMap? _selectedMountain;
  Map<String, NOverlayImage>? _iconCache;
  Map<String, NOverlayImage>? _largeIconCache;
  Map<String, NMarker> _markerCache = {};
  String? _lastTappedMarkerId;

  // 지도/리스트 보기 토글
  bool _isMapView = true;

  // 리스트 데이터 관련 변수
  List<dynamic> _mountainList = [];
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  final int _pageSize = 10;
  bool _isSearching = false;
  String _searchQuery = '';
  
  // 테마 색상
  final Color _primaryColor = AppColors.primary;
  final Color _secondaryColor = Colors.teal;
  final Color _accentColor = Colors.amber;
  
  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _loadMountains();
    _loadMountainList();

    // 스크롤 리스너 추가 (무한 스크롤용)
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 무한 스크롤 리스너
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreMountains();
    }
  }

  // 산 정보 로드 (로컬 또는 API)
  Future<void> _loadMountains() async {
    try {
      setState(() => _isLoading = true);

      // 앱 상태에서 토큰 가져오기
      final token = context.read<AppState>().accessToken ?? '';

      // 서비스를 통해 산 정보 가져오기
      final mountains = await _mountainMapService.getMountains(token);

      setState(() {
        _mountains = mountains;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('산 정보를 불러오는데 실패했습니다', isError: true);
      }
    }
  }

  // 사용자 경험을 개선한 스낵바
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade800 : Color(0xFF52A486),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // 산 리스트 데이터 로드 (API)
  Future<void> _loadMountainList({bool resetList = false}) async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      if (resetList) {
        _currentPage = 0;
        _mountainList = [];
        _hasReachedEnd = false;
      }
    });

    try {
      // 앱 상태에서 토큰과 baseUrl 가져오기
      final appState = context.read<AppState>();
      final token = appState.accessToken ?? '';
      final baseUrl = dotenv.env['BASE_URL'] ?? '';

      // API URL 구성
      String url = '$baseUrl/mountain/list?page=$_currentPage&size=$_pageSize';
      if (_searchQuery.isNotEmpty) {
        url = '$baseUrl/mountain/list?search=$_searchQuery';
      }

      // API 요청
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> dataMap = jsonDecode(decoded);

        if (dataMap['status'] == true) {
          if (_searchQuery.isNotEmpty) {
            // 검색 결과는 데이터 구조가 다름
            final List<dynamic> mountains = dataMap['data'];
            setState(() {
              _mountainList = mountains;
              _isLoadingMore = false;
              _hasReachedEnd = true; // 검색 결과는 페이징 없음
            });
          } else {
            // 일반 리스트 데이터 구조 처리
            final data = dataMap['data'];
            final List<dynamic> mountains = data['mountains'];

            setState(() {
              if (resetList) {
                _mountainList = mountains;
              } else {
                _mountainList.addAll(mountains);
              }

              _currentPage = data['currentPage'];
              _totalPages = data['totalPages'];
              _hasReachedEnd =
                  data['last'] ?? (_currentPage >= _totalPages - 1);
              _isLoadingMore = false;
              _currentPage++;
            });
          }
        } else {
          setState(() => _isLoadingMore = false);
          _showSnackBar('데이터를 불러오는데 실패했습니다', isError: true);
        }
      } else {
        setState(() => _isLoadingMore = false);
        _showSnackBar('서버 응답 오류: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showSnackBar('데이터 로드 중 오류 발생: $e', isError: true);
    }
  }

  // 더 많은 산 데이터 로드 (무한 스크롤)
  Future<void> _loadMoreMountains() async {
    if (_searchQuery.isNotEmpty) return; // 검색 중에는 추가 로드 안함
    await _loadMountainList();
  }

  // 검색 수행
  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
    await _loadMountainList(resetList: true);
  }

  // 검색 취소
  void _cancelSearch() {
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _searchController.clear();
    });
    _loadMountainList(resetList: true);
  }

  // 산 정보 강제 새로고침 (API에서 다시 가져오기)
  Future<void> _refreshMountainData() async {
    try {
      // 로딩 상태 표시
      setState(() => _isLoading = true);

      // 앱 상태에서 토큰 가져오기
      final token = context.read<AppState>().accessToken ?? '';

      // 로컬 캐시 데이터 삭제
      await _mountainMapService.clearLocalData();

      // API에서 데이터 다시 가져오기
      final mountains = await _mountainMapService.fetchMountainsFromApi(token);

      setState(() {
        _mountains = mountains;
        _isLoading = false;
      });

      // 지도에 업데이트된 데이터 표시
      if (_mapController != null) {
        await _showMountainsOnMap();
      }

      // 성공 메시지 표시
      _showSnackBar('산 정보가 업데이트되었습니다');

      // 리스트 데이터도 새로고침
      _loadMountainList(resetList: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('산 정보 업데이트 실패: $e', isError: true);
    }
  }

  // 난이도에 따른 마커 색상 설정 - 더 세련된 색상으로 변경
  Color _getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color(0xFFE53935); // 빨간색 (어려움)
      case 'M':
        return const Color(0xFFFDD835); // 노란색 (보통)
      case 'L':
        return const Color(0xFF52A486); // 초록색 (쉬움)
      default:
        return const Color(0xFF1E88E5); // 파란색 (기본)
    }
  }

  // 레벨별 일반 크기 아이콘 캐싱 함수 - 디자인 개선
  Future<Map<String, NOverlayImage>> _prepareLevelIcons(BuildContext ctx) async {
    // 이미 캐시가 있으면 반환
    if (_iconCache != null) {
      return _iconCache!;
    }

    final levels = ['H', 'M', 'L', 'default'];
    final cache = <String, NOverlayImage>{};

    for (var level in levels) {
      final color = _getLevelColor(level);
      cache[level] = await NOverlayImage.fromWidget(
        widget: Stack(
          alignment: Alignment.center,
          children: [
            // 그림자 효과
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // 흰색 배경 원
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
            // 컬러 아이콘
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        size: const Size(32, 32),
        context: ctx,
      );
    }

    _iconCache = cache;
    return cache;
  }

  // 레벨별 큰 크기 아이콘 캐싱 함수 (애니메이션용) - 디자인 개선
  Future<Map<String, NOverlayImage>> _prepareLargeLevelIcons(BuildContext ctx) async {
    // 이미 캐시가 있으면 반환
    if (_largeIconCache != null) {
      return _largeIconCache!;
    }

    final levels = ['H', 'M', 'L', 'default'];
    final cache = <String, NOverlayImage>{};

    for (var level in levels) {
      final color = _getLevelColor(level);
      cache[level] = await NOverlayImage.fromWidget(
        widget: Stack(
          alignment: Alignment.center,
          children: [
            // 그림자 효과
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            // 흰색 배경 원 (확대 크기)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
              ),
            ),
            // 컬러 아이콘 (확대 크기)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        size: const Size(46, 46),
        context: ctx,
      );
    }

    _largeIconCache = cache;
    return cache;
  }

  // 네이버 지도에 산 마커 일괄 표시 - 성능 및 가독성 개선
  Future<void> _showMountainsOnMap() async {
    if (_mapController == null || _mountains.isEmpty) {
      return;
    }

    try {
      // 1. 오버레이 초기화
      await _mapController!.clearOverlays();
      _markerCache.clear();
      _lastTappedMarkerId = null;

      // 2. 아이콘 캐시 가져오기
      final iconCache = await _prepareLevelIcons(context);

      // 큰 아이콘도 미리 준비 (애니메이션용)
      await _prepareLargeLevelIcons(context);

      // 3. 모든 NMarker 객체 생성
      final overlays = <NAddableOverlay>{};
      for (var mountain in _mountains) {
        final icon = iconCache[mountain.level] ?? iconCache['default']!;
        final markerId = 'mountain-${mountain.id}';

        final marker = NMarker(
          id: markerId,
          position: NLatLng(mountain.latitude, mountain.longitude),
          icon: icon,
          caption: NOverlayCaption(
            text: mountain.name,
            textSize: 12,
            color: Colors.black87,
            haloColor: Colors.white.withOpacity(0.8),
          ),
          anchor: const NPoint(0.5, 0.5), // 마커의 중심이 정확히 좌표에 위치하도록
        );

        // 마커 클릭 이벤트 설정
        marker.setOnTapListener((overlay) {
          // 마커 애니메이션 효과 적용
          _handleMarkerTap(markerId, mountain.level);

          // 산 정보 바텀시트 표시
          _onMarkerTap(mountain);
        });

        // 마커 캐시에 저장
        _markerCache[markerId] = marker;

        overlays.add(marker);
      }

      // 4. 일괄 추가
      await _mapController!.addOverlayAll(overlays);

      // 5. 카메라 이동
      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          NLatLngBounds(
            southWest: const NLatLng(33.0, 125.0), // 한반도 남서쪽
            northEast: const NLatLng(38.5, 132.0), // 한반도 북동쪽
          ),
          padding: const EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      _showSnackBar('지도에 산 정보를 표시하는데 실패했습니다', isError: true);
    }
  }

  // 마커 클릭 시 애니메이션 처리 - 부드러운 트랜지션 추가
  Future<void> _handleMarkerTap(String markerId, String level) async {
    try {
      // 이전에 클릭한 마커가 있고 현재 클릭한 마커와 다른 경우
      if (_lastTappedMarkerId != null && _lastTappedMarkerId != markerId) {
        // 이전 마커를 원래 크기로 복원
        final previousMarker = _markerCache[_lastTappedMarkerId];
        if (previousMarker != null && _iconCache != null) {
          final prevMountainId = int.parse(_lastTappedMarkerId!.split('-')[1]);
          final prevMountain =
              _mountains.firstWhere((m) => m.id == prevMountainId);
          previousMarker.setIcon(
              _iconCache![prevMountain.level] ?? _iconCache!['default']!);
        }
      }

      // 클릭한 마커를 확대된 크기로 변경
      final marker = _markerCache[markerId];
      if (marker != null && _largeIconCache != null) {
        marker.setIcon(_largeIconCache![level] ?? _largeIconCache!['default']!);
        
        // 마커를 살짝 튀어오르게 하는 효과 (Navermap API에서 지원하지 않아 시각적으로만 강조)
        marker.setGlobalZIndex(1000); // 다른 마커보다 위에 표시
      }

      // 현재 클릭한 마커 ID 저장
      _lastTappedMarkerId = markerId;
    } catch (e) {
      debugPrint('마커 애니메이션 처리 중 오류: $e');
    }
  }

  // 마커 탭 시 산 정보 표시
  void _onMarkerTap(MountainMap mountain) {
    setState(() {
      _selectedMountain = mountain;
    });
    
    // 바텀 시트로 산 상세 정보 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMountainDetailDialog(mountain),
    );
  }

  // 리스트 아이템에서 산 정보 표시
  void _onMountainItemTap(dynamic mountain) {
    // 상세 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MountainDetailScreen(mountainId: mountain['id']),
      ),
    );
  }

// MountainMapScreen 클래스의 _buildInfoCard 메서드 수정
Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 컨텐츠에 맞게 높이 조정
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12, // 폰트 크기 축소
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700], // textColor 대신 Colors.grey[700] 사용
                ),
              ),
              const SizedBox(height: 1),
              // FittedBox로 감싸 긴 텍스트가 줄바꿈되지 않도록 함
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // 산 상세 정보 바텀 시트 
Widget _buildMountainDetailDialog(MountainMap mountain) {
  final level = mountain.level;
  final levelColor = _getLevelColor(level);
  final difficultyText = () {
    switch (level) {
      case 'L':
        return '쉬움';
      case 'M':
        return '보통';
      case 'H':
        return '어려움';
      default:
        return '보통';
    }
  }();

  // 아이콘 선택 함수
  IconData getDifficultyIcon(String level) {
    switch (level) {
      case 'H':
        return Icons.trending_up;
      case 'M':
        return Icons.trending_flat;
      case 'L':
        return Icons.trending_down;
      default:
        return Icons.landscape;
    }
  }

  // 높이 값 포맷 개선 추가
  final double? altitudeValue = mountain.altitude is double ? mountain.altitude as double : null;
  final String formattedAltitude = altitudeValue != null 
      ? '${altitudeValue % 1 == 0 ? altitudeValue.toInt() : altitudeValue}m' // 소수점이 .0인 경우 정수로 표시
      : '${mountain.altitude}m';

  return Container(
    margin: EdgeInsets.only(
      top: MediaQuery.of(context).size.height * 0.1,
    ),
    decoration: const BoxDecoration(
      color: Colors.transparent,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더 (이미지 제거하고 산 이름과 닫기 버튼만 유지)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      // 산 이름 및 아이콘
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: levelColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.terrain,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mountain.name,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 닫기 버튼
                      Positioned(
                        top: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black.withOpacity(0.1),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.black54),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 정보 라벨
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            '기본 정보',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                      
                      // 정보 행 - 외곽선 제거하고 높이/난이도 나란히 표시
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          // 외곽선 제거 (Border.all 코드 제거)
                        ),
                        child: Row(  // 수직 Column에서 가로 Row로 변경
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // 균등하게 배치
                          children: [
                            // 높이 정보
                            Row(
                              children: [
                                // 아이콘
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: levelColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.height,
                                    color: levelColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // 내용
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '높이',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      formattedAltitude,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // 구분선
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[300],
                            ),
                            
                            // 난이도 정보
                            Row(
                              children: [
                                // 아이콘
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: levelColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    getDifficultyIcon(level),
                                    color: levelColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // 내용
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '난이도',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      difficultyText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                                
                // 설명 섹션
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '상세 설명',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mountain.description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 하단 버튼
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // 지도에서 확인 버튼 - 현재 지도 위치로 이동
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // 지도로 이동하거나 현재 지도 위치를 업데이트
                            if (_mapController != null) {
                              _mapController!.updateCamera(
                                NCameraUpdate.scrollAndZoomTo(
                                  target: NLatLng(mountain.latitude, mountain.longitude),
                                  zoom: 13,
                                ),
                              );
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: levelColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            '지도에서 확인하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
        ),
      ],
    ),
  );
}
  
Widget _buildMountainListItem(dynamic mountain) {
  final level = mountain['level'] as String? ?? 'M';
  final difficultyText = () {
    switch (level) {
      case 'L':
        return '쉬움';
      case 'M':
        return '보통';
      case 'H':
        return '어려움';
      default:
        return '보통';
    }
  }();
  
  final levelColor = _getLevelColor(level);
  final images = mountain['images'] as List<dynamic>;
  final hasImage = images.isNotEmpty;
  final altitude = mountain['altitude'] ?? 0;

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _onMountainItemTap(mountain),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 이미지 - 없을 경우 로컬 에셋 이미지 사용
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                  ? Image.network(
                      images[0],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Image.asset(
                          'lib/assets/images/mount_default.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                    )
                  : Image.asset(
                      'lib/assets/images/mount_default.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
              ),
              const SizedBox(width: 12),
              
              // 산 정보
              Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 산 이름 (오른쪽으로 이동)
                  Padding(
                    padding: const EdgeInsets.only(left: 18), 
                    child: Text(
                      mountain['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8), 

                    // 위치 정보
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mountain['location'] ?? '위치 정보 없음',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // 고도와 난이도를 한 줄에 표시 
                    Row(
                      children: [
                        // 고도 정보
                        Icon(Icons.height, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${altitude}m',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        
                        // 난이도 정보 (색상으로 구분)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: levelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          difficultyText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
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
    ),
  );
}

// 산 이미지 플레이스홀더
Widget _buildMountainPlaceholder() {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[300]!,
          Colors.grey[200]!,
        ],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.terrain,
          size: 36,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 4),
        Text(
          '이미지 없음',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// 리스트 화면 위젯 - 디자인 개선
Widget _buildListView() {
  return Column(
    children: [
      // 검색 바 영역
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '산 이름을 검색해주세요',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.search, color: _primaryColor),
            ),
            // suffixIcon 부분을 제거
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Color(0xFF52A486), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          style: const TextStyle(fontSize: 15),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
      ),

      // 리스트 내용
      Expanded(
        child: _mountainList.isEmpty && !_isLoadingMore
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.terrain,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? '검색 결과가 없습니다' : '산 정보가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 8),
                    Text(
                      '다른 검색어로 다시 시도해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: _cancelSearch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('검색 초기화'),
                    ),
                  ],
                ],
              ),
            )
          : RefreshIndicator(
              color: _primaryColor,
              onRefresh: () => _loadMountainList(resetList: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _mountainList.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _mountainList.length) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    );
                  }
                  return _buildMountainListItem(_mountainList[index]);
                },
              ),
            ),
      ),
    ],
  );
}

// 필터 칩 위젯
Widget _buildFilterChip({
  required String label,
  required bool isSelected,
  Color? color,
  required VoidCallback onTap,
}) {
  final chipColor = color ?? _primaryColor;
  
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? chipColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? chipColor : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            Icon(
              Icons.check_circle,
              size: 14,
              color: chipColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? chipColor : Colors.grey[700],
            ),
          ),
        ],
      ),
    ),
  );
}

  // 토글 버튼 위젯 - 부드러운 애니메이션 추가
  Widget _buildToggleButton() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _isMapView 
                ? 0.0
                : 3.14159, // 180도 회전 (π 라디안)
            child: FloatingActionButton.extended(
              backgroundColor: Color(0xFF52A486),
              foregroundColor: Colors.white,
              elevation: 4,
              label: Row(
                children: [
                  Icon(
                    _isMapView ? Icons.view_list : Icons.map,
                    size: 20,
                  ),
                ],
              ),
              onPressed: () {
                setState(() {
                  _isMapView = !_isMapView;
                  
                  // 애니메이션 방향 설정
                  if (_isMapView) {
                    _animationController.reverse();
                  } else {
                    _animationController.forward();
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  // 로딩 인디케이터
  Widget _buildLoadingIndicator() {
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // 고정된 배경색
        scrolledUnderElevation: 0, // 스크롤 시 엘리베이션 변화 방지
        title: Text(
          _isMapView ? '전체 산 지도' : '산 전체 목록',  // _isMapView 상태에 따라 타이틀 변경
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF52A486)),
        actions: [
          // 데이터 새로고침 버튼 - 지도 뷰일 때만 표시
          if (_isMapView)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF52A486)),
              tooltip: '산 정보 새로고침',
              onPressed: _isLoading ? null : _refreshMountainData,
            ),
        ],
      ),
      // 기존 body 내용은 그대로 유지
      body: Container(
        decoration: BoxDecoration(
          // 배경 그라데이션 (지도 모드에서는 보이지 않음)
          gradient: !_isMapView ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[100]!,
            ],
          ) : null,
        ),
        child: Stack(
          children: [
            // 로딩 화면
            if (_isLoading)
              _buildLoadingIndicator(),
              
            // 지도 뷰
            if (!_isLoading && _isMapView)
              NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: const NLatLng(36.0, 128.0), // 한국 중앙 좌표
                    zoom: 7,
                  ),
                  mapType: NMapType.basic,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8, 
                    horizontal: 0,
                  ),
                  logoAlign: NLogoAlign.rightBottom,
                  activeLayerGroups: [
                    NLayerGroup.mountain,
                    NLayerGroup.building,
                    NLayerGroup.transit,
                  ],
                  nightModeEnable: MediaQuery.of(context).platformBrightness == Brightness.dark,
                ),
                onMapReady: (controller) {
                  _mapController = controller;
                  // 지도가 준비되면 산 마커 표시
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _showMountainsOnMap();
                    }
                  });
                },
              ),
              
            // 리스트 뷰
            if (!_isLoading && !_isMapView)
              _buildListView(),
              
            // 토글 버튼 (항상 표시)
            if (!_isLoading)
              _buildToggleButton(),
              
            // 지도 모드에서 사용 안내 툴팁 (추가적인 UX 향상)
            if (!_isLoading && _isMapView)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF52A486),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '마커를 탭하면 산의 정보를 확인할 수 있어요',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}