import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/detection_service.dart';
import '../widgets/detection_painter.dart';
import '../models/detection_result.dart';
import 'package:image/image.dart' as img;
import 'chat_screen.dart';
import '../utils/prompt_generator.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription? camera;
  const HomeScreen({super.key, this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  File? _image;
  final ImagePicker picker = ImagePicker();
  List<dynamic> _detections = []; // YOLO 서버에서 받은 원본 데이터
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.camera == null) return;

    _cameraController = CameraController(
      widget.camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }).catchError((e) {
      print("카메라 초기화 실패: $e");
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _detections = [];
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);
      final result = await uploadImageToServer(imageFile, context);

      if (mounted) {
        setState(() {
          _image = imageFile;
          _detections = result;
        });
      }
    } catch (e) {
      print("사진 촬영/업로드 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('사진 처리에 실패했습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _detections = [];
    });

    try {
      final XFile? picked = await picker.pickImage(source: source);
      if (!mounted || picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final imageFile = File(picked.path);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception("이미지 디코딩 실패");

      final resizedImage = img.copyResize(image, width: 1080);
      final resizedImageBytes = img.encodeJpg(resizedImage, quality: 85);
      final tempDir = await Directory.systemTemp.createTemp();
      final resizedFile = await File('${tempDir.path}/resized_image.jpg')
          .writeAsBytes(resizedImageBytes);

      final result = await uploadImageToServer(resizedFile, context);

      if (mounted) {
        print('Detections from server: $result');
        setState(() {
          _image = resizedFile;
          _detections = result;
        });
      }
    } catch (e) {
      print("갤러리 이미지 선택/업로드 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('이미지를 불러오는 데 실패했습니다.')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<ui.Image> _getImageInfo(File file) async {
    final data = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Widget _buildDetectedImage() {
    if (_image == null) {
      return const Center(child: Text('촬영된 사진이 여기에 표시됩니다.'));
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            return FutureBuilder<ui.Image>(
              future: _getImageInfo(_image!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final originalWidth = snapshot.data!.width.toDouble();
                  final originalHeight = snapshot.data!.height.toDouble();
                  double displayWidth, displayHeight;
                  final imageRatio = originalWidth / originalHeight;
                  final containerRatio = maxWidth / maxHeight;

                  if (imageRatio > containerRatio) {
                    displayWidth = maxWidth;
                    displayHeight = maxWidth / imageRatio;
                  } else {
                    displayHeight = maxHeight;
                    displayWidth = maxHeight * imageRatio;
                  }

                  final scaleX = displayWidth / originalWidth;
                  final scaleY = displayHeight / originalHeight;

                  return Center(
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: Stack(
                        children: [
                          Image.file(
                            _image!,
                            width: displayWidth,
                            height: displayHeight,
                            fit: BoxFit.fill,
                          ),
                          CustomPaint(
                            size: Size(displayWidth, displayHeight),
                            painter: DetectionPainter(
                              _detections,
                              scaleX: scaleX,
                              scaleY: scaleY,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          },
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('객체를 탐지하고 있습니다...',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Check App'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '반갑습니다.\n깔끔한 방 정리를 돕겠습니다!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('사진 찍기'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('갤러리에서 불러오기'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _analyzeWithAI,
                    icon: const Icon(Icons.psychology),
                    label: const Text('AI 분석 요청 및 대화하기'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: Text('카메라 초기화 중...')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildDetectedImage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeWithAI() async {
    if (_detections.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('먼저 사진을 분석하여 객체를 탐지해주세요.')));
      return;
    }

    final parsedDetections = _detections
        .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
        .toList();

    final List<DetectionResult>? finalDetections =
        await showDialog<List<DetectionResult>>(
      context: context,
      barrierDismissible: false, // 바깥 영역을 탭해도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return DeletableDetectionsDialog(initialDetections: parsedDetections);
      },
    );

    // 사용자가 '취소'하지 않고 최종 목록을 반환했으며 그 목록이 비어있지 않은 경우
    if (finalDetections != null && finalDetections.isNotEmpty) {
      _navigateToChatScreen(finalDetections);
    } else if (finalDetections != null && finalDetections.isEmpty) {
      // 사용자가 모든 항목을 제거한 경우
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 객체가 제거되어 대화를 시작할 수 없습니다.')),
      );
    }
  }

  void _navigateToChatScreen(List<DetectionResult> detections) {
    final initialMessage = PromptGenerator.createInitialMessage(detections);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(initialAnalysis: initialMessage),
      ),
    );
  }
}

/// 사용자가 탐지된 객체 목록을 수정할 수 있는 다이얼로그 위젯
class DeletableDetectionsDialog extends StatefulWidget {
  final List<DetectionResult> initialDetections;

  const DeletableDetectionsDialog({super.key, required this.initialDetections});

  @override
  State<DeletableDetectionsDialog> createState() =>
      _DeletableDetectionsDialogState();
}

class _DeletableDetectionsDialogState extends State<DeletableDetectionsDialog> {
  // 각 객체의 선택 상태를 저장하는 Map. true이면 선택 false이면 제거.
  late Map<DetectionResult, bool> _selectionStates;

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 모든 객체를 '선택된' 상태로 초기화
    _selectionStates = {
      for (var detection in widget.initialDetections) detection: true
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('탐지된 객체 수정'),
      content: SingleChildScrollView(
        child: ListBody(
          // Map의 키를 기반으로 체크박스 리스트를 만들어 제공
          children: _selectionStates.keys.map((detection) {
            return CheckboxListTile(
              title: Text(detection.label),
              value: _selectionStates[detection], // 현재 선택 상태
              onChanged: (bool? newValue) {
                // 체크박스를 누를 때마다 상태를 업데이트
                setState(() {
                  _selectionStates[detection] = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading, // 체크박스를 앞에 표시
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('취소'),
          onPressed: () {
            // 아무것도 반환하지 않음
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('선택 완료 및 대화하기'),
          onPressed: () {
            // 현재 선택된 객체들만 필터링
            final finalDetections = _selectionStates.entries
                .where((entry) => entry.value) // value가 true인 항목만 선택
                .map((entry) => entry.key) // key를 추출
                .toList();

            // 필터링된 최종 목록을 결과로 반환
            Navigator.of(context).pop(finalDetections);
          },
        ),
      ],
    );
  }
}
