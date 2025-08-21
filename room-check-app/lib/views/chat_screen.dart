import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  // home_screen에서 전달받을 첫 AI 분석 메시지
  final String initialAnalysis;

  const ChatScreen({super.key, required this.initialAnalysis});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 채팅 서비스 인스턴스
  final ChatService _chatService = ChatService();

  // 채팅 메시지들을 관리하는 리스트
  final List<ChatMessage> _messages = [];

  // 사용자(나)와 AI(챗봇) 객체 정의
  final ChatUser _currentUser = ChatUser(id: '1', firstName: '나');
  final ChatUser _aiUser = ChatUser(id: '2', firstName: 'AI');

  // 첫 응답을 기다리는 동안 로딩 상태를 표시하기 위한 변수
  bool _isFirstResponseLoading = true;

  @override
  void initState() {
    super.initState();
    // 화면이 시작되자마자 첫 AI 응답을 받아옴
    _getInitialAiResponse();
  }

  // 첫 AI 응답을 받아오는 함수
  Future<void> _getInitialAiResponse() async {
    try {
      // HomeScreen에서 받은 상세한 프롬프트를 '첫 번째 사용자 메시지'로 사용
      final aiResponseText = await _chatService.getAiResponse(
        userMessage: widget.initialAnalysis,
        conversationHistory: [], // 첫 질문이므로 대화 기록은 없음
      );

      // AI의 첫 답변을 메시지 리스트에 추가
      final firstAiMessage = ChatMessage(
        text: aiResponseText,
        user: _aiUser,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, firstAiMessage);
      });
    } catch (e) {
      // 에러 발생 시 에러 메시지를 AI 답변 대신 표시
      final errorMessage = ChatMessage(
        text: "죄송합니다, 첫 분석 결과를 가져오는 데 실패했어요. 네트워크 상태를 확인하고 다시 시도해주세요. ($e)",
        user: _aiUser,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.insert(0, errorMessage);
      });
    } finally {
      // 성공하든 실패하든 로딩 상태를 종료
      setState(() {
        _isFirstResponseLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 정리 도우미'),
      ),
      // 로딩 상태에 따라 다른 화면을 보여줌
      body: _isFirstResponseLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("AI가 방을 분석하고 있습니다...\n잠시만 기다려주세요."),
                ],
              ),
            )
          : DashChat(
              currentUser: _currentUser,
              onSend: _handleSend,
              messages: _messages,
              inputOptions: InputOptions(
                inputDisabled: _isFirstResponseLoading, // 후속 질문도 로딩 중에는 비활성화
              ),
              messageOptions: const MessageOptions(
                currentUserContainerColor: Colors.blue,
                containerColor: Color.fromRGBO(245, 245, 245, 1),
                textColor: Colors.black,
              ),
            ),
    );
  }

  // 사용자의 '후속 질문'을 처리하는 함수 (이 부분은 이전과 거의 동일)
  Future<void> _handleSend(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
    });

    try {
      final conversationHistory = List<ChatMessage>.from(_messages);

      final aiResponseText = await _chatService.getAiResponse(
        userMessage: message.text,
        conversationHistory: conversationHistory,
      );

      final aiMessage = ChatMessage(
        text: aiResponseText,
        user: _aiUser,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}
