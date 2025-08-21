# 룸췤: 객체 인식 기반의 맞춤형 공간 정리 서비스

## 프로젝트 목표

1. **개인 맞춤형 솔루션 제공**: 사용자의 실제 공간 데이터를 기반으로 구체적이고 실용적인 정리 가이드 제공  
2. **정리 과정의 심리적 장벽 완화**: 사용자가 정리를 쉽게 시작 가능  
3. **지속 가능한 상호작용**: AI와의 대화형 피드백 루프를 통해 정리 과정 문제 해결  
4. **풀스택 AI 서비스 구축 경험**: 프런트엔드, 백엔드, AI 모델 서빙, 컨테이너화까지 직접 구축

## 주요 기능

- **이미지 기반 객체 탐지**  
  스마트폰 카메라로 방 사진 촬영 또는 갤러리 이미지를 선택하여 학습된 YOLOv8 모델이 객체를 식별하고 위치를 파악합니다.

- **개인 맞춤형 AI 정리 컨설팅**  
  탐지된 객체 정보를 바탕으로 생성형 AI(llama3)가 사용자의 방 상태에 가장 적합한 정리 계획을 생성합니다.

- **대화형 채팅을 통한 지속적인 피드백**  
  사용자는 AI가 제공한 초기 분석 결과를 바탕으로 채팅을 통해 추가 질문이 가능하며 질문에 대한 조언을 추가적으로 제공합니다.

- **Docker 기반 개발/테스트 환경**  
  - `docker-compose.dev.yml`: 실제 모델 사용 개발 환경  
  - `docker-compose.test.yml`: Mock 데이터 테스트 환경
 
## 기술 스택 (Tech Stack)
| 분야 | 기술 | 설명 |
|------|------|------|
| 프런트엔드 | Flutter, Dart | 크로스 플랫폼 모바일 앱 개발 |
| 백엔드 | Node.js, Express | RESTful API 서버 구축 |
| 객체 탐지 | Python, FastAPI, YOLOv8 | 커스텀 데이터셋 학습 객체 탐지 모델 서빙 |
| 모델 | Ollama, Llama3 | 대화형 AI |
| 데이터베이스 | MySQL | 사용자 데이터 및 분석 결과 저장 |
| 인프라 | Docker, Docker Compose | 전체 시스템 컨테이너화 |

## 사용 방법

### 1. 전제 조건
- Docker & Docker Compose 설치  
- Flutter SDK 설치  
- Ollama 설치
- Android Emulator 또는 실제 디바이스 연결  
- .env 파일 작성

### 2. 백엔드 시스템 실행
```bash
# 프로젝트 클론
git clone https://github.com/HongEunK/RoomCheckProject.git
cd RoomCheck

# AI 모델 다운로드 (llama3, Ollama 필요)
ollama pull llama3

# 환경 변수 파일 설정
# ./backend/.env.dev, ./backend/.env.test
# ./room-check-app/.env.dev, ./room-check-app/.env.test

# Docker 컨테이너 실행 (개발 환경)
docker-compose -f docker-compose.dev.yml up --build -d

# 테스트 환경 실행 시
docker-compose -f docker-compose.test.yml up --build -d
```
### 3. Flutter 앱 실행
```bash
cd room-check-app
flutter pub get

# 개발 환경 실행
flutter run --dart-define=ENV=dev

# 테스트 환경 실행
flutter run --dart-define=ENV=test
```
