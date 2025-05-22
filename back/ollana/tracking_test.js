import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

// 부하 테스트 설정
export const options = {
  stages: [
    { duration: '1m', target: 10 }, // 10명의 동시 사용자로 시작 
    { duration: '3m', target: 50 }, // 50명으로 증가
    { duration: '1m', target: 100 }, // 100명으로 증가
    { duration: '1m', target: 0 },  // 점진적으로 감소
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95%의 요청이 500ms 내에 처리되어야 함
    'http_req_duration{scenario:finish}': ['p(95)<1000'], // finish API 응답 시간
  },
};

// 성공 및 실패 카운터
const trackingFinishErrors = new Counter('tracking_finish_errors');

// 테스트 시나리오
export default function() {
  const token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0aXBvczI3NjcxQG1hZ3BpdC5jb20iLCJ1c2VySWQiOjMyLCJpYXQiOjE3NDc3NTczNTcsImV4cCI6MTc4Mzc1NzM1N30.8lN_PbGbTuZLxJ8YnfTvERQtklSlk0KG05EYk5Nyz-4';
  
  // 각 사용자별 트래킹 데이터 생성
  const recordSize = Math.floor(Math.random() * 1000) + 100; // 100~1100개의 기록 포인트
  const records = [];
  
  for (let i = 0; i < recordSize; i++) {
    records.push({
      time: i * 10, // 10초 간격
      distance: Math.random() * 0.05 + (i * 0.01), // 누적 거리
      heartRate: Math.floor(Math.random() * 40) + 80, // 80~120 bpm
      latitude: 37.123 + (Math.random() * 0.01), // 임의의 위치
      longitude: 127.123 + (Math.random() * 0.01)
    });
  }
  
  // 트래킹 종료 요청
  const finishData = {
    mountainId: 132,
    pathId: 7917,
    opponentId: null,
    recordId: null,
    mode: "GENERAL",
    isSave: true,
    finalLatitude: 37.123,
    finalLongitude: 127.123,
    finalTime: recordSize * 10, // 총 시간
    finalDistance: recordSize * 0.01, // 총 거리
    records: records
  };
  
  const finishRes = http.post('http://localhost:8080/tracking/finish', JSON.stringify(finishData), {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    tags: { scenario: 'finish' }
  });
  
  // 응답 확인
  const finishCheck = check(finishRes, {
    'status is 200': (r) => r.status === 200,
    'response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  if (!finishCheck) {
    trackingFinishErrors.add(1);
    console.log(`Error: ${finishRes.status}, ${finishRes.body}`);
  }
  
  sleep(1);
}