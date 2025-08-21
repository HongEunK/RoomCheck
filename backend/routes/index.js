const express = require('express');
const router = express.Router();
const axios = require('axios');
const db = require('../db');

// Flutter의 /api/upload 요청을 처리하는 API
router.post('/upload', async (req, res) => {
  try {
    // Flutter 앱에서 보낸 이미지 데이터를 받음
    const { image } = req.body;

    // .env 파일에서 YOLO 서버 주소를 가져옴
    const yoloApiUrl = process.env.YOLO_API_URL;

    // '/upload' 엔드포인트로 이미지 데이터를 전달
    const response = await axios.post(`${yoloApiUrl}/upload`, { image });

    // YOLO 서버가 보내준 예측 결과를 그대로 Flutter 앱에 반환
    res.status(200).json(response.data);

  } catch (error) {
    console.error('YOLO 서비스 호출 중 오류:', error.message);
    res.status(500).json({ error: '이미지 처리 실패' });
  }
});

router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT NOW() AS now');
    res.json({ serverTime: rows[0].now });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'DB 연결 실패' });
  }
});

module.exports = router;

