import 'package:flutter/material.dart';
import '../../utils/ai_utils.dart';

class MountainDetailDialog extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final Color primaryColor;
  final Color textColor;

  const MountainDetailDialog({
    Key? key,
    required this.mountain,
    required this.primaryColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = mountain['mountain_name'] as String?;
    final desc = mountain['mountain_description'] as String?;

    // 원본 이미지 URL 가져오기
  final rawImageUrl = mountain['image_url'] as String?;
  print("원본 이미지 URL: $rawImageUrl");
  
  // 제한된 도메인인지 확인하고 적절히 처리된 URL 획득
  final imgUrl = ImageUtils.getProcessedImageUrl(rawImageUrl);

    // 높이 포맷 변경: 소수점이 있는 경우 정수로 변환
    final double? heightValue = mountain['height'] is double ? mountain['height'] as double : null;
    final String elevation = heightValue != null 
        ? '${heightValue % 1 == 0 ? heightValue.toInt() : heightValue}m' // 소수점이 .0인 경우 정수로 표시
        : '정보 없음';

    final difficulty = () {
      switch (mountain['level'] as String?) {
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

    // 난이도에 따른 아이콘 선택
    IconData getDifficultyIcon(String? level) {
      switch (level) {
        case 'H':
          return Icons.trending_up;
        case 'M':
          return Icons.trending_flat;
        case 'L':
          return Icons.trending_down;
        default:
          return Icons.landscape;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                imgUrl != null
                ? Image.network(
                    imgUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      print("이미지 로딩 중: ${loadingProgress.expectedTotalBytes != null 
                        ? '${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}'
                        : '알 수 없음'}");
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (ctx, err, st) {
                      print('이미지 로딩 오류: $err');
                      print('스택 트레이스: $st');
                      return Image.asset(
                        'lib/assets/images/mount_default.png',
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'lib/assets/images/mount_default.png',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.terrain,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name ?? '추천 산',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Color.fromARGB(150, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.white),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // 수정된 정보 영역 (배경색 제거 버전)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  // color 속성 제거로 배경색 없음
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // 높이 정보
                    Expanded(
                      child: Row(
                        children: [
                          // 아이콘
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.height,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 내용
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '높이',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                elevation,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 구분선
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    
                    // 난이도 정보
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            // 아이콘
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getDifficultyIcon(mountain['level'] as String?),
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // 내용
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '난이도',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  difficulty,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상세 설명',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc ?? '정보가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}