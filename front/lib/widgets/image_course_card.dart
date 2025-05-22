// image_course_card.dart: 추천 코스를 시각적으로 표현하는 이미지 카드 위젯
// - 코스 데이터(제목, 부제목, 이미지)를 시각적으로 표현
// - 상단에 그라데이션 오버레이로 텍스트 가독성 향상
// - 둥근 모서리와 여백으로 카드 디자인 구현
// - 리스트뷰에서 반복 사용되는 재사용 가능한 UI 컴포넌트

import 'package:flutter/material.dart';
import '../models/course_data.dart';

class ImageCourseCard extends StatelessWidget {
  final CourseData course;
  const ImageCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(course.imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(130), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                course.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
