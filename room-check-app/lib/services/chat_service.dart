import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  Future<String> getAiResponse({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
  }) async {
    try {
      // 1. .env 파일에서 백엔드 기본 URL을 불러옴
      final String? backendUrl = dotenv.env['BACKEND_API_URL'];

      // URL이 .env에 설정되지 않은 경우 에러 처리
      if (backendUrl == null || backendUrl.isEmpty) {
        throw Exception('BACKEND_API_URL이 .env 파일에 설정되지 않았습니다.');
      }

      // 2. 전체 API 엔드포인트 주소 조합
      final apiUrl = '$backendUrl/api/chat';

      // 3. 백엔드에 보낼 대화 기록 포맷 가공
      List<Map<String, String>> historyForBackend = conversationHistory
          .map((msg) => {
                'role':
                    msg.user.id == '1' ? 'user' : 'assistant', // '1'은 사용자 ID
                'content': msg.text,
              })
          .toList();

      // 4. HTTP POST 요청
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'userMessage': userMessage,
          'conversationHistory': historyForBackend,
        }),
      );

      // 5. 응답 처리
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          return data['message'];
        } else {
          throw Exception('AI 응답 실패: ${data['message']}');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('ChatService 오류: $e');
      throw Exception('AI와 통신 중 오류가 발생했습니다.');
    }
  }
}
