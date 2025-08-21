FROM node:18

# 작업 디렉토리
WORKDIR /app

# 의존성 복사 및 설치
COPY package*.json ./
RUN npm install

# 소스 복사
COPY . .

# 서버 실행
CMD ["npm", "start"]
