// course_data.dart: 앱에서 사용하는 데이터 모델 클래스 정의
// - CardData: 카드 UI 컴포넌트를 위한 데이터 모델 (ID와 그라데이션 색상 정보)
// - CourseData: 코스 정보를 위한 데이터 모델 (제목, 부제목, 이미지 경로)
// - courseList: 샘플 코스 데이터 목록 (실제 앱에서는 API로 대체 가능)
// - 데이터와 표현을 분리하기 위한 모델 클래스 정의

import 'package:flutter/material.dart';

// 카드 데이터 모델
class CardData {
  final int id;
  final List<Color> gradient;

  CardData({required this.id, required this.gradient});
}

// 코스 데이터 모델
class CourseData {
  final String title;
  final String subtitle;
  final String imagePath;

  CourseData(
      {required this.title, required this.subtitle, required this.imagePath});
}

// 샘플 이미지 코스 리스트
final List<CourseData> courseList = [
  CourseData(
    title: '봄꽃 구경 추천 코스',
    subtitle: 'BEST 6',
    imagePath: 'lib/assets/images/spring.jpg',
  ),
  CourseData(
    title: '영남알프스 4일 완성 속성반',
    subtitle: 'BEST 4',
    imagePath: 'lib/assets/images/alps.jpg',
  ),
  CourseData(
    title: '초보 산행이 추천 코스',
    subtitle: 'BEST 9',
    imagePath: 'lib/assets/images/beginner.jpg',
  ),
  CourseData(
    title: '케이블카 추천 코스',
    subtitle: 'BEST 5',
    imagePath: 'lib/assets/images/cablecar.jpg',
  ),
];
