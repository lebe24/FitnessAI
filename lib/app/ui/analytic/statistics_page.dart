import 'package:animate_do/animate_do.dart';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/core/di.dart';
import 'package:fitness/app/ui/auth/domain/usecase/get_current_user.dart';
import 'package:fitness/app/ui/fitness/domain/usecases/get_user_data_usecase.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({ Key? key }) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final GetUserDataUsecase _getUserDataUsecase = sl<GetUserDataUsecase>();
  final GetCurrentUser _getCurrentUser = sl<GetCurrentUser>();

  List<FlSpot> _daylySpots = [];
  List<FlSpot> _monthlySpots = [];
  List<FlSpot> _yearlySpots = [];
  
  double _totalDuration = 0.0;
  double _workoutPercentage = 0.0;
  bool _isLoading = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible again
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _getCurrentUser();
      if (user?.id != null) {
        final userDataList = await _getUserDataUsecase(user!.id);
        
        if (userDataList.isNotEmpty) {
          // Get the latest user data record (should be single row per user)
          final userData = userDataList.first;
          
          // Extract date_n_duration array
          List<Map<String, dynamic>> workoutEntries = [];
          if (userData['date_n_duration'] != null && userData['date_n_duration'] is List) {
            final dateNDurationArray = userData['date_n_duration'] as List;
            for (var entry in dateNDurationArray) {
              if (entry is Map<String, dynamic> && entry['date'] != null && entry['duration'] != null) {
                workoutEntries.add(entry);
              }
            }
          }

          // Sort by date
          workoutEntries.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['date']);
              final dateB = DateTime.parse(b['date']);
              return dateA.compareTo(dateB);
            } catch (e) {
              return 0;
            }
          });

          // Calculate total duration
          _totalDuration = workoutEntries.fold(0.0, (sum, entry) {
            final duration = (entry['duration'] as num?)?.toDouble() ?? 0.0;
            return sum + duration;
          });

          // Calculate workout percentage (unique workout days / days elapsed this month)
          final now = DateTime.now();
          final daysElapsedInMonth = now.day;
          
          // Count unique workout days
          final uniqueWorkoutDates = <String>{};
          for (var entry in workoutEntries) {
            try {
              final entryDate = DateTime.parse(entry['date']);
              final dateKey = '${entryDate.year}-${entryDate.month}-${entryDate.day}';
              uniqueWorkoutDates.add(dateKey);
            } catch (e) {
              continue;
            }
          }
          
          _workoutPercentage = daysElapsedInMonth > 0
              ? (uniqueWorkoutDates.length / daysElapsedInMonth * 100).clamp(0.0, 100.0)
              : 0.0;

          // Generate chart spots
          _generateChartSpots(workoutEntries);
        }
      }
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateChartSpots(List<Map<String, dynamic>> workoutEntries) {
    if (workoutEntries.isEmpty) {
      _daylySpots = [];
      _monthlySpots = [];
      _yearlySpots = [];
      return;
    }

    final now = DateTime.now();
    
    // Daily spots (last 31 days)
    _daylySpots = _generateDailySpots(workoutEntries, now);
    
    // Monthly spots (last 12 months)
    _monthlySpots = _generateMonthlySpots(workoutEntries, now);
    
    // Yearly spots (last 12 months by month)
    _yearlySpots = _generateYearlySpots(workoutEntries, now);
  }

  List<FlSpot> _generateDailySpots(List<Map<String, dynamic>> entries, DateTime now) {
    final spots = <FlSpot>[];
    
    // Group workouts by date and sum durations for each date
    final workoutDaysMap = <String, double>{};
    
    for (var entry in entries) {
      try {
        final entryDate = DateTime.parse(entry['date']);
        final dateKey = '${entryDate.year}-${entryDate.month}-${entryDate.day}';
        final duration = (entry['duration'] as num?)?.toDouble() ?? 0.0;
        
        // Sum durations for the same day
        workoutDaysMap[dateKey] = (workoutDaysMap[dateKey] ?? 0.0) + duration;
      } catch (e) {
        continue;
      }
    }
    
    // Sort workout days by date
    final sortedWorkoutDays = workoutDaysMap.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse('${a.key}T00:00:00');
          final dateB = DateTime.parse('${b.key}T00:00:00');
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });
    
    // Create spots with sequential day numbers (1, 2, 3...)
    for (int i = 0; i < sortedWorkoutDays.length; i++) {
      final dayNumber = i + 1; // Start from day 1
      final duration = sortedWorkoutDays[i].value;
      spots.add(FlSpot(dayNumber.toDouble(), duration));
    }
    
    return spots;
  }

  List<FlSpot> _generateMonthlySpots(List<Map<String, dynamic>> entries, DateTime now) {
    final spots = <FlSpot>[];
    final last12Months = List.generate(12, (i) {
      final monthDate = DateTime(now.year, now.month - (11 - i), 1);
      return monthDate;
    });
    
    for (int i = 0; i < last12Months.length; i++) {
      final monthDate = last12Months[i];
      double totalDuration = 0.0;
      
      for (var entry in entries) {
        try {
          final entryDate = DateTime.parse(entry['date']);
          if (entryDate.year == monthDate.year && entryDate.month == monthDate.month) {
            totalDuration += (entry['duration'] as num?)?.toDouble() ?? 0.0;
          }
        } catch (e) {
          continue;
        }
      }
      
      spots.add(FlSpot(i.toDouble(), totalDuration));
    }
    
    return spots;
  }

  List<FlSpot> _generateYearlySpots(List<Map<String, dynamic>> entries, DateTime now) {
    // Same as monthly for yearly view
    return _generateMonthlySpots(entries, now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff0E1117),
      
      body: SafeArea(
        child: Container(
          child: Column(
            children: <Widget>[
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    
                    child: AppWidgets.appLogo()),
                  Text(
                    ': ANALYTIC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
                           ),
             ),
              Spacer(),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          from: 30,
                          child: Text(
                            '${_totalDuration.toStringAsFixed(0)} min',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.blueGrey.shade100,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          from: 30,
                          child: Text(
                            '${_workoutPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              color: _workoutPercentage >= 50 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                SizedBox(height: 100),
                _isLoading
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : FadeInUp(
                        duration: Duration(milliseconds: 1000),
                        from: 60,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: LineChart(
                            mainData(),
                            curve: Curves.easeInOutCubic,
                            duration: Duration(milliseconds: 1000),
                          ),
                        ),
                      ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  height: MediaQuery.of(context).size.height * 0.3,
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _currentIndex == 0 ? Color(0xff161b22) : Color(0xff161b22).withOpacity(0.0),
                          ),
                          child: Text("D", style: TextStyle(color: _currentIndex == 0 ? Colors.blueGrey.shade200 : Colors.blueGrey, fontSize: 20),),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _currentIndex == 1 ? Color(0xff161b22) : Color(0xff161b22).withOpacity(0.0),
                          ),
                          child: Text("M", style: TextStyle(color: _currentIndex == 1 ? Colors.blueGrey.shade200 : Colors.blueGrey, fontSize: 20),),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 2;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _currentIndex == 2 ? Color(0xff161b22) : Color(0xff161b22).withOpacity(0.0),
                          ),
                          child: Text("Y", style: TextStyle(color: _currentIndex == 2 ? Colors.blueGrey.shade200 : Colors.blueGrey, fontSize: 20),),
                        ),
                      ),
                    ],
                  )
                ),
              Spacer(flex: 1),
            ]
          ),
        ),
      )
    );
  }

  // Charts Data
  List<Color> gradientColors = [
    const Color(0xffe68823),
    const Color(0xffe68823),
  ];

  LineChartData mainData() {
    return LineChartData(
      borderData: FlBorderData(
        show: false,
      ),
      gridData: FlGridData(
        show: false,
        horizontalInterval: 1.6,
        drawVerticalLine: false
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: _currentIndex == 0 
                ? (_daylySpots.isNotEmpty ? ((_daylySpots.last.x / 5).ceil().toDouble()).clamp(1.0, double.infinity) : 1.0)
                : 1.0,
            getTitlesWidget: (value, meta) {
              if (_currentIndex == 0) {
                // Daily view - show day numbers (1, 2, 3...)
                final dayNumber = value.toInt();
                // Only show labels for valid day numbers (1 and above)
                if (dayNumber >= 1) {
                  return Text(
                    'Day $dayNumber',
                    style: const TextStyle(
                      color: Color(0xff68737d),
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  );
                }
              } else {
                // Monthly/Yearly view - show month names
                final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                               'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                final index = value.toInt();
                if (index >= 0 && index < months.length) {
                  return Text(
                    months[index],
                    style: const TextStyle(
                      color: Color(0xff68737d),
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  );
                }
              }
              return Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _getMaxY() > 0 ? (_getMaxY() / 4).clamp(10.0, double.infinity) : 10.0,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.round()}m',
                style: const TextStyle(
                  color: Color(0xff67727d),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      minX: _currentIndex == 0 ? 1.0 : 0.0,
      maxX: _currentIndex == 0 
          ? (_daylySpots.isNotEmpty ? _daylySpots.last.x : 10.0)
          : _currentIndex == 1 
              ? (_monthlySpots.isNotEmpty ? (_monthlySpots.length - 1).toDouble() : 11.0)
              : _currentIndex == 2 
                  ? (_yearlySpots.isNotEmpty ? (_yearlySpots.length - 1).toDouble() : 11.0)
                  : 30.0,
      minY: 0,
      maxY: _getMaxY(),
      lineTouchData: LineTouchData(
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            final colorList = [Colors.black, Colors.black];
            final safeIndex = index < colorList.length ? index : 0;
            return TouchedSpotIndicatorData(
              FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 2,
                dashArray: [3, 3],
              ),
              FlDotData(
                show: false,
                getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 8,
                    color: colorList[safeIndex],
                    strokeWidth: 2,
                    strokeColor: Colors.black,
                  ),
              ),
            );
          }).toList();
        },
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipPadding: const EdgeInsets.all(8),
          // tooltipBgColor: Color(0xff2e3747).withOpacity(0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              return LineTooltipItem(
                '${touchedSpot.y.round()} min',
                const TextStyle(color: Colors.white, fontSize: 12.0),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _currentIndex == 0 
              ? _daylySpots 
              : _currentIndex == 1 
                  ? _monthlySpots 
                  : _yearlySpots,
          isCurved: true,
          color: gradientColors[0],
          barWidth: 2,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xffe68823).withOpacity(0.1),
                Color(0xffe68823).withOpacity(0),
              ],
            ),
          ),
        )
      ],
    );
  }

  double _getMaxY() {
    List<FlSpot> currentSpots = _currentIndex == 0 
        ? _daylySpots 
        : _currentIndex == 1 
            ? _monthlySpots 
            : _yearlySpots;
    
    if (currentSpots.isEmpty) return 100.0;
    
    final maxDuration = currentSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Add 20% padding and round up to nearest 10
    final calculatedMax = ((maxDuration * 1.2) / 10).ceil() * 10.0;
    // Ensure minimum value to avoid division by zero in interval calculation
    return calculatedMax > 0 ? calculatedMax : 100.0;
  }
}