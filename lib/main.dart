import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  // Load theme preference
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save theme preference
  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
  }

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gulwing Score Tracker',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: DrivingScoreHomePage(
        isDarkMode: isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            isDarkMode = value;
            saveTheme(value);
          });
        },
      ),
    );
  }
}

class DrivingScoreHomePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const DrivingScoreHomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<DrivingScoreHomePage> createState() => _DrivingScoreHomePageState();
}

class _DrivingScoreHomePageState extends State<DrivingScoreHomePage> {
  int drivingScore = 100;
  List<int> scoreHistory = [];

  // Save scores
  Future<void> saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    scoreHistory.add(score);
    prefs.setStringList('scoreHistory', scoreHistory.map((e) => e.toString()).toList());
  }

  // Load scores
  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScores = prefs.getStringList('scoreHistory') ?? [];
    setState(() {
      scoreHistory = savedScores.map((e) => int.parse(e)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  // Simulate driving score
  void simulateDrive() {
    final Random random = Random();
    int harshBrakes = random.nextInt(6);
    int rapidAcceleration = random.nextInt(6);
    int speedOverLimit = random.nextInt(11);

    int newScore = 100 - (harshBrakes * 2) - (rapidAcceleration * 2) - (speedOverLimit * 3);
    newScore = newScore.clamp(0, 100);

    setState(() {
      drivingScore = newScore;
      saveScore(newScore);
    });
  }

  // Build the chart
  Widget buildChart() {
    if (scoreHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No score data available yet!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: scoreHistory.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.blue,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // Build score stats
  Widget buildScoreStats() {
    if (scoreHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'No previous scores yet!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    int highestScore = scoreHistory.reduce(max);
    int lowestScore = scoreHistory.reduce(min);
    double averageScore = scoreHistory.reduce((a, b) => a + b) / scoreHistory.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildStatBox('Highest Score', highestScore.toString()),
        buildStatBox('Lowest Score', lowestScore.toString()),
        buildStatBox('Average Score', averageScore.toStringAsFixed(2)),
      ],
    );
  }

  // Build stat box
  Widget buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  // Build data grid
  Widget buildDataGrid() {
    if (scoreHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No previous scores yet!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: scoreHistory.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent),
            ),
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                'Score: ${scoreHistory[index]}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text(
          'GULWING SCORE TRACKER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          Row(
            children: [
              const Text(
                'Dark Mode',
                style: TextStyle(color: Colors.white),
              ),
              Switch(
                value: widget.isDarkMode,
                onChanged: (value) {
                  widget.onThemeChanged(value);
                },
              ),
            ],
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Fix height to full screen
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 10),
              const Text(
                'Your Current Driving Score:',
                style: TextStyle(fontSize: 20, color: Colors.blueAccent),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$drivingScore',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: drivingScore >= 70 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: simulateDrive,
                child: const Text(
                  'Simulate Drive',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              buildChart(),
              const SizedBox(height: 20),
              buildScoreStats(),
              const SizedBox(height: 20),
              const Text(
                'PREVIOUS SCORES:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: buildDataGrid(),
                ),
              ),
              const SizedBox(height: 20), // Small padding at bottom
            ],
          ),
        ),
      ),
    );
  }
}
