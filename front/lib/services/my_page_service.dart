import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import 'package:http_parser/http_parser.dart';

class MyPageService {
  final String baseUrl = dotenv.get('BASE_URL');

  Future fetchUserDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/mypage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
    );
    if (response.statusCode == 200) {
      final jsonString = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(jsonString);
      if (jsonData['status'] == true) {
        return User.fromJson(jsonData['data']);
      } else {
        throw Exception('API returned status false');
      }
    } else {
      throw Exception('Failed to load user details: ${response.statusCode}');
    }
  }

  Future<User> updateUserProfile(String token, String nickname, XFile? profileImage) async {
    try {
      final uri = Uri.parse('$baseUrl/user/mypage');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json; charset=utf-8';

      final userData = jsonEncode({"nickname": nickname});
      request.files.add(http.MultipartFile.fromString(
        'userData',
        userData,
        contentType: MediaType('application', 'json'),
      ));

      if (profileImage != null) {
        final file = await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(file);
      }

      debugPrint('=============== REQUEST DETAILS ===============');
      debugPrint('URL: $uri');
      debugPrint('Method: PATCH');
      debugPrint('Headers: ${request.headers}');
      for (var field in request.fields.entries) {
        debugPrint('Field: ${field.key} = ${field.value}');
      }
      for (var file in request.files) {
        debugPrint('File: ${file.field} = ${file.filename} (${file.length} bytes)');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('=============== RESPONSE DETAILS ===============');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Raw Body Bytes: ${response.bodyBytes}');
      debugPrint('Raw Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonString = utf8.decode(response.bodyBytes, allowMalformed: true);
        debugPrint('UTF-8 Decoded Body: $jsonString');
        final jsonData = jsonDecode(jsonString);
        debugPrint('API Message: ${jsonData['message']}');
        debugPrint('Nickname: ${jsonData['data']?['nickname']}');
        if (jsonData['status'] == true) {
          return User.fromJson(jsonData['data']);
        } else {
          throw Exception('API failed: ${jsonData['message']} (code: ${jsonData['code']})');
        }
      } else {
        final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        debugPrint('Error Body (UTF-8 Decoded): $decodedBody');
        throw Exception(decodedBody);
      }
    } catch (e) {
      debugPrint('========= ERROR =========');
      debugPrint('$e');
      rethrow;
    }
  }

  Future<User> updateUserAgreement(String token, bool isAgree) async {
    try {
      final uri = Uri.parse('$baseUrl/user/mypage');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json; charset=utf-8';

      final userData = jsonEncode({"isAgree": isAgree});
      request.files.add(http.MultipartFile.fromString(
        'userData',
        userData,
        contentType: MediaType('application', 'json'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('=============== AGREEMENT UPDATE RESPONSE ===============');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Body Bytes: ${response.bodyBytes}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonString = utf8.decode(response.bodyBytes);
        debugPrint('UTF-8 Decoded Body: $jsonString');
        final jsonData = jsonDecode(jsonString);
        if (jsonData['status'] == true) {
          return User.fromJson(jsonData['data']);
        } else {
          throw Exception('API failed: ${jsonData['message']} (code: ${jsonData['code']})');
        }
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        debugPrint('Error Body (UTF-8 Decoded): $decodedBody');
        throw Exception(decodedBody);
      }
    } catch (e) {
      debugPrint('========= AGREEMENT UPDATE ERROR =========');
      debugPrint('$e');
      rethrow;
    }
  }

  Future withdrawUser(String token, bool social, {String? password}) async {
    try {
      final uri = Uri.parse('$baseUrl/user/withdraw');
      final body = social ? {} : {'password': password};

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('=============== WITHDRAW REQUEST DETAILS ===============');
      debugPrint('URL: $uri');
      debugPrint('Method: DELETE');
      debugPrint('Headers: {Authorization: Bearer $token, Content-Type: application/json}');
      debugPrint('Body: $body');
      debugPrint('=============== WITHDRAW RESPONSE DETAILS ===============');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          return;
        } else {
          throw Exception('API failed: ${jsonData['message']} (code: ${jsonData['code']})');
        }
      } else {
        final decodedBody = utf8.decode(response.bodyBytes);
        throw Exception(decodedBody);
      }
    } catch (e) {
      debugPrint('========= WITHDRAW ERROR =========');
      debugPrint('$e');
      rethrow;
    }
  }
}