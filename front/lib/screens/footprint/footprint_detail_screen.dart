import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/compare_response.dart';
import '../../models/path_detail.dart';
import '../../services/my_footprint_service.dart';
import '../../utils/footprint_utils.dart';
import '../../widgets/footprint/footprint_detail_widgets.dart';
import './date_picker_modal.dart';

class FootprintDetailScreen extends StatefulWidget {
  final int footprintId;
  final String token;

  const FootprintDetailScreen({
    super.key,
    required this.footprintId,
    required this.token,
  });

  @override
  State<FootprintDetailScreen> createState() => _FootprintDetailScreenState();
}

class _FootprintDetailScreenState extends State<FootprintDetailScreen> {
  List<PathDetail> paths = [];
  String? mountainName;
  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasNextPage = true;
  Map<int, Set<int>> _selectedRecordIdsByPath = {};
  Map<int, CompareResponse?> _compareDataByPath = {};
  Map<int, DateTime?> _startDatesByPath = {};
  Map<int, DateTime?> _endDatesByPath = {};
  bool _isTooltipVisible = false; // 툴팁 표시 여부를 관리하는 상태
  OverlayEntry? _overlayEntry; // 오버레이 엔트리

  @override
  void initState() {
    super.initState();
    _fetchFootprintDetail();
  }

  // dispose 메서드 추가
  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  // 툴팁 토글 함수
  void _toggleTooltip(BuildContext context) {
    setState(() {
      if (_isTooltipVisible) {
        _removeTooltip(); 
      } else {
        _showTooltip(context);
      }
    });
  }

