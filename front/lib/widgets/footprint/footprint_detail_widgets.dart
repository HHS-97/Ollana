import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/compare_response.dart';
import '../../models/record.dart';
import '../../utils/footprint_utils.dart';

Widget buildCompareResult(CompareResponse compareData) {
  final records = compareData.records;
  final result = compareData.result;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Divider(thickness: 1),
      Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: records.map((record) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52A486),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween, // spaceEvenly 대신 spaceBetween 사용
  children: [
    Flexible(
      flex: 1,
      child: buildMetricCard(
        '',
        '${record.maxHeartRate}',
        'bpm',
        Colors.red[100]!,
        Colors.red[700]!,
        Icons.favorite,
      ),
    ),
    SizedBox(width: 4), // 작은 간격 추가
    Flexible(
      flex: 1,
      child: buildMetricCard(
        '',
        '${record.averageHeartRate.toStringAsFixed(1)}',
        'bpm',
        Colors.blue[100]!,
        Colors.blue[700]!,
        Icons.monitor_heart_outlined,
      ),
    ),
    SizedBox(width: 4), // 작은 간격 추가
    Flexible(
      flex: 1,
      child: buildMetricCard(
        '',
        '${record.time}',
        '분',
        Colors.green[100]!,
        Colors.green[700]!,
        Icons.timer,
      ),
    ),
  ],
),

                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      if (result != null) ...[
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      WidgetSpan(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                result.growthStatus == 'IMPROVING' ? Icons.emoji_events : Icons.trending_down,
                                size: 18,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatGrowthStatus(result.growthStatus),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextSpan(
                        text: '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: result.growthStatus == 'IMPROVING' ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                buildComparisonItemCute('최고 심박수', result.maxHeartRateDiff, 'bpm', result.maxHeartRateDiff <= 0, Icons.favorite),
                const SizedBox(height: 16),
                buildComparisonItemCute('평균 심박수', result.avgHeartRateDiff, 'bpm', result.avgHeartRateDiff <= 0, Icons.monitor_heart_outlined),
                const SizedBox(height: 16),
                buildComparisonItemCute('소요 시간', result.timeDiff, '분', result.timeDiff <= 0, Icons.timer),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      const Divider(thickness: 1),
    ],
  );
}

Widget buildMetricCard(String label, String value, String unit, Color bgColor, Color textColor, IconData icon) {
  // 통일된 텍스트 색상
  final Color uniformTextColor = Colors.grey[800]!;
  
  // 아이콘에 따라 배경색과 아이콘 색상 결정
  Color updatedBgColor;
  Color updatedIconColor;
  
  if (icon == Icons.favorite) {
    updatedBgColor = Colors.red[50]!;
    updatedIconColor = Colors.red[600]!;
  } else if (icon == Icons.monitor_heart_outlined) {
    updatedBgColor = Colors.blue[50]!;
    updatedIconColor = Colors.blue[600]!;
  } else {
    updatedBgColor = Colors.green[50]!;
    updatedIconColor = Colors.green[600]!;
  }
  
  return Container(
    // 고정 너비 제거하고 사용 가능한 공간을 최대한 활용
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(
      color: updatedBgColor, 
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: updatedIconColor, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon == Icons.favorite 
                    ? '최고 심박수'
                    : icon == Icons.monitor_heart_outlined
                        ? '평균 심박수'
                        : '소요 시간',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: uniformTextColor,
                ),
                maxLines: 1,
              ),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: uniformTextColor,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.normal,
                          color: uniformTextColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    )
  );
}

// buildComparisonItemCute 수정 - 텍스트 크기 조정 및 공간 최적화
Widget buildComparisonItemCute(String label, int diff, String unit, bool isPositive, IconData icon) {
  final sign = diff > 0 ? '+' : '';
  // Determine colors based on the metric label
  Color bgColor;
  Color metricColor;
  switch (label) {
    case '최고 심박수':
      bgColor = Colors.red[50]!;
      metricColor = Colors.red[600]!;
      break;
    case '평균 심박수':
      bgColor = Colors.blue[50]!;
      metricColor = Colors.blue[600]!;
      break;
    case '소요 시간':
      bgColor = Colors.green[50]!;
      metricColor = Colors.green[600]!;
      break;
    default:
      bgColor = Colors.grey[50]!;
      metricColor = Colors.grey[600]!;
  }

  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8), // 패딩 축소
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: metricColor,
            size: 18, // 아이콘 크기 축소
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13, // 폰트 크기 축소
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 1, // 최대 1줄로 제한
                overflow: TextOverflow.ellipsis, // 넘치는 텍스트는 생략
              ),
              const SizedBox(height: 2), // 간격 축소
              Text(
                '이전 기록 대비',
                style: TextStyle(
                  fontSize: 11, // 폰트 크기 축소
                  color: Colors.grey[600],
                ),
                maxLines: 1, // 최대 1줄로 제한
                overflow: TextOverflow.ellipsis, // 넘치는 텍스트는 생략
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // 패딩 축소
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                color: metricColor,
                size: 14, // 아이콘 크기 축소
              ),
              const SizedBox(width: 4),
              Text(
                '$sign$diff $unit',
                style: TextStyle(
                  fontSize: 13, // 폰트 크기 축소
                  fontWeight: FontWeight.bold,
                  color: metricColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget legendItem(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );
}

LineChartBarData line(
  List<FlSpot> spots,
  Color color,
  String label,
  List<Record> records,
  int pathId,
  Map<int, Set<int>> selectedRecordIdsByPath,
) {
  final selectedRecordIds = selectedRecordIdsByPath[pathId] ?? {};
  return LineChartBarData(
    spots: spots,
    isCurved: true,
    dotData: FlDotData(
      show: true,
      getDotPainter: (spot, percent, barData, index) {
        final recordId = records[index].recordId;
        return FlDotCirclePainter(
          radius: selectedRecordIds.contains(recordId) ? 6 : 4,
          color: selectedRecordIds.contains(recordId) ? Colors.orange : color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        );
      },
    ),
    color: color,
    barWidth: 2,
    belowBarData: BarAreaData(
      show: true,
      color: color.withAlpha(25),
    ),
  );
}