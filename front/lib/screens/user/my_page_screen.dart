import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/user.dart';
import '../../services/my_page_service.dart';
import 'edit_profile_screen.dart';
import 'password_change_screen.dart';
import '../user/login_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future userFuture;
  bool? _isAgree;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final userService = MyPageService();
    userFuture = userService.fetchUserDetails(appState.accessToken ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final userService = MyPageService();
    final newFuture = userService.fetchUserDetails(appState.accessToken ?? '');
    if (userFuture != newFuture) {
      setState(() {
        userFuture = newFuture;
        _isAgree = null;
      });
    }
  }

  Future _handleWithdraw() async {
    final appState = context.read<AppState>();
    final userService = MyPageService();
    final social = appState.social ?? false;

    if (!social) {
      final passwordController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '회원 탈퇴하기',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '정말로 탈퇴하시겠습니까? 계정 확인을 위해 비밀번호를 입력해주세요.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  //labelText: '비밀번호',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF52A486), width: 2.0),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF52A486)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF52A486),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('탈퇴하기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result != true) return;

      try {
        await userService.withdrawUser(
          appState.accessToken ?? '',
          social,
          password: passwordController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원 탈퇴가 완료되었습니다.'),
            backgroundColor: Color(0xFF52A486),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('탈퇴 실패: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '정말로 회원 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('탈퇴하기', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await userService.withdrawUser(
          appState.accessToken ?? '',
          social,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원 탈퇴가 완료되었습니다.'),
            backgroundColor: Color(0xFF52A486),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('탈퇴 실패: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
    }

    await appState.clearAuth();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // 고정된 배경색
        scrolledUnderElevation: 0, // 스크롤 시 엘리베이션 변화 방지
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF52A486)),
      ),
      body: FutureBuilder(
        future: userFuture,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _isAgree == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52A486)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No user data available',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data as User;
          _isAgree ??= user.agree;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 프로필 섹션
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 16, bottom: 16),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF52A486),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                user.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'lib/assets/images/alps.jpg',
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: -4,
                            child: GestureDetector(
                              onTap: () async {
                                final updatedUser = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      nickname: user.nickname,
                                      imageUrl: user.imageUrl,
                                    ),
                                  ),
                                );
                                if (updatedUser != null) {
                                  setState(() {
                                    userFuture = Future.value(updatedUser);
                                    _isAgree = updatedUser.agree;
                                  });
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF52A486),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 설정 섹션
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                      ),
                      
                      // 등산기록 제공 동의 카드
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF52A486).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.hiking,
                                            color: Color(0xFF52A486),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          '등산기록 제공 동의',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ],
                                    ),                                    
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isAgree!,
                                onChanged: (value) async {
                                  setState(() {
                                    _isAgree = value;
                                  });

                                  final appState = context.read<AppState>();
                                  final userService = MyPageService();

                                  try {
                                    final updatedUser = await userService.updateUserAgreement(
                                      appState.accessToken ?? '',
                                      value,
                                    );
                                    setState(() {
                                      userFuture = Future.value(updatedUser);
                                      _isAgree = updatedUser.agree;
                                    });
                                  } catch (e) {
                                    setState(() {
                                      _isAgree = user.agree;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('설정 변경 실패: $e'),
                                        backgroundColor: Colors.red.shade400,
                                      ),
                                    );
                                  }
                                },
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF52A486),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 비밀번호 변경 버튼
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PasswordChangeScreen(
                                  accessToken: context.read<AppState>().accessToken ?? '',
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF52A486).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF52A486),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '비밀번호 변경하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 회원 탈퇴 버튼
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: InkWell(
                          onTap: _handleWithdraw,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF52A486).withOpacity(0.1), // 빨간색에서 초록색으로 변경
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.exit_to_app, 
                                    color: Color(0xFF52A486), // 빨간색에서 초록색으로 변경
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '회원 탈퇴하기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333), // 빨간색에서 검은색으로 변경
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey, // 빨간색에서 회색으로 변경
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}