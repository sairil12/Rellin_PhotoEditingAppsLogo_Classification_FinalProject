import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'dart:ui';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, Map<String, dynamic>> _classificationHistory = {};
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;

  static const List<String> _validClasses = [
    'adobe photos',
    'canva',
    'fotor',
    'lightroom',
    'picsart',
    'pixlr',
    'polarr',
    'remini',
    'snapseed',
    'vsco',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load aggregate history
      final historyJson = prefs.getString('classification_history');
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
        _classificationHistory = decoded.map((key, value) {
          final map = value as Map<String, dynamic>;
          return MapEntry(key, {
            'count': map['count'] as int,
            'totalConfidence': map['totalConfidence'] as double,
            'results': List<double>.from(map['results'] as List),
          });
        });
      }

      // Load recent scans
      final recentScansJson = prefs.getString('scan_history_list');
      if (recentScansJson != null) {
        final List<dynamic> decoded = jsonDecode(recentScansJson);
        _recentScans = decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      developer.log('Error loading analytics data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontFamily: 'serif', // Matching the style from screenshots
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF808080),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/anime.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSummaryCards(),
                      const SizedBox(height: 20),
                      _buildBarChart(),
                      const SizedBox(height: 20),
                      _buildPieChart(),
                      const SizedBox(height: 20),
                      _buildDetailedStats(),
                      const SizedBox(height: 20),
                      _buildRecentScans(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Editing Logo Analysis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Comprehensive statistics and insights',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    int totalScans = 0;
    String mostScanned = 'None';
    int maxCount = 0;
    int lowConfidenceCount = 0;

    _classificationHistory.forEach((key, value) {
      if (!_validClasses.contains(key)) return;
      final count = value['count'] as int;
      totalScans += count;
      if (count > maxCount) {
        maxCount = count;
        mostScanned = key;
      }
      
      final confidences = value['results'] as List<double>;
      lowConfidenceCount += confidences.where((c) => c < 0.7).length;
    });

    // Capitalize most scanned
    if (mostScanned != 'None') {
      mostScanned = mostScanned[0].toUpperCase() + mostScanned.substring(1);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                icon: Icons.bar_chart,
                title: 'Total',
                value: '$totalScans',
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCard(
                icon: Icons.star,
                title: 'Most Scanned',
                value: mostScanned,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low Confidence/Errors',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$lowConfidenceCount scans',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_classificationHistory.isEmpty) return const SizedBox.shrink();

    final filteredHistory = Map.fromEntries(
      _classificationHistory.entries.where((e) => _validClasses.contains(e.key))
    );
    if (filteredHistory.isEmpty) return const SizedBox.shrink();

    final List<Color> colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFFAB47BC),
      const Color(0xFFEF5350),
      const Color(0xFF26A69A),
      const Color(0xFFFFA726),
      const Color(0xFF8D6E63),
      const Color(0xFF78909C),
      const Color(0xFFEC407A),
      const Color(0xFF9CCC65),
      const Color(0xFF42A5F5),
    ];

    final labels = filteredHistory.keys.toList();
    
    final data = filteredHistory.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (e.value['count'] as int).toDouble(),
            color: colors[index % colors.length],
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    // Create a map for x-axis labels
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Counts (Bar Chart)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.isEmpty ? 10 : data.map((e) => e.barRods[0].toY).reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black.withOpacity(0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${labels[groupIndex]}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: (rod.toY).toInt().toString(),
                            style: const TextStyle(
                              color: Colors.yellow,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()].length > 4 
                                  ? '${labels[value.toInt()].substring(0, 4)}...' 
                                  : labels[value.toInt()],
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(labels.length, (index) {
                  final label = labels[index];
                  final count = filteredHistory[label]!['count'] as int;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: colors[index % colors.length],
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_classificationHistory.isEmpty) return const SizedBox.shrink();

    final filteredHistory = Map.fromEntries(
      _classificationHistory.entries.where((e) => _validClasses.contains(e.key))
    );
    if (filteredHistory.isEmpty) return const SizedBox.shrink();

    int totalScans = 0;
    filteredHistory.forEach((_, value) {
      totalScans += value['count'] as int;
    });

    final List<Color> colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFFAB47BC),
      const Color(0xFFEF5350),
      const Color(0xFF26A69A),
      const Color(0xFFFFA726),
      const Color(0xFF8D6E63),
      const Color(0xFF78909C),
      const Color(0xFFEC407A),
      const Color(0xFF9CCC65),
      const Color(0xFF42A5F5),
    ];

    final sections = filteredHistory.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      final count = e.value['count'] as int;
      final percentage = (count / totalScans) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Distribution (Pie Chart)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    if (_classificationHistory.isEmpty) return const SizedBox.shrink();

    final filteredHistory = Map.fromEntries(
      _classificationHistory.entries.where((e) => _validClasses.contains(e.key))
    );
    if (filteredHistory.isEmpty) return const SizedBox.shrink();

    int totalScans = 0;
    filteredHistory.forEach((_, value) {
      totalScans += value['count'] as int;
    });

    final sortedEntries = filteredHistory.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('App', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                const Expanded(flex: 1, child: Text('Scans', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.center)),
                const Expanded(flex: 1, child: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), textAlign: TextAlign.right)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...sortedEntries.map((e) {
            final count = e.value['count'] as int;
            final percentage = (count / totalScans) * 100;
            final name = e.key[0].toUpperCase() + e.key.substring(1);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(name, style: const TextStyle(color: Colors.black87))),
                  Expanded(flex: 1, child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87))),
                  Expanded(flex: 1, child: Text('${percentage.toStringAsFixed(1)}%', textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87))),
                ],
              ),
            );
          }).toList(),
          // Add dividers between rows if needed
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    if (_recentScans.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Scans (Last 10)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ..._recentScans.take(10).map((scan) {
            final label = scan['label'] as String;
            final confidence = scan['confidence'] as double;
            final timestampStr = scan['timestamp'] as String;
            final timestamp = DateTime.parse(timestampStr);
            final timeStr = DateFormat('HH:mm').format(timestamp);
            
            final name = label.isNotEmpty ? label[0].toUpperCase() + label.substring(1) : 'Unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(confidence * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
