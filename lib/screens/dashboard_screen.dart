import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<Map<String, dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchWellbeingData();
  }

  Future<Map<String, dynamic>> _fetchWellbeingData() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Fetch up to 30 logs ordered by date
    final response = await Supabase.instance.client
        .from('wellbeing_logs')
        .select('created_at, mood_rating')
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(30) as List; // Cast to List for type safety

    if (response.isEmpty) {
      return {'spots': <FlSpot>[], 'dates': <DateTime>[]};
    }

    final List<FlSpot> spots = [];
    final List<DateTime> dates = [];
    for (var i = 0; i < response.length; i++) {
      final log = response[i];
      double rating = log['mood_rating'].toDouble();
      spots.add(FlSpot(i.toDouble(), rating));
      dates.add(DateTime.parse(log['created_at']));
    }

    // Ensure at least two points for the chart to draw if only one log exists
    if (spots.length == 1) {
      spots.add(FlSpot(1, spots[0].y));
      dates.add(dates[0].add(const Duration(days: 1)));
    }

    return {'spots': spots, 'dates': dates};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final spots = snapshot.data?['spots'] as List<FlSpot>?;
          final dates = snapshot.data?['dates'] as List<DateTime>?;

          if (spots == null || spots.isEmpty || dates == null || dates.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No well-being data yet. Add a check-in to see your progress!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your 30-Day Mood Trend',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              String text;
                              switch (value.toInt()) {
                                case 1: text = '1'; break;
                                case 2: text = '2'; break;
                                case 3: text = '3'; break;
                                case 4: text = '4'; break;
                                case 5: text = '5'; break;
                                default: return Container();
                              }
                              return Text(text, style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (spots.length / 2).toDouble() == 0 ? 1 : (spots.length / 2).toDouble(),
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= dates.length) return Container();
                              final date = dates[value.toInt()];
                              return Text(DateFormat('d MMM').format(date), style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (LineBarSpot spot) => Colors.blueGrey,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                'Mood: ${spot.y.toInt()}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.white12)),
                      minY: 1,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.blue],
                          ),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [Colors.cyan.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}