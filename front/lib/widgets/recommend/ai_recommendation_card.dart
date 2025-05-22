import 'package:flutter/material.dart';
import '../../utils/ai_utils.dart';

class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final Animation<double> fadeAnimation;
  final int index;
  final VoidCallback onTap;

  const RecommendationCard({
    Key? key,
    required this.mountain,
    required this.fadeAnimation,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  // 난이도에 따른 색상 설정
  Color _getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color(0xFFE53935); // 빨간색 (어려움)
      case 'M':
        return const Color(0xFFFDD835); // 노란색 (보통)
      case 'L':
        return const Color(0xFF52A486); // 초록색 (쉬움)
      default:
        return const Color(0xFF1E88E5); // 파란색 (기본)
    }
  }

  @override
  Widget build(BuildContext context) {
    // 산 정보 가져오기
    final name = mountain['mountain_name'] as String? ?? '';
    final location = mountain['location'] as String? ?? '위치 정보 없음';
    
    // 원본 이미지 URL 가져오기
    final rawImageUrl = mountain['image_url'] as String?;
    
    // 제한된 도메인인지 확인하고 적절히 처리된 URL 획득
    final imgUrl = ImageUtils.getProcessedImageUrl(rawImageUrl);
    
    final height = mountain['height'] ?? 0; 
    final level = mountain['level'] as String? ?? 'M';
    
    // 난이도 텍스트 변환
    final difficultyText = () {
      switch (level) {
        case 'L':
          return '쉬움';
        case 'M':
          return '보통';
        case 'H':
          return '어려움';
        default:
          return '보통';
      }
    }();
    
    final levelColor = _getLevelColor(level);
    final primaryColor = const Color(0xFF52A486);

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 이미지 - 여기서 mount_default.png 사용하도록 수정
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('이미지 로딩 오류: $error');
                            // mount_default.png 이미지 사용하도록 변경
                            return Image.asset(
                              'lib/assets/images/mount_default.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'lib/assets/images/mount_default.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                  ),
                  const SizedBox(width: 16), // 간격 늘림
                  
                  // 산 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 산 이름
                        Padding(
                          padding: const EdgeInsets.only(left: 18), 
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8), 

                        // 위치 정보
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // 고도와 난이도를 한 줄에 표시 
                        Row(
                          children: [
                            // 고도 정보
                            Icon(Icons.height, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${height}m', // height 사용
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            
                            // 난이도 정보 (색상으로 구분)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: levelColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              difficultyText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 난이도에 따른 색상을 외부에서 가져올 수 있도록 메서드 추가
  static Color getLevelColor(String level) {
    switch (level) {
      case 'H':
        return const Color(0xFFE53935); // 빨간색 (어려움)
      case 'M':
        return const Color(0xFFFDD835); // 노란색 (보통)
      case 'L':
        return const Color(0xFF52A486); // 초록색 (쉬움)
      default:
        return const Color(0xFF1E88E5); // 파란색 (기본)
    }
  }
}