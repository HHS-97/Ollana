// tracking_screen.dart: 트래킹 관련 기능을 제공하는 화면
// - 산 검색, 등산로 선택, 모드 선택, 실시간 트래킹 기능 제공
// - AppState를 통해 현재 트래킹 단계 관리
// - 등산 중에는 다른 탭으로 이동해도 상태 유지

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
// import '../../models/mountain.dart';
// import '../../models/hiking_route.dart';
import '../../widgets/tracking/mountain_route_screen.dart';
import 'mode_select_screen.dart';
import 'live_tracking_screen.dart';
import '../../models/hiking_route.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.trackingStage == TrackingStage.tracking) {
          return const LiveTrackingScreen();
        } else if (appState.trackingStage == TrackingStage.modeSelect) {
          return const ModeSelectScreen();
        } else {
          // 산 검색 및 등산로 선택 화면
          return MountainRouteScreen(
            onRouteSelected: (mountain, route) {
              // 여기서 선택된 산과 등산로를 앱 상태에 저장
              appState.selectMountain(mountain.name);
              appState.selectRoute(route);
              // selectRoute 메서드가 이미 TrackingStage를 modeSelect로 설정함
            },
          );
        }
      },
    );
  }
}

class IntegratedMountainRouteScreen extends StatefulWidget {
  const IntegratedMountainRouteScreen({super.key});

  @override
  State<IntegratedMountainRouteScreen> createState() =>
      _IntegratedMountainRouteScreenState();
}

