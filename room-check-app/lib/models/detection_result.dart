class DetectionResult {
  final String label;
  final double confidence;
  final List<double> box; // [left, top, right, bottom]

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.box,
  });

  // box 데이터를 이용해 x, y, width, height를 계산하는 getter
  double get x => box.isNotEmpty ? box[0] : 0.0;
  double get y => box.isNotEmpty ? box[1] : 0.0;
  double get width => box.length == 4 ? box[2] - box[0] : 0.0;
  double get height => box.length == 4 ? box[3] - box[1] : 0.0;

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      label: json['label'] ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      box: List<double>.from(
          json['box']?.map((e) => (e as num).toDouble()) ?? []),
    );
  }
}
