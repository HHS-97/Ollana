import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';

class PasswordChangeScreen extends StatefulWidget {
  /// 로그인 후 임시 비밀번호 사용자일 때 API 호출을 위해 토큰을 넘겨받습니다.
  final String accessToken;
  const PasswordChangeScreen({
    Key? key,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordValid = false;

  void _validatePassword() {
    final newPassword = _newPwdCtrl.text.trim();
    final confirmPassword = _confirmPwdCtrl.text.trim();
    
    setState(() {
      if (newPassword.isEmpty || newPassword.length < 6) {
        _errorMsg = '비밀번호는 최소 6자 이상이어야 합니다';
        _isPasswordValid = false;
      } else if (confirmPassword.isNotEmpty && newPassword != confirmPassword) {
        _errorMsg = '비밀번호가 일치하지 않습니다';
        _isPasswordValid = false;
      } else if (confirmPassword.isNotEmpty && newPassword == confirmPassword) {
        _errorMsg = null;
        _isPasswordValid = true;
      } else {
        _errorMsg = null;
        _isPasswordValid = false;
      }
    });
  }

  Future<void> _changePassword() async {
    final newPassword = _newPwdCtrl.text.trim();
    final confirmPassword = _confirmPwdCtrl.text.trim();
    
    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _errorMsg = '비밀번호는 최소 6자 이상이어야 합니다');
      return;
    }
    
    if (newPassword != confirmPassword) {
      setState(() => _errorMsg = '비밀번호가 일치하지 않습니다');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final token = context.read<AppState>().accessToken;
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/password/change');
    try {
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'newPassword': newPassword}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == true) {
        // 성공 시 애니메이션 효과와 함께 성공 메시지 표시
        _showSuccessDialog();
      } else {
        setState(() => _errorMsg = data['message'] ?? '비밀번호 변경에 실패했습니다.');
      }
    } catch (e) {
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF52A486),
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                '비밀번호 변경 완료',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '비밀번호가 성공적으로 변경되었습니다.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  Navigator.of(context).pop(); // 비밀번호 변경 화면 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52A486),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _newPwdCtrl.addListener(_validatePassword);
    _confirmPwdCtrl.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF52A486);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          '비밀번호 변경',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.05),
                // 상단 안내 아이콘
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 안내 텍스트
                const Text(
                  '새로운 비밀번호를 설정해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '안전한 보호를 위해\n6자 이상의 비밀번호를 입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                // 에러 메시지
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // 새 비밀번호 입력 필드
                TextField(
                  controller: _newPwdCtrl,
                  decoration: InputDecoration(
                    labelText: '새 비밀번호',
                    hintText: '6자 이상 입력',
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    floatingLabelStyle: TextStyle(color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  obscureText: _obscureNewPassword,
                ),
                const SizedBox(height: 20),
                // 비밀번호 확인 필드
                TextField(
                  controller: _confirmPwdCtrl,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력해주세요',
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    floatingLabelStyle: TextStyle(color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
                const SizedBox(height: 40),
                // 비밀번호 변경 버튼
                ElevatedButton(
                  onPressed: (_isPasswordValid && !_isLoading) ? _changePassword : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withOpacity(0.3),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '비밀번호 변경하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}