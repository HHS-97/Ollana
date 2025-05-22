import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../screens/user/login_screen.dart';
import '../screens/home_screen.dart';
import '../../models/app_state.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final String _title = 'ollana';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogout() async {
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final appState = context.read<AppState>();
    final token = appState.accessToken;
    final baseUrl = dotenv.get('BASE_URL');

    final confirm = await showDialog<bool>(
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
                  color: const Color(0xFF52A486).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF52A486),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '정말 로그아웃 하시나요?',
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
                      onPressed: () => Navigator.of(ctx).pop(false),
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
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF52A486),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '로그아웃',
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

    if (confirm != true || !mounted) return;

    final res = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );
    if (!mounted) return;

    if (res.statusCode == 403) {
      appState.clearAuth();
      appState.changePage(0);
      scaffold.showSnackBar(
          const SnackBar(content: Text('세션이 만료되었습니다. 다시 로그인해주세요.')));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    if (res.statusCode == 200) {
      bool success = false;
      try {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        success = result['status'] == true;
      } catch (_) {
        success = true;
      }
      if (success) {
        appState.clearAuth();
        appState.changePage(0);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final msg = (jsonDecode(res.body) as Map<String, dynamic>)['message'] ??
            '로그아웃 실패';
        scaffold.showSnackBar(SnackBar(content: Text(msg)));
      }
    } else {
      scaffold
          .showSnackBar(SnackBar(content: Text('서버 에러: ${res.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AppState>().isLoggedIn;
    final appState = Provider.of<AppState>(context, listen: false);

    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: false, // 타이틀을 중앙에서 왼쪽으로 변경
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0, // 타이틀의 왼쪽 여백 제거
      title: GestureDetector(
        onTap: () {
          // 현재 페이지가 홈(0)이 아닌 경우에만 홈으로 이동
          if (appState.currentPageIndex != 0) {
            appState.changePage(0); // AppState의 currentPageIndex를 0(홈)으로 변경
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false, // 모든 경로를 제거하고 새 경로만 유지
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0), // 왼쪽에 약간의 패딩 추가
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ollana',
              style: TextStyle(
                fontFamily: 'EVE',
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: Color(0xFF52A486),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isLoggedIn) // 로그인 상태일 때만 버튼 표시
          TextButton(
            onPressed: _handleLogout, // 로그인 상태일 때는 항상 로그아웃 기능만 필요
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              textStyle: const TextStyle(
                fontFamily: 'GmarketSans',
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('로그아웃'),
          ),
        // 비로그인 상태일 때는 아무것도 표시하지 않음
      ],
    );
  }
}