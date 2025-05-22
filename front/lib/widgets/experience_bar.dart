// lib/widgets/experience_bar.dart - 더 세련된 "현재/목표 XP" 통합 표시
import 'package:flutter/material.dart';

/// 등급별 레벨업에 필요한 EXP - 원래 값 그대로 유지
const _xpThresholds = {
  'SEED': 100,
  'SPROUT': 300,
  'TREE': 500,
  'FRUIT': 800,
  'MOUNTAIN': 1000,
};

class ExperienceBar extends StatelessWidget {
  final int currentXp;
  final String grade;

  const ExperienceBar({
    Key? key,
    required this.currentXp,
    required this.grade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final xpForNext = _xpThresholds[grade] ?? 100; // 원래 값 사용
    final progress = (currentXp / xpForNext).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 프로그레스 바
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // 배경
                    Container(
                      width: fullWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    
                    // 채움
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500), // 애니메이션 효과
                      curve: Curves.easeOutQuart,
                      width: fullWidth * progress,
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 143, 237, 203), // 시작 색상
                            Color(0xFF52A486), // 끝 색상
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 반짝임 효과
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                5, 
                                (index) => Container(
                                  width: 1,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (progress > 0.05 && progress < 0.95) // 너무 끝에 있지 않을 때만
                      Positioned(
                        left: (fullWidth * progress) - 4,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF52A486).withOpacity(0.3),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${currentXp}xp / ${xpForNext}xp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}