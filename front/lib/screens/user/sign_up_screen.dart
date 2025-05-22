// lib/screens/sign_up_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_state.dart';
import 'package:http_parser/http_parser.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _gender = 'M';
  File? _profileImage;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _emailSent = false;
  bool _emailVerified = false;
  String? _errorMsg;
  String? _verifyError;
  final _picker = ImagePicker();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _passwordsMatch =>
      _passwordCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nickCtrl.dispose();
    _birthCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = '유효한 이메일을 입력해 주세요.');
      return;
    }
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/email/send');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            _emailSent = true;
            _verifyError = null;
          });
        } else {
          setState(() => _errorMsg = data['message'] ?? '인증 코드 전송 실패');
        }
      } else {
        setState(() => _errorMsg = '서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = '네트워크 오류 발생');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _verifyError = '인증 코드를 입력해 주세요.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _verifyError = null;
    });
    final uri = Uri.parse('${dotenv.get('BASE_URL')}/auth/email/verify');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          setState(() {
            _emailVerified = true;
          });
        } else {
          setState(() => _verifyError = data['message'] ?? '인증 코드 확인 실패');
        }
      } else {
        setState(() => _verifyError = '서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _verifyError = '네트워크 오류 발생');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_emailVerified) {
      if (!_emailVerified) {
        setState(() => _errorMsg = '이메일 인증을 완료해 주세요.');
      }
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final baseUrl = dotenv.get('BASE_URL');
    final uri = Uri.parse('$baseUrl/auth/signup');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(
      http.MultipartFile.fromString(
        'userData',
        jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
          'nickname': _nickCtrl.text.trim(),
          'birth': _birthCtrl.text.trim(),
          'gender': _gender,
        }),
        contentType: MediaType('application', 'json'),
      ),
    );
    if (_profileImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          _profileImage!.path,
          contentType: MediaType('image', _profileImage!.path.split('.').last),
        ),
      );
    }
    try {
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      final bodyString = utf8.decode(resp.bodyBytes);
      final data = jsonDecode(bodyString);
      if (!mounted) return;
      if (resp.statusCode == 200 && data['status'] == true) {
        context.read<AppState>().toggleLogin();
        Navigator.of(context).pop();
      } else {
        final msg = data['message'] ?? '회원가입에 실패했습니다.';
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('회원가입 실패'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('네트워크 오류가 발생했습니다.\n${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    
    final textTheme = Theme.of(context).textTheme;

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
        height: 0.8,
      ),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, // 배경색을 흰색으로 고정
        surfaceTintColor: Colors.white, // 스크롤 시 색상 변화 방지
        centerTitle: true,
        elevation: 0,
        title: Text(
          '회원가입',
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
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile image section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profileImage == null
                                ? Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 36,
                                    color: Colors.grey.shade500,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '프로필 사진',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Error message
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
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade400, size: 20),
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

                      // Email section with verification
                      _buildSectionTitle('이메일'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: inputDecoration.copyWith(
                          hintText: 'example@email.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: _emailVerified
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF52A486),
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_emailVerified,
                        validator: (v) =>
                            v != null && v.contains('@') ? null : '유효한 이메일을 입력해 주세요.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (!_emailVerified)
                        ElevatedButton(
                          onPressed: (_isSending || _emailSent) ? null : _sendVerificationCode,
                          style: buttonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey.shade300;
                              }
                              return Color(0xFF52A486);
                            }),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          child: _isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: onPrimary,
                                  ),
                                )
                              : Text(
                                  _emailSent ? '인증 코드 재전송' : '인증 코드 전송',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      
                      // Verification code section
                      if (_emailSent && !_emailVerified) ...[
                        const SizedBox(height: 24),
                        _buildSectionTitle('인증'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeCtrl,
                                decoration: inputDecoration.copyWith(
                                  hintText: '인증 코드',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _isVerifying ? null : _verifyCode,
                                style: buttonStyle.copyWith(
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                    if (states.contains(MaterialState.disabled)) {
                                      return Colors.grey.shade300;
                                    }
                                    return Color(0xFF52A486);
                                  }),
                                  padding: MaterialStateProperty.all(
                                    const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                                child: _isVerifying
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: onPrimary,
                                        ),
                                      )
                                    : const Text(
                                        '확인',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (_verifyError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 8),
                            child: Text(
                              _verifyError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 24),
                      _buildSectionTitle('비밀번호'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordCtrl,
                        decoration: inputDecoration.copyWith(
                          hintText: '8자 이상 특수문자 포함',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v != null &&
                                v.length >= 8 &&
                                RegExp(r'[^A-Za-z0-9]').hasMatch(v))
                            ? null
                            : '8자 이상 특수문자 포함 비밀번호를 입력해 주세요.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmCtrl,
                        decoration: inputDecoration.copyWith(
                          hintText: '비밀번호 확인',
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                          if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (_confirmCtrl.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: Row(
                            children: [
                              Icon(
                                _passwordsMatch ? Icons.check : Icons.error_outline,
                                size: 14,
                                color: _passwordsMatch ? Color(0xFF52A486) : Colors.red.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _passwordsMatch ? '비밀번호가 일치합니다.' : '비밀번호가 일치하지 않습니다.',
                                style: TextStyle(
                                  color: _passwordsMatch ? Color(0xFF52A486) : Colors.red.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('계정 정보'),
                      const SizedBox(height: 8),
                      
                      // Nickname field
                      TextFormField(
                        controller: _nickCtrl,
                        decoration: inputDecoration.copyWith(
                          hintText: '닉네임',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[가-힣a-zA-Z0-9]'))
                        ],
                        validator: (v) => (v != null && v.trim().isNotEmpty)
                            ? null
                            : '닉네임을 입력해 주세요.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Birth field
                      TextFormField(
                        controller: _birthCtrl,
                        decoration: inputDecoration.copyWith(
                          hintText: '생년월일 8자리 (YYYYMMDD)',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        validator: (v) => v != null && RegExp(r'^\d{8}$').hasMatch(v)
                            ? null
                            : '생년월일 8자리 숫자로 입력해 주세요.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Gender field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _gender = 'M'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _gender == 'M' ? Color(0xFF52A486) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '남성',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _gender == 'M'
                                            ? onPrimary
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _gender = 'F'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _gender == 'F' ? Color(0xFF52A486) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '여성',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _gender == 'F'
                                            ? onPrimary
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            
            // Sign up button at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: buttonStyle.copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey.shade400;
                      }
                      return Color(0xFF52A486);
                    }),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: onPrimary,
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}