class _IntegratedMountainRouteScreenState
    extends State<IntegratedMountainRouteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _mountainList = [];
  List<String> _filteredMountainList = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _selectedMountain;
  int _selectedRouteIndex = -1;

  // 등산로 데이터
  final List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 초기 데이터 로드 (가장 가까운 산과 등산로)
  void _loadInitialData() {
    setState(() {
      _isLoading = true;
    });

    // 임시 산 목록 데이터
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _mountainList.addAll([
          '설악산',
          '북한산',
          '지리산',
          '한라산',
          '덕유산',
          '소백산',
          '오대산',
          '치악산',
          '월출산',
          '속리산',
          '계룡산',
          '내장산',
          '가야산',
          '주왕산',
          '불굴산'
        ]);
        _filteredMountainList = List.from(_mountainList);

        // 기본 선택 산 (가장 가까운 산이라고 가정)
        _selectedMountain = '북한산';
        _loadRouteData(_selectedMountain!);
      });
    });
  }

  // 산 검색 필터링
  void _filterMountainList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMountainList = List.from(_mountainList);
      } else {
        _filteredMountainList = _mountainList
            .where((mountain) => mountain.contains(query))
            .toList();
      }
    });
  }

  // 선택한 산의 등산로 데이터 로드
  void _loadRouteData(String mountainName) {
    setState(() {
      _isLoading = true;
      _routes.clear();
      _selectedRouteIndex = -1;
    });

    // 임시 등산로 데이터
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _routes.addAll([
          {
            'name': '$mountainName 정상 코스',
            'difficulty': '중',
            'distance': '7.5km',
            'time': '약 4시간',
            'color': Colors.green,
          },
          {
            'name': '$mountainName 초보자 코스',
            'difficulty': '하',
            'distance': '4.2km',
            'time': '약 2시간',
            'color': Colors.blue,
          },
          {
            'name': '$mountainName 전문가 코스',
            'difficulty': '상',
            'distance': '12.3km',
            'time': '약 6시간',
            'color': Colors.red,
          },
        ]);
        _isLoading = false;
      });
    });
  }

  // 다음 단계로 진행 (모드 선택 화면으로)
  void _proceedToModeSelect() {
    if (_selectedRouteIndex >= 0 && _selectedRouteIndex < _routes.length) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.selectMountain(_selectedMountain!);

      // HikingRoute 객체 생성
      final routeData = _routes[_selectedRouteIndex];
      final route = HikingRoute(
        id: _selectedRouteIndex + 1,
        mountainId: 1, // 산 ID 추가 (숫자로 변경)
        name: routeData['name'],
        difficulty: routeData['difficulty'],
        distance:
            (double.tryParse(routeData['distance'].replaceAll('km', '')) ?? 5.0)
                .toInt(),
        estimatedTime: int.tryParse(
                routeData['time'].replaceAll('약 ', '').replaceAll('시간', '')) ??
            120,
        path: [
          {'latitude': 37.5665, 'longitude': 126.9780},
          {'latitude': 37.5690, 'longitude': 126.9800},
          {'latitude': 37.5720, 'longitude': 126.9830},
          {'latitude': 37.5760, 'longitude': 126.9876},
        ],
      );

      appState.selectRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 검색 필드
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '등반할 산을 검색하세요...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterMountainList('');
                              setState(() {
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    _filterMountainList(value);
                    setState(() {
                      _isSearching = value.isNotEmpty;
                    });
                  },
                  onTap: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // 메인 콘텐츠 영역 (산 검색 결과 또는 등산로 맵/리스트)
          Expanded(
            child: _isSearching
                ? _buildMountainSearchResults()
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRouteContent(),
          ),

          // 하단 버튼 (다음 단계로)
          if (!_isSearching && _selectedRouteIndex >= 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _proceedToModeSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 산 검색 결과 목록
  Widget _buildMountainSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _filteredMountainList.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          child: ListTile(
            title: Text(_filteredMountainList[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedMountain = _filteredMountainList[index];
                _isSearching = false;
                _searchController.clear();
              });
              _loadRouteData(_selectedMountain!);
            },
          ),
        );
      },
    );
  }

  // 등산로 맵과 리스트
  Widget _buildRouteContent() {
    return Column(
      children: [
        // 지도 영역 (실제 네이버 지도 통합 시 대체)
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '산 등산로',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 간단한 등산로 시각화
                      Container(
                        width: 240,
                        height: 160,
                        color: Colors.white,
                        child: CustomPaint(
                          painter: RoutePainter(
                            routes: _routes,
                            selectedIndex: _selectedRouteIndex,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    'Click!',
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 등산로 리스트
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: _selectedRouteIndex == index
                      ? Colors.grey[200]
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _selectedRouteIndex == index
                          ? route['color']
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      route['name'],
                      style: TextStyle(
                        fontWeight: _selectedRouteIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '난이도: ${route['difficulty']} • 거리: ${route['distance']} • 시간: ${route['time']}',
                    ),
                    leading: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        color: route['color'],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedRouteIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// 등산로 시각화를 위한 커스텀 페인터
class RoutePainter extends CustomPainter {
  final List<Map<String, dynamic>> routes;
  final int selectedIndex;

  RoutePainter({
    required this.routes,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 산 정상 표시
    final titlePaint = TextPainter(
      text: const TextSpan(
        text: '산 정상',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePaint.layout();
    titlePaint.paint(canvas, Offset(size.width / 2 - titlePaint.width / 2, 10));

    // 등산로 그리기
    if (routes.isEmpty) return;

    final paths = [
      Path()
        ..moveTo(40, size.height - 20)
        ..lineTo(80, 40),
      Path()
        ..moveTo(size.width / 2, size.height - 20)
        ..lineTo(size.width / 2 + 20, 40),
      Path()
        ..moveTo(size.width - 40, size.height - 20)
        ..lineTo(size.width - 80, 40),
    ];

    // 등산로 경로
    for (int i = 0; i < routes.length && i < paths.length; i++) {
      final pathPaint = Paint()
        ..color = routes[i]['color']
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == selectedIndex ? 4 : 2;

      canvas.drawPath(paths[i], pathPaint);
    }

    // 미션형 표시
    if (routes.isNotEmpty) {
      final missionPaint = TextPainter(
        text: const TextSpan(
          text: '미션형 등산로',
          style: TextStyle(
            fontSize: 12,
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      missionPaint.layout();
      missionPaint.paint(canvas, Offset(20, size.height / 2));
    }

    // 선택된 경로 표시
    if (selectedIndex >= 0 && selectedIndex < routes.length) {
      final routeLabel = TextPainter(
        text: TextSpan(
          text: '선택한 등산로',
          style: TextStyle(
            fontSize: 12,
            color: routes[selectedIndex]['color'],
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      routeLabel.layout();
      routeLabel.paint(
          canvas, Offset(size.width - routeLabel.width - 10, size.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
