// lib/widgets/custom_footer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_state.dart';
import '../services/mountain_service.dart';
import '../../screens/user/login_screen.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 60 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterButton(context, 0, Icons.home),
              _buildFooterButton(context, 1, Icons.directions_walk),
              _buildFooterButton(context, 2, Icons.area_chart_rounded),
              _buildFooterButton(context, 3, FontAwesomeIcons.shoePrints),
              _buildFooterButton(context, 4, Icons.person),
            ],
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  // 위치 권한 확인 및 요청
  Future<bool> _handleLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.'),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.'),
        ),
      );
      return false;
    }

    return true;
  }

  // 현재 위치 가져오기
  Future<Position?> _getCurrentPosition(BuildContext context) async {
    final hasPermission = await _handleLocationPermission(context);
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다: \$e')));
      return null;
    }
  }

  Widget _buildFooterButton(
    BuildContext context,
    int index,
    IconData icon,
  ) {
    final appState = context.watch<AppState>();
    final isSelected = appState.currentPageIndex == index;

    Widget iconWidget = icon == FontAwesomeIcons.shoePrints
        ? Transform.rotate(
            angle: -1.7,
            child: Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 24.0,
            ),
          )
        : Icon(
            icon,
            color: isSelected ? Colors.green : Colors.grey,
            size: 34.0,
          );

    return GestureDetector(
      onTap: () async {
        // 🔥 로그아웃 상태에서 0이 아닌 탭 선택 시 모달 안내
        // 로그아웃 상태에서 홈(0) 또는 지도(2) 탭만 허용, 그 외에는 안내 모달
        if (!appState.isLoggedIn && index != 0 && index != 2) {
          await showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF52A486).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF52A486),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '로그인이 필요합니다',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '이 기능을 사용하기 위해서는\n로그인이 필요해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF52A486),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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
          return;
        }

        // 🔥 트래킹 탭(1) 선택 시
        if (index == 1) {
          // 이미 트래킹 중이면 바로 변경
          if (appState.isTracking ||
              appState.trackingStage == TrackingStage.tracking) {
            appState.changePage(index);
            return;
          }
          // 페이지 변경 후 백그라운드 데이터 로딩
          appState.changePage(index);
          _loadMountainDataInBackground(context, appState);
        } else {
          appState.changePage(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [iconWidget],
      ),
    );
  }

  // 🔥 백그라운드에서 산 데이터 로딩
  void _loadMountainDataInBackground(
      BuildContext context, AppState appState) async {
    try {
      final position = await _getCurrentPosition(context);
      final mountainService = MountainService();
      late final double lat;
      late final double lon;

      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
      } else {
        // 위치 실패 시 서울 중심 좌표
        lat = 37.5665;
        lon = 126.9780;
      }

      final data = await mountainService.getNearbyMountains(lat, lon);
      if (!context.mounted) return;

      final mountain = data.mountain;
      final routes = data.routes;
      if (routes.isNotEmpty) {
        appState.selectMountain(mountain.name);
        appState.preSelectRoute(routes[0]);
      }
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('[loadMountainData] Exception: $e');
    }
  }
}
