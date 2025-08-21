import '../models/detection_result.dart';

class PromptGenerator {
  // 다른 곳에서 객체 생성 없이 바로 호출할 수 있도록 static 메소드로 만들었음
  static String createInitialMessage(List<DetectionResult> detections) {
    final buffer = StringBuffer();

    buffer.writeln('방 사진을 분석한 결과는 다음과 같습니다:\n');

    for (var d in detections) {
      // final confidence = (d.confidence * 100).toStringAsFixed(1);
      buffer.writeln(
        '- ${d.label} (위치: x=${d.x.toStringAsFixed(1)}, y=${d.y.toStringAsFixed(1)}, 너비=${d.width.toStringAsFixed(1)}, 높이=${d.height.toStringAsFixed(1)})',
      );
    }
    buffer.writeln('\n이 정보를 바탕으로 아래 질문에 답변해주세요: ');
    buffer.writeln('1. 방의 전반적인 정리 상태를 알려주세요.');
    buffer.writeln('2. 각 물건을 어떻게 청소하고 정리하고 어떤 장소에 둬야 좋을지 구체적인 방법을 알려주세요.');

    return buffer.toString();
  }
}
