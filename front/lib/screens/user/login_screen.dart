// lib/screens/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../../services/kakao_auth_service.dart';
import '../../models/app_state.dart';
import './sign_up_screen.dart';
import './password_reset_screen.dart';
import './password_change_screen.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  bool _isPasswordVisible = false;

  // 테마 색상
  final Color _primaryColor = const Color(0xFF52A486);
  final Color _secondaryColor = const Color(0xFF3D7A64);
  final Color _backgroundColor = const Color(0xFFF9F9F9);
  final Color _textColor = const Color(0xFF333333);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('🔄 [Login] 시작');
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [Login] 유효성 검사 실패');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final baseUrl = dotenv.get('BASE_URL');
      final uri = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      final bodyString = utf8.decode(response.bodyBytes);
      final data = jsonDecode(bodyString);

      if (response.statusCode == 200 && data['status'] == true) {
        final accessToken = data['data']['accessToken'];
        final profileImageUrl = data['data']['user']['profileImageUrl'];
        final nickname = data['data']['user']['nickname'];
        final social = data['data']['user']['social'] as bool;
        final payloadA = Jwt.parseJwt(accessToken);
        final userId = payloadA['userId']?.toString() ?? '';
        final expA = payloadA['exp'] as int;
        final expiryA = DateTime.fromMillisecondsSinceEpoch(expA * 1000);
        
        await context.read<AppState>().setToken(
              accessToken,
              userId: userId,
              profileImageUrl: profileImageUrl,
              nickname: nickname,
              social: social,
            );

        // 임시 비밀번호 검사
        final user = data['data']['user'];
        final isTemp = (user['tempPassword'] as bool?) ?? false;
        if (isTemp) {
          final shouldChange = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                '임시 비밀번호 안내',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              content: Text(
                '현재 임시비밀번호 발급을 받으셨습니다.\n비밀번호 변경 페이지로 이동하시겠습니까?',
                style: TextStyle(color: _textColor.withOpacity(0.8)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          );

          if (shouldChange == true) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PasswordChangeScreen(
                  accessToken: accessToken,
                ),
              ),
            );
          }
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _errorMsg = data['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('❌ [Login] 오류 발생: $e');
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, String? hintText, IconData? icon) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: _primaryColor.withOpacity(0.7)) : null,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '로그인',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 이미지/로고 영역
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 로고 또는 이미지
                    Container(
                      width: 120, // 로고 크기에 맞게 조정하세요
                      height: 120, // 로고 크기에 맞게 조정하세요
                      child: Image.asset(
                        'lib/assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ollana에 오신 것을 환영합니다',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '로그인해서 다양한 서비스를 이용해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 로그인 폼
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 에러 메시지
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // 이메일 입력..
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration(
                          '이메일',
                          'example@email.com',
                          Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                        ),
                        validator: (v) => (v?.contains('@') ?? false)
                            ? null
                            : '유효한 이메일을 입력해 주세요.',
                      ),
                      const SizedBox(height: 16),
                      
                      // 비밀번호 입력
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration(
                          '비밀번호',
                          '6자 이상 입력해주세요',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                        ),
                        validator: (v) => (v != null && v.length >= 6)
                            ? null
                            : '6자 이상 비밀번호를 입력해 주세요.',
                      ),
                      const SizedBox(height: 8),
                      
                      // 회원가입 및 비밀번호 찾기 링크
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 회원가입 링크
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 14,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // 비밀번호 찾기 링크
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PasswordResetScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                fontSize: 14,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 로그인 버튼
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(56),
                          disabledBackgroundColor: _primaryColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 카카오 로그인 버튼
                      ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                  _errorMsg = null;
                                });
                                try {
                                  final kakaoService = KakaoAuthService();
                                  await kakaoService.loginWithKakao(context);
                                } catch (e) {
                                  setState(() {
                                    _errorMsg = '카카오 로그인 중 오류가 발생했습니다.';
                                  });
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              },
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text(
                          '카카오톡으로 시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE500),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(56),
                          disabledBackgroundColor: const Color(0xFFFEE500).withOpacity(0.7),
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
    );
  }
}