  void _showTooltip(BuildContext context) {
    _removeTooltip(); // 기존 툴팁이 있다면 제거

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: 28, // 오른쪽에서의 거리
        bottom: 60, // 하단에서의 거리 (FAB 위에 위치하도록)
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 265, 
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Color(0xFF52A486), 
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                        spreadRadius: 2,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF5CB89A),
                        Color(0xFF3D8A6B),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '도움말',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '그래프의 날짜를 클릭해서 상세 내역과\n비교 결과를 조회해보세요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 말풍선 꼬리 부분 추가
                Padding(
                  padding: EdgeInsets.only(right: 15.0),
                  child: ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      width: 15,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF3D8A6B),
                            Color(0xFF3D8A6B),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isTooltipVisible = true;
  }

  // 툴팁 제거 함수
  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isTooltipVisible = false;
  }

  Future<void> _fetchFootprintDetail({int? pathId}) async {
    if (_isFetching || (!_hasNextPage && pathId == null)) return;

    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      if (pathId != null) {
        final startDate = _startDatesByPath[pathId];
        final endDate = _endDatesByPath[pathId];
        final detailResponse = await service.getFootprintPathDetail(
          widget.token,
          widget.footprintId,
          pathId,
          start: startDate,
          end: endDate,
        );

        setState(() {
          final index = paths.indexWhere((p) => p.pathId == pathId);
          if (index != -1) {
            if (detailResponse.records.isNotEmpty) {
              paths[index] = PathDetail(
                pathId: pathId,
                pathName: paths[index].pathName,
                records: detailResponse.records,
                isExceed: detailResponse.isExceed,
              );
              _selectedRecordIdsByPath[pathId] = {};
              _compareDataByPath[pathId] = null;
            }
          } else if (!detailResponse.records.isEmpty) {
            paths.add(detailResponse);
          }
        });

        if (detailResponse.isExceed) {
          _showSnackBar('설정하신 기간의 등산 기록이 5개를 초과했어요!\n종료일 기준 최근 5개만 조회할게요');
        } else if (detailResponse.records.isEmpty) {
          _showSnackBar('설정하신 기간의 등산 기록이 존재하지 않아요');
        }
      } else {
        final detailResponse = await service.getFootprintDetail(
          widget.token,
          widget.footprintId,
          page: _currentPage,
        );

        setState(() {
          mountainName ??= detailResponse.mountainName;
          paths.addAll(detailResponse.paths);
          for (var path in detailResponse.paths) {
            _selectedRecordIdsByPath[path.pathId] ??= {};
            _compareDataByPath[path.pathId] ??= null;
            _startDatesByPath[path.pathId] ??= null;
            _endDatesByPath[path.pathId] ??= null;
          }
          _currentPage++;
          _hasNextPage = !detailResponse.last;
        });
      }
    } catch (e) {
      _showSnackBar('등산 상세 결과를 불러오지 못했습니다.');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                message.contains('존재하지 않습니다') 
                  ? Icons.info_outline 
                  : Icons.notifications_none,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF52A486),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3), // 더 짧은 시간으로 수정
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3,
        margin: const EdgeInsets.all(16),
        // 확인 버튼 제거
      ),
    );
  }

  Future<void> _fetchCompareData(int pathId) async {
    final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
    if (selectedRecordIds.isEmpty) {
      setState(() {
        _compareDataByPath[pathId] = null;
      });
      return;
    }

    try {
      final service = MyFootprintService();
      final compareResponse = await service.getCompareData(
        widget.token,
        widget.footprintId,
        selectedRecordIds,
      );

      setState(() {
        _compareDataByPath[pathId] = compareResponse;
      });
    } catch (e) {
      _showSnackBar('비교 데이터를 불러오지 못했습니다.');
      setState(() {
        _compareDataByPath[pathId] = null;
      });
    }
  }

  void _toggleRecordSelection(int pathId, int recordId) {
    setState(() {
      final selectedRecordIds = _selectedRecordIdsByPath[pathId] ?? {};
      if (selectedRecordIds.contains(recordId)) {
        selectedRecordIds.remove(recordId);
      } else if (selectedRecordIds.length < 2) {
        selectedRecordIds.add(recordId);
      }
      _selectedRecordIdsByPath[pathId] = selectedRecordIds;
    });
    _fetchCompareData(pathId);
  }

  Future<void> _showDatePickerModal(int pathId, bool isStartDate) async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => DatePickerModal(
        initialDate: isStartDate
            ? _startDatesByPath[pathId] ?? DateTime.now()
            : _endDatesByPath[pathId] ?? DateTime.now(),
      ),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDatesByPath[pathId] = selectedDate;
          if (_endDatesByPath[pathId] != null &&
              _endDatesByPath[pathId]!.isBefore(selectedDate)) {
            _endDatesByPath[pathId] = null;
          }
        } else {
          if (_startDatesByPath[pathId] == null) {
            _showSnackBar('시작일을 선택해주세요.');
            return;
          }
          if (selectedDate.isBefore(_startDatesByPath[pathId]!)) {
            _showSnackBar('종료일은 시작일 이후여야 합니다.');
            return;
          }
          _endDatesByPath[pathId] = selectedDate;
        }
      });

      if (_startDatesByPath[pathId] != null && _endDatesByPath[pathId] != null) {
        await _fetchFootprintDetail(pathId: pathId);
      }
    }
  }

  // 레전드 아이템 위젯
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // 라인 차트용 LineChartBarData 생성
  LineChartBarData _buildLineChartBarData(
    List<FlSpot> spots,
    Color color,
    double strokeWidth,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: strokeWidth,
      color: color,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (var path in paths) {
    print('Path ${path.pathId}: ${path.pathName}');
    print('Records count: ${path.records.length}');
    if (path.records.isNotEmpty) {
      try {
        print('First record date: ${path.records[0].date}');
        print('Type of date: ${path.records[0].date.runtimeType}');
        
        // 추가 디버깅: 날짜 관련 정보 더 자세히 확인
        if (path.records[0].date is DateTime) {
          final dateObj = path.records[0].date as DateTime;
          print('DateTime components: year=${dateObj.year}, month=${dateObj.month}, day=${dateObj.day}');
        }
        
        // 전체 레코드 객체 출력
        print('Record object: ${path.records[0].toString()}');
      } catch (e) {
        print('Error accessing date: $e');
      }
    }
  }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0, // 이 값을 0으로 설정
      title: Text(
        mountainName != null ? '$mountainName 발자취' : '발자취',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    ),
      // 물음표 아이콘을 위한 FloatingActionButton 추가
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () {
            _toggleTooltip(context);
          },
          backgroundColor: const Color(0xFF52A486),
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              _isTooltipVisible ? Icons.close : Icons.help_outline,
              key: ValueKey<bool>(_isTooltipVisible),
              color: Colors.white,
              size: 24,
            ),
          ),
          mini: true,
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('최고 심박수', Colors.red),
                const SizedBox(width: 20),
                _buildLegendItem('평균 심박수', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('소요 시간(분)', Colors.green),
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!_isFetching &&
                    _hasNextPage &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                  _fetchFootprintDetail();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 16),
                itemCount: paths.length + (_isFetching ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= paths.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Color(0xFF52A486),
                        ),
                      ),
                    );
                  }

                  final path = paths[index];
                  final compareData = _compareDataByPath[path.pathId];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                color: Color(0xFF52A486),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  path.pathName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          AspectRatio(
  aspectRatio: 1.7,
  child: Padding(
    padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
    child: Builder(
      builder: (context) {
        // 레코드가 없는 경우
        if (path.records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_chart_outlined,
                  size: 40,
                  color: Color(0xFF52A486),
                ),
                const SizedBox(height: 12),
                Text(
                  "그래프를 보려면 기록이 필요해요",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // 레코드가 1개인 경우
        if (path.records.length == 1) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 36,
                        color: Color(0xFF52A486),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "그래프를 확인하려면",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "기록이 2개 이상 필요해요!",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFFEDF7F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "꾸준히 등산해서 기록을 비교해 보세요",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500, 
                            color: Color(0xFF52A486),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // 레코드가 2개 이상인 경우 (그래프 렌더링)
        return LineChart(
          LineChartData(
            minX: 0,
            maxX: path.records.length - 1.0,
            minY: 0,
            maxY: getMaxValue(path) * 1.1,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.white.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                                          final String title;
                                          final Color textColor;

                                          if (touchedSpot.barIndex == 0) {
                                            title =
                                                '최고 심박수: ${touchedSpot.y.toInt()}';
                                            textColor = Colors.black;
                                          } else if (touchedSpot.barIndex == 1) {
                                            title =
                                                '평균 심박수: ${touchedSpot.y.toInt()}';
                                            textColor = Colors.black;
                                          } else {
                                            title =
                                                '소요 시간: ${touchedSpot.y.toInt()}분';
                                            textColor = Colors.black;
                                          }

                                          return LineTooltipItem(
                                            title,
                                            TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          );
                                        }).toList();
                },
              ),
              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                if (event is FlTapUpEvent &&
                                          touchResponse != null &&
                                          touchResponse.lineBarSpots != null) {
                                        final spot = touchResponse.lineBarSpots!.first;
                                        final index = spot.x.toInt();
                                        if (index >= 0 &&
                                            index < path.records.length) {
                                          final recordId =
                                              path.records[index].recordId;
                                          _toggleRecordSelection(
                                              path.pathId, recordId);
                                        }
                                      }
              },
              getTouchedSpotIndicator: (barData, spotIndexes) {
                return spotIndexes.map((index) {
                                        return TouchedSpotIndicatorData(
                                          FlLine(color: Colors.orange, strokeWidth: 2),
                                          FlDotData(
                                            show: true,
                                            getDotPainter:
                                                (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 6,
                                                color: Colors.orange,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList();
              },
            ),
            gridData: FlGridData(
              show: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
            ),
            titlesData: FlTitlesData(
             show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < path.records.length) {
                                            final date = path.records[index].date;
                                            final recordId =
                                                path.records[index].recordId;
                                            final selectedRecordIds =
                                                _selectedRecordIdsByPath[path.pathId] ??
                                                    {};
                                            final isSelected =
                                                selectedRecordIds.contains(recordId);

                                            return GestureDetector(
                                              onTap: () {
                                                _toggleRecordSelection(
                                                    path.pathId, recordId);
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  formatDate(date),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? const Color(0xFF52A486) 
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                      axisNameWidget: const Padding(
                                        padding: EdgeInsets.only(top: 15),
                                        child: Text(
                                          '날짜',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35,
                                        getTitlesWidget: (value, meta) {
                                          if (value == 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
            ),
            borderData: FlBorderData(
             show: true,
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.5),
                                        width: 1),
            ),
            lineBarsData: [
              // 최고 심박수 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(),
                                                  record.maxHeartRate.toDouble());
                                            }).toList(),
                                      Colors.red,
                                      2.5,
                                    ),
                                    // 평균 심박수 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(), record.averageHeartRate);
                                            }).toList(),
                                      Colors.blue,
                                      2.5,
                                    ),
                                    // 소요 시간 라인
                                    _buildLineChartBarData(
                                      path.records.isEmpty
                                          ? [FlSpot(0, 0)]
                                          : path.records.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final record = entry.value;
                                              return FlSpot(
                                                  idx.toDouble(), record.time.toDouble());
                                            }).toList(),
                                      Colors.green,
                                      2.5,
                                    ),
            ],
          ),
        );
      },
    ),
  ),
),
                          if (path.records.length == 1) ...[
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF52A486),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              DateFormat('yyyy-MM-dd').format(path.records[0].date),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: buildMetricCard(
                  '',
                  '${path.records[0].maxHeartRate}',
                  'bpm',
                  Colors.red[100]!,
                  Colors.red[700]!,
                  Icons.favorite,
                ),
              ),
              SizedBox(width: 4),
              Flexible(
                flex: 1,
                child: buildMetricCard(
                  '',
                  '${path.records[0].averageHeartRate.toStringAsFixed(1)}',
                  'bpm',
                  Colors.blue[100]!,
                  Colors.blue[700]!,
                  Icons.monitor_heart_outlined,
                ),
              ),
              SizedBox(width: 4),
              Flexible(
                flex: 1,
                child: buildMetricCard(
                  '',
                  '${path.records[0].time}',
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
    ),
  ),
  const SizedBox(height: 16),
  const Divider(thickness: 1),
],
                          // 수정된 버튼 섹션: 기록이 2개 이상인 경우에만 표시
                          if (path.records.length >= 2) ...[
                            const SizedBox(height: 12), // 버튼과 그래프 사이 간격
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF52A486),
                                      foregroundColor: Colors.white,
                                      minimumSize: Size(120, 36),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: () => _showDatePickerModal(path.pathId, true),
                                    child: Text(
                                      _startDatesByPath[path.pathId] == null
                                          ? '시작일 선택'
                                          : displayDate(_startDatesByPath[path.pathId]),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                if (_startDatesByPath[path.pathId] != null &&
                                    _endDatesByPath[path.pathId] != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '~',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Flexible(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF52A486),
                                      foregroundColor: Colors.white,
                                      minimumSize: Size(120, 36),
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    onPressed: _startDatesByPath[path.pathId] == null
                                        ? null
                                        : () => _showDatePickerModal(path.pathId, false),
                                    child: Text(
                                      _endDatesByPath[path.pathId] == null
                                          ? '종료일 선택'
                                          : displayDate(_endDatesByPath[path.pathId]),
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (compareData != null && compareData.records.isNotEmpty) ...[
                            buildCompareResult(compareData),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(IconData icon, Color color, String label, String value) {
  return Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    ],
  );
}

    // 도움말 메시지를 표시하는 함수 추가
  void _showHelpMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.fromLTRB(16, 0, 16, 70), // 하단에 충분한 여백을 두어 FloatingActionButton과 겹치지 않도록 설정
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
    );
  }
}

Widget _buildSingleRecordMetric(IconData icon, Color color, String value, String label) {
  return Column(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 8),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

Widget _buildCompactMetric(IconData icon, Color color, String value, String label) {
  return Expanded(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TriangleClipper extends CustomClipper<Path> {
    @override
    Path getClip(Size size) {
      final path = Path();
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
      path.close();
      return path;
    }
    

    @override
    bool shouldReclip(CustomClipper<Path> oldClipper) => false;
  }