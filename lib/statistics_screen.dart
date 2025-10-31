import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _easyCompleted = 0;
  int _mediumCompleted = 0;
  int _hardCompleted = 0;
  int _bestEasy = 0;
  int _bestMedium = 0;
  int _bestHard = 0;
  int _bestExpert = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _easyCompleted = prefs.getInt('easyCompleted') ?? 0;
      _mediumCompleted = prefs.getInt('mediumCompleted') ?? 0;
      _hardCompleted = prefs.getInt('hardCompleted') ?? 0;
      _bestEasy = prefs.getInt('best_easy') ?? 0;
      _bestMedium = prefs.getInt('best_medium') ?? 0;
      _bestHard = prefs.getInt('best_hard') ?? 0;
      _bestExpert = prefs.getInt('best_expert') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puzzles Completed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_getHighestCompletedCount() + 5).toDouble(),
                  barTouchData: const BarTouchData(
                    enabled: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          );
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Easy';
                              break;
                            case 1:
                              text = 'Medium';
                              break;
                            case 2:
                              text = 'Hard';
                              break;
                            default:
                              text = '';
                              break;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) {
                      return const FlLine(
                        color: Colors.grey,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Best Scores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreColumn('Easy', _bestEasy),
                _buildScoreColumn('Medium', _bestMedium),
                _buildScoreColumn('Hard', _bestHard),
                _buildScoreColumn('Expert', _bestExpert, isLocked: _bestExpert == 0),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Coming Soon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Streak History and Puzzle Accuracy will be available in a future update.'),
          ],
        ),
      ),
    );
  }

  double _getHighestCompletedCount() {
    final counts = [_easyCompleted, _mediumCompleted, _hardCompleted];
    if (counts.every((element) => element == 0)) {
      return 5;
    }
    return counts.reduce((a, b) => a > b ? a : b).toDouble();
  }

  List<BarChartGroupData> _buildBarGroups() {
    return [
      _buildBarChartGroupData(0, _easyCompleted.toDouble()),
      _buildBarChartGroupData(1, _mediumCompleted.toDouble()),
      _buildBarChartGroupData(2, _hardCompleted.toDouble()),
    ];
  }

  BarChartGroupData _buildBarChartGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blue,
          width: 22,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildScoreColumn(String title, int score, {bool isLocked = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(isLocked ? '—' : score.toString()),
      ],
    );
  }
}
