import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/my_footprint_service.dart';
import '../../models/app_state.dart';
import 'footprint_battle_screen.dart';
import '../../models/footprint_mountain.dart';
import 'footprint_detail_screen.dart';
import 'dart:ui';

class MyFootprintScreen extends StatefulWidget {
  const MyFootprintScreen({super.key});

  @override
  State<MyFootprintScreen> createState() => _MyFootprintScreenState();
}

class _MyFootprintScreenState extends State<MyFootprintScreen> {
  List<footprintMountain> footprints = [];
  bool isLoading = true;

  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasNextPage = true;
  double totalDistance = 0;
  int totalElements = 0;

  @override
  void initState() {
    super.initState();

    // 첫 데이터 로딩
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
      _fetchFootprints(token);
    });
  }

  Future<void> _fetchFootprints(String token) async {
    if (_isFetching || !_hasNextPage) {
      debugPrint('[발자취] 현재 데이터 요청 중이거나 더 이상 페이지가 없음');
      return;
    }

    debugPrint('[발자취] 데이터 요청 시작: 페이지 $_currentPage');
    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      final newResponse = await service.getFootprints(token, page: _currentPage);

      debugPrint('[발자취] currentPage: ${newResponse.currentPage}, last: ${newResponse.last}, mountains 개수: ${newResponse.mountains.length}');

      if (mounted) {
        setState(() {
          if (_currentPage == 0) {
            footprints = newResponse.mountains;
            totalDistance = newResponse.totalDistance;
            totalElements = newResponse.totalElements;
          } else {
            footprints.addAll(newResponse.mountains);
            totalDistance = newResponse.totalDistance;
            totalElements = newResponse.totalElements;
          }

          _hasNextPage = !newResponse.last;
          _currentPage++;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[발자취] 목록 로딩 중 에러 발생: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  void _loadMoreData() {
    debugPrint('[발자취] 추가 데이터 로드 요청');
    final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
    _fetchFootprints(token);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final profileImageUrl = appState.profileImageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white, // Fixed background color
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent elevation change on scroll
        title: const Text(
          '나의 발자취',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF52A486),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 상단 요약 카드
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          profileImageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('[발자취] 프로필 이미지 로드 에러: $error');
                                            return const Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Color(0xFF52A486),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                color: Color(0xFF52A486),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Color(0xFF52A486),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '총 등산 거리',  // 항상 '총 등산 거리'를 표시
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(  // 항상 Row를 표시
                                    children: [
                                      Text(
                                        footprints.isEmpty 
                                            ? '0'  // 비어있으면 '0'
                                            : (totalDistance >= 1000
                                                ? (totalDistance / 1000).toStringAsFixed(1)
                                                : totalDistance.toStringAsFixed(0)),
                                        style: const TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF52A486),
                                        ),
                                      ),
                                      Text(
                                        footprints.isEmpty
                                            ? ' m'  // 비어있으면 무조건 'm'
                                            : (totalDistance >= 1000 ? ' km' : ' m'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF52A486),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (footprints.isNotEmpty) const SizedBox(height: 16),
                          // 대결 결과 버튼
                          if (footprints.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FootprintBattleScreen(token: token),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF52A486),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '대결 결과 보기',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 발자취 목록 타이틀
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '내가 등산한 산',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$totalElements개',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 그리드 부분
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (!_isFetching &&
                            _hasNextPage &&
                            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                          _loadMoreData();
                        }
                        return false;
                      },
                      child: footprints.isEmpty
                          ? _buildEmptyState()
                          : CustomScrollView(
                              slivers: [
                                SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.85,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = footprints[index];
                                      return _buildFootprintCard(context, item);
                                    },
                                    childCount: footprints.length,
                                  ),
                                ),
                                // 하단에 로딩 표시기 추가
                                SliverToBoxAdapter(
                                  child: _isFetching
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.0),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF52A486),
                                              strokeWidth: 3,
                                            ),
                                          ),
                                        )
                                      : !_hasNextPage && footprints.isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                                              child: Center(
                                              ),
                                            )
                                          : const SizedBox.shrink(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hiking,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 등산 기록이 없어요',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 등산을 기록하고 발자취를 남겨볼까요?',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootprintCard(BuildContext context, footprintMountain item) {
    return InkWell(
      onTap: () async {
        try {
          final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
          final service = MyFootprintService();
          await service.getFootprintDetail(token, item.footprintId);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FootprintDetailScreen(
                footprintId: item.footprintId,
                token: token,
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('상세 정보를 불러오는 데 실패했습니다'),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.imgUrl.isNotEmpty
                        ? Image.network(
                            item.imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2.0,
                                  color: const Color(0xFF52A486),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.landscape,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                    // 산 이름
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Stroke (outline) text
                          Text(
                            item.mountainName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Main text
                          Text(
                            item.mountainName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
            // 상세 정보 영역
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 거리 표시 or 다른 정보를 여기에 추가할 수 있습니다
                  const Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye,
                        size: 16,
                        color: Color(0xFF52A486),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '성장 그래프 보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF52A486),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}