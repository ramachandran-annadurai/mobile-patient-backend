import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/vital_sign.dart';

class VitalSignChart extends StatefulWidget {
  final VitalSignType type;
  final int timeRange;
  final List<VitalSign> vitalSigns;

  const VitalSignChart({
    Key? key,
    required this.type,
    required this.timeRange,
    required this.vitalSigns,
  }) : super(key: key);

  @override
  State<VitalSignChart> createState() => _VitalSignChartState();
}

class _VitalSignChartState extends State<VitalSignChart> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.vitalSigns.isEmpty) {
      return _buildEmptyChart();
    }

    final filteredVitals = _filterVitalsByTimeRange();
    if (filteredVitals.isEmpty) {
      return _buildEmptyChart();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.type.displayName} Chart',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getHorizontalInterval(),
                    verticalInterval: _getVerticalInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _getBottomInterval(),
                        getTitlesWidget: (value, meta) {
                          return _getBottomTitle(value);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _getHorizontalInterval(),
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: filteredVitals.length.toDouble() - 1,
                  minY: _getMinY(filteredVitals),
                  maxY: _getMaxY(filteredVitals),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getSpots(filteredVitals),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          _getTypeColor().withOpacity(0.8),
                          _getTypeColor().withOpacity(0.3),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _getTypeColor(),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _getTypeColor().withOpacity(0.3),
                            _getTypeColor().withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: _getTypeColor().withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final vitalSign = filteredVitals[touchedSpot.x.toInt()];
                          return LineTooltipItem(
                            '${vitalSign.formattedValue} ${vitalSign.unit}\n${_formatDateTime(vitalSign.timestamp)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: _getTypeColor(),
                            strokeWidth: 2,
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: _getTypeColor(),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(filteredVitals),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${widget.type.displayName} Chart',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some vital signs to see the chart',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(List<VitalSign> vitalSigns) {
    final normalRange = VitalSign.normalRanges[widget.type];
    if (normalRange == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          'Normal Range',
          '${normalRange['min']} - ${normalRange['max']} ${widget.type.unit}',
          Colors.green,
        ),
        _buildLegendItem(
          'Current Range',
          '${_getMinValue(vitalSigns).toStringAsFixed(1)} - ${_getMaxValue(vitalSigns).toStringAsFixed(1)} ${widget.type.unit}',
          _getTypeColor(),
        ),
        _buildLegendItem(
          'Data Points',
          '${vitalSigns.length} readings',
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  List<VitalSign> _filterVitalsByTimeRange() {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: widget.timeRange));
    
    return widget.vitalSigns
        .where((v) => v.timestamp.isAfter(startDate))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<FlSpot> _getSpots(List<VitalSign> vitalSigns) {
    return vitalSigns.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  double _getMinY(List<VitalSign> vitalSigns) {
    final values = vitalSigns.map((v) => v.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    return min - (min * 0.1);
  }

  double _getMaxY(List<VitalSign> vitalSigns) {
    final values = vitalSigns.map((v) => v.value).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return max + (max * 0.1);
  }

  double _getMinValue(List<VitalSign> vitalSigns) {
    final values = vitalSigns.map((v) => v.value).toList();
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _getMaxValue(List<VitalSign> vitalSigns) {
    final values = vitalSigns.map((v) => v.value).toList();
    return values.reduce((a, b) => a > b ? a : b);
  }

  double _getHorizontalInterval() {
    final filteredVitals = _filterVitalsByTimeRange();
    if (filteredVitals.isEmpty) return 10;
    
    final values = filteredVitals.map((v) => v.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    
    if (range < 10) return 1;
    if (range < 50) return 5;
    if (range < 100) return 10;
    return 20;
  }

  double _getVerticalInterval() {
    final filteredVitals = _filterVitalsByTimeRange();
    if (filteredVitals.length <= 10) return 1;
    if (filteredVitals.length <= 30) return 2;
    return 5;
  }

  double _getBottomInterval() {
    final filteredVitals = _filterVitalsByTimeRange();
    if (filteredVitals.length <= 5) return 1;
    if (filteredVitals.length <= 15) return 2;
    return 5;
  }

  Widget _getBottomTitle(double value) {
    final filteredVitals = _filterVitalsByTimeRange();
    final index = value.toInt();
    
    if (index < 0 || index >= filteredVitals.length) {
      return const Text('');
    }
    
    final vitalSign = filteredVitals[index];
    return Text(
      _formatTime(vitalSign.timestamp),
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case VitalSignType.heartRate:
        return Colors.red;
      case VitalSignType.bloodPressure:
        return Colors.blue;
      case VitalSignType.temperature:
        return Colors.orange;
      case VitalSignType.spO2:
        return Colors.green;
      case VitalSignType.respiratoryRate:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    if (widget.timeRange == 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
