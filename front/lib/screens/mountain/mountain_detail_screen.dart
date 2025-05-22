import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class MountainDetailScreen extends StatefulWidget {
  final int mountainId;

  const MountainDetailScreen({Key? key, required this.mountainId})
      : super(key: key);

  @override
  State<MountainDetailScreen> createState() => _MountainDetailScreenState();
}

class _MountainDetailScreenState extends State<MountainDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _mountainData = {};
  int _currentImageIndex = 0;
  NaverMapController? _mapController;
  ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  
  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);

  @override
  void initState() {
    super.initState();
    _loadMountainDetail();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // 스크롤 리스너 해제
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // 확장 높이의 절반 이상 스크롤 했을 때 상태 변경
      final bool isCollapsed = _scrollController.offset > 160;
      if (isCollapsed != _isCollapsed) {
        setState(() {
          _isCollapsed = isCollapsed;
        });
      }
    }
  }

  // 산 상세 정보 로드
  Future<void> _loadMountainDetail() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      final url = Uri.parse('$baseUrl/mountain/detail/${widget.mountainId}');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);

        if (data['status'] == true) {
          setState(() {
            _mountainData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '데이터를 불러오는데 실패했습니다.';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '서버 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '데이터 로드 중 오류 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 UI 설정을 앱 전체에 적용
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingView()
          : _hasError
              ? _buildErrorView()
              : _buildDetailView(),
    );
  }

  // 로딩 화면
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

  // 오류 화면
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage, 
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMountainDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24, 
                vertical: 12
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // 상세 정보 화면
  Widget _buildDetailView() {
    return CustomScrollView(
      controller: _scrollController, 
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 앱바 및 이미지 슬라이더
        _buildSliverAppBar(),
        
        // 상세 정보 콘텐츠
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            //margin: const EdgeInsets.only(top: -24),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(),
                const SizedBox(height: 24),
                _buildWeatherInfo(),
                const SizedBox(height: 24),
                _buildPathMapSection(),
                const SizedBox(height: 24),
                _buildDescriptionSection(),
                // 하단 여백
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // 슬라이버 앱바 (이미지 슬라이더 포함)
Widget _buildSliverAppBar() {
  final List<dynamic> images = _mountainData['images'] ?? [];
  
  return SliverAppBar(
    expandedHeight: 320,
    pinned: true,
    stretch: true,
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.white,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    // 스크롤 상태에 따라 leading 위젯 변경
    leading: _isCollapsed
        // 축소된 상태 - 기본 뒤로가기 버튼 사용
        ? null
        // 확장된 상태 - 둥근 컨테이너
        : Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
    iconTheme: IconThemeData(color: Colors.black), // 아이콘 색상 설정
    foregroundColor: Colors.black, // 텍스트 색상 설정
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          // 이미지 슬라이더
          images.isNotEmpty
              ? CarouselSlider.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index, realIndex) {
                    final imageUrl = images[index];
                    final safeUrl = getImageUrl(imageUrl);
                    return Image.network(
                      safeUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // 오류 발생 시 로컬 에셋 이미지 표시
                        return Image.asset(
                          'lib/assets/images/mount_default.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    );
                  },
                  options: CarouselOptions(
                    height: 350,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    enableInfiniteScroll: images.length > 1,
                    autoPlay: images.length > 1,
                    autoPlayInterval: const Duration(seconds: 5),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                )
              : Image.asset(
                  'lib/assets/images/mount_default.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
          
          // 그라데이션 효과
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
            
            // 이미지 인디케이터
            if (images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: index == _currentImageIndex ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _currentImageIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            
            // 산 이름 및 기본 정보
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Text(
                _mountainData['name'] ?? '산 이름',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 4,
                      color: Color.fromARGB(130, 0, 0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 기본 정보 섹션
  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  icon: Icons.height,
                  iconColor: _primaryColor,
                  title: '고도',
                  value: '${_mountainData['altitude']?.toStringAsFixed(1) ?? '0'}m',
                ),
                _buildVerticalDivider(),
                _buildInfoItem(
                  icon: Icons.trending_up,
                  iconColor: _getLevelColor(_mountainData['level'] ?? 'M'),
                  title: '난이도',
                  value: _getLevelText(_mountainData['level'] ?? 'M'),
                ),
                _buildVerticalDivider(),
                _buildInfoItem(
                  icon: Icons.location_on,
                  iconColor: Colors.redAccent,
                  title: '위치',
                  value: _formatLocation(_mountainData['location'] ?? '위치 정보 없음'),
                ),
              ],
            ),
          ),
          
          // 일출/일몰 정보 (있는 경우만)
          if (_mountainData['weather']?['sunrise'] != null &&
              _mountainData['weather']?['sunset'] != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4).withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.yellow.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wb_sunny,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '일출 ${_mountainData['weather']?['sunrise'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.nights_stay,
                    size: 20,
                    color: Color(0xFF5C6BC0),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '일몰 ${_mountainData['weather']?['sunset'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 정보 아이템 위젯
  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 수직 구분선
  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  // 위치 정보 포맷팅
  String _formatLocation(String location) {
    if (location.length > 8) {
      List<String> parts = location.split(' ');
      if (parts.length > 1) {
        return parts.last;
      }
      return location.substring(location.length - 6);
    }
    return location;
  }

  String _formatDuration(String minutesStr) {
    int minutes = int.tryParse(minutesStr) ?? 0;
    
    if (minutes < 60) {
      return '$minutes분';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      
      if (remainingMinutes == 0) {
        return '$hours시간';
      } else {
        return '$hours시간 $remainingMinutes분';
      }
    }
  }

  // 난이도 텍스트 변환
  String _getLevelText(String level) {
    switch (level) {
      case 'H':
        return '어려움';
      case 'M':
        return '보통';
      case 'L':
        return '쉬움';
      default:
        return '보통';
    }
  }
  // 등산로 지도 섹션
  Widget _buildPathMapSection() {
    final List<dynamic> paths = _mountainData['paths'] ?? [];

    if (paths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('등산로', Icons.directions_walk),
        const SizedBox(height: 16),

        // 등산로 탭
        DefaultTabController(
          length: paths.length,
          child: Column(
            children: [
              // 탭 바
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3,
                      color: _primaryColor,
                    ),
                    insets: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  padding: EdgeInsets.zero,
                  tabAlignment: TabAlignment.start,
                  tabs: List.generate(paths.length, (index) {
                    final path = paths[index];
                    return Tab(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 4 : 8,
                          right: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hiking, 
                              size: 16,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(path['pathName'] ?? '등산로'),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
),
              
              const SizedBox(height: 16),
              
              // 탭 콘텐츠
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: paths.map<Widget>((path) {
                    final List<dynamic> route = path['route'] ?? [];
                    final pathName = path['pathName'] ?? '등산로';
                    final pathTime = path['pathTime'] ?? '0';

                    // 경로 좌표 변환
                    final List<NLatLng> routeCoords =
                        route.map<NLatLng>((coord) {
                      return NLatLng(
                        coord['latitude'] ?? 0.0,
                        coord['longitude'] ?? 0.0,
                      );
                    }).toList();

                    return Column(
                      children: [
                        // 등산로 정보 카드
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '소요 시간: 약 ${_formatDuration(pathTime)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 네이버 지도
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: routeCoords.isNotEmpty
                                ? NaverMap(
                                    options: NaverMapViewOptions(
                                      mapType: NMapType.basic,
                                      activeLayerGroups: [
                                        NLayerGroup.mountain,
                                        NLayerGroup.building,
                                        NLayerGroup.transit,
                                      ],
                                    ),
                                    onMapReady: (controller) async {
                                      _mapController = controller;

                                      // 경로 표시
                                      if (routeCoords.length >= 2) {
                                        // 경로 오버레이 추가
                                        controller.addOverlay(
                                          NPathOverlay(
                                            id: 'path-${path['pathId']}',
                                            coords: routeCoords,
                                            color: _primaryColor,
                                            width: 5,
                                            outlineWidth: 1,
                                            outlineColor: Colors.white,
                                            patternInterval: 15,
                                          ),
                                        );

                                        // 시작점 마커 추가
                                        controller.addOverlay(
                                          NMarker(
                                            id: 'start-${path['pathId']}',
                                            position: routeCoords.first,
                                            icon: await NOverlayImage.fromWidget(
                                              widget: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.green,
                                                  size: 18,
                                                ),
                                              ),
                                              size: const Size(32, 32),
                                              context: context,
                                            ),
                                            caption: const NOverlayCaption(
                                              text: '시작',
                                              textSize: 12,
                                              color: Colors.black87,
                                              haloColor: Colors.white,
                                            ),
                                          ),
                                        );

                                        // 도착점 마커 추가
                                        controller.addOverlay(
                                          NMarker(
                                            id: 'end-${path['pathId']}',
                                            position: routeCoords.last,
                                            icon: await NOverlayImage.fromWidget(
                                              widget: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.flag,
                                                  color: Colors.red,
                                                  size: 18,
                                                ),
                                              ),
                                              size: const Size(32, 32),
                                              context: context,
                                            ),
                                            caption: const NOverlayCaption(
                                              text: '도착',
                                              textSize: 12,
                                              color: Colors.black87,
                                              haloColor: Colors.white,
                                            ),
                                          ),
                                        );

                                        // 카메라 이동 - 경로의 경계 구하기
                                        double minLat = double.infinity;
                                        double maxLat = -double.infinity;
                                        double minLng = double.infinity;
                                        double maxLng = -double.infinity;

                                        for (var point in routeCoords) {
                                          minLat =
                                              math.min(minLat, point.latitude);
                                          maxLat =
                                              math.max(maxLat, point.latitude);
                                          minLng =
                                              math.min(minLng, point.longitude);
                                          maxLng =
                                              math.max(maxLng, point.longitude);
                                        }

                                        // 경계를 이용하여 카메라 이동
                                        controller.updateCamera(
                                          NCameraUpdate.fitBounds(
                                            NLatLngBounds(
                                              southWest: NLatLng(minLat, minLng),
                                              northEast: NLatLng(maxLat, maxLng),
                                            ),
                                            padding: const EdgeInsets.all(30),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.landscape,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '등산로 정보가 없습니다',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // 날씨 정보 섹션
  Widget _buildWeatherInfo() {
    final List<dynamic> dailyWeather =
        _mountainData['weather']?['dailyWeather'] ?? [];

    if (dailyWeather.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('날씨 정보', Icons.cloud),
        const SizedBox(height: 16),

        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(2),
            itemCount: dailyWeather.length > 5 ? 5 : dailyWeather.length, // 최대 5일치만 표시
            itemBuilder: (context, index) {
              final weather = dailyWeather[index];
              final date = weather['date'] ?? '';
              final minTemp = weather['temperatureMin']?.toStringAsFixed(1) ?? '-';
              final maxTemp = weather['temperatureMax']?.toStringAsFixed(1) ?? '-';
              final weatherIcon = weather['weather']?['icon'] ?? '01d';

              // 날짜 포맷팅 로직 개선
              String dayText = '오늘';
              if (date.isNotEmpty) {
                try {
                  // API에서 받은 날짜 파싱
                  final dateTime = DateTime.parse(date);
                  
                  // 현재 날짜 (시간 정보 제외)
                  final today = DateTime.now();
                  final todayOnly = DateTime(today.year, today.month, today.day);
                  
                  // 비교할 날짜 (시간 정보 제외)
                  final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
                  
                  // 날짜 차이 계산
                  final differenceInDays = dateOnly.difference(todayOnly).inDays;
                  
                  // 날짜 텍스트 설정
                  if (differenceInDays == 0) {
                    dayText = '오늘';
                  } else if (differenceInDays == 1) {
                    dayText = '내일';
                  } else if (differenceInDays > 1) {
                    // 요일 구하기
                    switch (dateTime.weekday) {
                      case DateTime.monday:
                        dayText = '월';
                        break;
                      case DateTime.tuesday:
                        dayText = '화';
                        break;
                      case DateTime.wednesday:
                        dayText = '수';
                        break;
                      case DateTime.thursday:
                        dayText = '목';
                        break;
                      case DateTime.friday:
                        dayText = '금';
                        break;
                      case DateTime.saturday:
                        dayText = '토';
                        break;
                      case DateTime.sunday:
                        dayText = '일';
                        break;
                    }
                  } else {
                    // 과거 날짜인 경우 (이런 경우는 보통 없지만, 방어 코드)
                    dayText = '이전';
                  }
                } catch (e) {
                  // 날짜 파싱 에러 처리
                  print('날짜 파싱 에러: $e');
                  dayText = '날짜 오류';
                }
              }

              // 날씨 정보 섹션의 카드 내부 컬럼 수정
return Card(
  elevation: 0,
  margin: const EdgeInsets.only(right: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(
      color: Colors.grey.shade200,
      width: 1,
    ),
  ),
  child: Container(
    width: 90,
    padding: const EdgeInsets.all(12),
    // height 추가로 명시적 크기 제한 - 기존 디자인 방해하지 않으면서 overflow 방지
    height: 130, // 기존 SizedBox 높이 140에서 내부 패딩 12*2 감안하여 130으로 설정
    child: Column(
      // mainAxisSize를 min으로 유지하되 mainAxisAlignment를 spaceEvenly로 변경
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: index == 0 ? _primaryColor : Colors.black87,
          ),
        ),
        // SizedBox 높이 약간 조정
        const SizedBox(height: 4),
        Image.network(
          'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
          width: 42,
          height: 42,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.cloud, size: 42);
          },
        ),
        // SizedBox 높이 약간 조정
        const SizedBox(height: 4),
        // 나머지 코드는 그대로 유지
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 최고 온도
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '최고',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$maxTemp°',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 최저 온도
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '최저',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$minTemp°',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ),
);
            },
          ),
        ),
      ],
    );
  }

  // 상세 설명 섹션
  Widget _buildDescriptionSection() {
    final description = _mountainData['description'] ?? '상세 설명이 없습니다.';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // 추가: 필요한 최소 크기만 사용
      children: [
        _buildSectionTitle('상세 설명', Icons.description),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  // 섹션 타이틀 위젯
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 난이도에 따른 색상
  Color _getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color(0xFFE53935); // 빨간색 (어려움)
      case 'M':
        return const Color(0xFFFDD835); // 노란색 (보통)
      case 'L':
        return const Color(0xFF43A047); // 초록색 (쉬움)
      default:
        return const Color(0xFF1E88E5); // 파란색 (기본)
    }
  }

  // 이미지 URL 안전 처리 함수
  String getImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }
}