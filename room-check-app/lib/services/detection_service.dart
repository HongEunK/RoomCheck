import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<dynamic>> uploadImageToServer(
  File imageFile,
  BuildContext context,
) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final String? backendUrl = dotenv.env['BACKEND_API_URL'];

    if (backendUrl == null || backendUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('서버 주소를 찾을 수 없습니다.')));
      }
      return [];
    }

    final serverUrl = '$backendUrl/api/upload';

    final response = await http
        .post(
          Uri.parse(serverUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': base64Image}),
        )
        .timeout(const Duration(seconds: 20)); // 20초 이상 응답 없으면 실패 처리

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      print("   - 서버 응답 내용: $jsonResponse");
      return jsonResponse['detections'] ?? [];
    } else {
      return [];
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('이미지 업로드 실패: $e')));
    }
    return [];
  }
}
