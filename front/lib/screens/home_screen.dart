// home_screen.dart: 앱의 메인 화면 구성 및 레이아웃 정의
// - HomeScreen: 앱 바, 바텀 내비게이션 바, 메인 콘텐츠 영역 구성
// - 트래킹 중에도 다른 탭으로 이동 가능하도록 설정
// - 트래킹 중일 때는 플로팅 상태 표시 위젯 추가

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';
import '../widgets/home_body.dart';
import './tracking/tracking_screen.dart';
import './footprint/my_footprint_screen.dart';
import './user/my_page_screen.dart';
import './mountain/mountain_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: const CustomAppBar(),
          body: Stack(
            children: [
              // 현재 선택된 탭에 따라 화면 표시
              Builder(builder: (context) {
                switch (appState.currentPageIndex) {
                  case 0:
                    return HomeBody();
                  case 1:
                    return const TrackingScreen();
                  case 2:
                    return const MountainMapScreen();
                  case 3:
                    return const MyFootprintScreen();
                  case 4:
                    return MyPageScreen();
                  default:
                    return HomeBody();
                }
              }),

              // 트래킹 중일 때 표시되는 플로팅 위젯 (1번 탭이 아닐 때만 표시)
              if (appState.isTracking &&
                  appState.trackingStage == TrackingStage.tracking &&
                  appState.currentPageIndex != 1)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildTrackingStatusButton(context, appState),
                ),
            ],
          ),
          bottomNavigationBar: const CustomFooter(),
        );
      },
    );
  }

  // 트래킹 상태를 보여주는 플로팅 버튼
  Widget _buildTrackingStatusButton(BuildContext context, AppState appState) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 트래킹 탭으로 이동
          appState.changePage(1);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_walk,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${appState.selectedMode} 등산 중',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
