//앱 진입점
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'views/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 실행 시점의 환경 변수를 읽어옴 (기본값 'dev')
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // 읽어온 환경에 맞는 .env 파일을 로드
  await dotenv.load(fileName: ".env.$env");

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('카메라를 초기화할 수 없습니다: $e');
  }

  // 카메라가 없어도 앱이 실행되도록 수정
  runApp(MyApp(camera: cameras?.isNotEmpty == true ? cameras![0] : null));
}

class MyApp extends StatelessWidget {
  final CameraDescription? camera; // 테스트를 위해 camera를 선택적(nullable)로 변경
  const MyApp({super.key, this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Check App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // camera가 null이면 테스트 모드로 Scaffold 표시
      home: camera != null
          ? HomeScreen(camera: camera!)
          : const Scaffold(body: Center(child: Text('Test mode - No camera'))),
      debugShowCheckedModeBanner: false,
    );
  }
}
