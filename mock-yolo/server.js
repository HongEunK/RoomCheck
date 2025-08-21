const express = require('express');
const cors = require('cors');
const app = express();

// base64 문자열을 받기 위해 body-parser의 limit 옵션 추가
app.use(express.json({ limit: '50mb' }));
app.use(cors());

// Real YOLO와 동일한 '/upload' 주소를 사용
app.post('/upload', (req, res) => {
  // Real YOLO와 완벽하게 동일한 JSON 응답 구조를 사용
  const responseData = {
    message: "객체 탐지 완료 (Mock)",
    detections: [
      {
        box: [10.0, 20.0, 150.0, 200.0],
        class: 3, // 예시 클래스 ID
        label: 'bedding', // Real YOLO와 동일하게 'label' 키 사용
        confidence: 0.95
      },
      {
        box: [100.0, 120.0, 250.0, 400.0],
        class: 56, // 예시 클래스 ID
        label: 'chair',
        confidence: 0.85
      }
    ]
  };

  res.json(responseData);
});

const PORT = 8000;
app.listen(PORT, () => {
  console.log(`Mock YOLO API running on port ${PORT}`);
});
