// lib/screens/user/password_reset_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  bool _isSuccessful = false;

  Future<void> _requestTempPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = '유효한 이메일을 입력해 주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/password/reset');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['status'] == true) {
        setState(() {
          _isSuccessful = true;
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        setState(() => _errorMsg = data['message'] ?? '발송에 실패했습니다.');
      }
    } catch (e) {
      setState(() => _errorMsg = '네트워크 오류가 발생했습니다.');
    } finally {
      if (!_isSuccessful) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          '비밀번호 찾기',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isSuccessful 
                ? _buildSuccessMessage() 
                : _buildResetForm(primary),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Color(0xFF52A486),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '임시 비밀번호가 발송되었습니다',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '이메일을 확인해주세요.\n로그인 후 비밀번호를 변경해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(Color primary) {
    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      errorStyle: const TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w500,
      ),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF52A486),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 비밀번호 찾기 아이콘
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 50,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // 안내 텍스트
        Text(
          '비밀번호를 잊으셨나요?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '가입하신 이메일을 입력하시면\n임시 비밀번호를 보내드릴게요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // 에러 메시지
        if (_errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // 이메일 입력 필드
        TextFormField(
          controller: _emailController,
          decoration: inputDecoration.copyWith(
            hintText: '이메일 주소',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: Colors.grey.shade600,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        
        // 임시 비밀번호 발급 버튼
        ElevatedButton(
          onPressed: _isLoading ? null : _requestTempPassword,
          style: buttonStyle,
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
                  '임시 비밀번호 발급',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}