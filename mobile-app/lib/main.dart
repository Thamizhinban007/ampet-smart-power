// ======================================================
// AMPET BACKEND CONFIGURATION
// EDIT ONLY THIS SECTION WHEN CHANGING SERVER/API
// ======================================================

// ********************************************************
// IMPORTANT:
// IF THE FLASK SERVER IP OR API READ ENDPOINT CHANGES,
// EDIT THIS BACKEND CONFIGURATION SECTION ONLY.
// DO NOT MODIFY THE UI OR ENERGY CALCULATION CODE.
// ********************************************************

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ======================================================
// APP CONSTANTS - BACKEND CONFIGURATION
// ======================================================

const String serverIp = "10.107.173.35";
const String serverPort = "5000";

const String consumerDataEndpoint =
    "/REPLACE_WITH_EXISTING_GET_ENDPOINT";

const String consumerDataUrl =
    "http://$serverIp:$serverPort$consumerDataEndpoint";

// ======================================================
// APP RUNTIME CONSTANTS
// ======================================================

const Duration refreshInterval = Duration(seconds: 2);
const int maxHistoryEntries = 30;
const int httpTimeoutSeconds = 5;

const double defaultTariff = 7.0;
const double defaultHighUsageThreshold = 1000.0;
const double lowUsageThreshold = 200.0;
const double moderateUsageThreshold = 500.0;

const double defaultVoltage = 230.0;
const double defaultCurrent = 0.0;
const double defaultPower = 0.0;
const double defaultEnergy = 0.0;

// ======================================================
// APP COLORS
// ======================================================

abstract class AppColors {
  static const Color background = Color(0xFF0B0F19);
  static const Color card = Color(0xFF151B28);
  static const Color cardLight = Color(0xFF1C2438);
  static const Color cardElevated = Color(0xFF222B42);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFFB347);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF29B6F6);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textTertiary = Color(0xFF5A6577);
  static const Color divider = Color(0xFF2A3444);
}

// ======================================================
// DATA MODEL
// ======================================================

class ConsumerData {
  final double voltage;
  final double current;
  final double power;
  final double energy;
  final String status;
  final String theft;
  final DateTime timestamp;

  ConsumerData({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.status,
    required this.theft,
    required this.timestamp,
  });

  factory ConsumerData.fromJson(Map<String, dynamic> json) {
    return ConsumerData(
      voltage: _parseDouble(json['voltage'], defaultVoltage),
      current: _parseDouble(json['current'], defaultCurrent),
      power: _parseDouble(json['power'], defaultPower),
      energy: _parseDouble(json['energy'], defaultEnergy),
      status: json['status'] is String ? json['status'] : 'UNKNOWN',
      theft: json['theft'] is String ? json['theft'] : 'UNKNOWN',
      timestamp: DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }
}

// ======================================================
// API SERVICE
// ======================================================

class APIService {
  static Future<ConsumerData?> fetchConsumerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('server_ip') ?? serverIp;
      final port = prefs.getString('server_port') ?? serverPort;
      final endpoint = prefs.getString('consumer_endpoint') ??
          consumerDataEndpoint;
      final url = 'http://$ip:$port$endpoint';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: httpTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ConsumerData.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// ======================================================
// PREFERENCES HELPER
// ======================================================

class PrefsHelper {
  static SharedPreferences? _instance;

  static Future<SharedPreferences> get instance async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
  }

  static Future<void> setServerIp(String ip) => _setStr('server_ip', ip);
  static Future<String> getServerIp() async =>
      (await instance).getString('server_ip') ?? serverIp;

  static Future<void> setServerPort(String port) =>
      _setStr('server_port', port);
  static Future<String> getServerPort() async =>
      (await instance).getString('server_port') ?? serverPort;

  static Future<void> setConsumerEndpoint(String ep) =>
      _setStr('consumer_endpoint', ep);
  static Future<String> getConsumerEndpoint() async =>
      (await instance).getString('consumer_endpoint') ??
      consumerDataEndpoint;

  static Future<void> setTariff(double value) => _setDbl('tariff', value);
  static Future<double> getTariff() async {
    final v = (await instance).getDouble('tariff');
    return v ?? defaultTariff;
  }

  static Future<void> setRefreshInterval(int seconds) =>
      _setInt('refresh_interval', seconds);
  static Future<int> getRefreshInterval() async {
    final v = (await instance).getInt('refresh_interval');
    return v ?? 2;
  }

  static Future<void> setHighUsageThreshold(double value) =>
      _setDbl('high_usage_threshold', value);
  static Future<double> getHighUsageThreshold() async {
    final v = (await instance).getDouble('high_usage_threshold');
    return v ?? defaultHighUsageThreshold;
  }

  static Future<void> setDailyBaseline(double value) =>
      _setDbl('daily_baseline', value);
  static Future<double> getDailyBaseline() async {
    final v = (await instance).getDouble('daily_baseline');
    return v ?? 0.0;
  }

  static Future<void> setDailyBaselineDate(String date) =>
      _setStr('daily_baseline_date', date);
  static Future<String> getDailyBaselineDate() async =>
      (await instance).getString('daily_baseline_date') ?? '';

  static Future<void> setMonthlyBaseline(double value) =>
      _setDbl('monthly_baseline', value);
  static Future<double> getMonthlyBaseline() async {
    final v = (await instance).getDouble('monthly_baseline');
    return v ?? 0.0;
  }

  static Future<void> setMonthlyBaselineMonth(String month) =>
      _setStr('monthly_baseline_month', month);
  static Future<String> getMonthlyBaselineMonth() async =>
      (await instance).getString('monthly_baseline_month') ?? '';

  static Future<void> setLastEnergy(double value) =>
      _setDbl('last_energy', value);
  static Future<double> getLastEnergy() async {
    final v = (await instance).getDouble('last_energy');
    return v ?? 0.0;
  }

  static Future<void> setHasRan() => _setBool('has_ran', true);
  static Future<bool> getHasRan() async =>
      (await instance).getBool('has_ran') ?? false;

  static Future<void> setHistoryList(List<Map<String, dynamic>> list) async {
    final jsonList = list.map((e) => jsonEncode(e)).toList();
    await (await instance).setStringList('history', jsonList);
  }

  static Future<List<Map<String, dynamic>>> getHistoryList() async {
    final strings = (await instance).getStringList('history') ?? [];
    return strings.map<Map<String, dynamic>>((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }).toList();
  }

  static Future<void> _setStr(String key, String value) async =>
      await (await instance).setString(key, value);
  static Future<void> _setDbl(String key, double value) async =>
      await (await instance).setDouble(key, value);
  static Future<void> _setInt(String key, int value) async =>
      await (await instance).setInt(key, value);
  static Future<void> _setBool(String key, bool value) async =>
      await (await instance).setBool(key, value);
}

// ======================================================
// ENERGY CALCULATOR
// ======================================================

class EnergyCalculator {
  static Future<Map<String, double>> compute(ConsumerData data) async {
    final currentEnergy = data.energy;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    String dailyDate = await PrefsHelper.getDailyBaselineDate();
    String monthlyMonth = await PrefsHelper.getMonthlyBaselineMonth();

    double dailyBaseline = await PrefsHelper.getDailyBaseline();
    double monthlyBaseline = await PrefsHelper.getMonthlyBaseline();

    if (dailyDate != today) {
      dailyBaseline = currentEnergy;
      await PrefsHelper.setDailyBaseline(dailyBaseline);
      await PrefsHelper.setDailyBaselineDate(today);
    }

    if (monthlyMonth != currentMonth) {
      monthlyBaseline = currentEnergy;
      await PrefsHelper.setMonthlyBaseline(monthlyBaseline);
      await PrefsHelper.setMonthlyBaselineMonth(currentMonth);
    }

    double todayUsage = max(0.0, currentEnergy - dailyBaseline);
    double monthlyUsage = max(0.0, currentEnergy - monthlyBaseline);

    final lastEnergy = await PrefsHelper.getLastEnergy();
    if (currentEnergy < lastEnergy) {
      final hasRun = await PrefsHelper.getHasRan();
      if (hasRun) {
        await PrefsHelper.setDailyBaseline(currentEnergy);
        await PrefsHelper.setDailyBaselineDate(today);
        await PrefsHelper.setMonthlyBaseline(currentEnergy);
        await PrefsHelper.setMonthlyBaselineMonth(currentMonth);
        todayUsage = 0.0;
        monthlyUsage = 0.0;
      }
    }

    await PrefsHelper.setLastEnergy(currentEnergy);
    if (!await PrefsHelper.getHasRan()) {
      await PrefsHelper.setHasRan();
    }

    final tariff = await PrefsHelper.getTariff();
    final todayCost = todayUsage * tariff;
    final monthlyCost = monthlyUsage * tariff;

    return {
      'todayUsage': todayUsage,
      'monthlyUsage': monthlyUsage,
      'todayCost': todayCost,
      'monthlyCost': monthlyCost,
      'totalEnergy': currentEnergy,
    };
  }

  static Future<void> storeSnapshot(ConsumerData data) async {
    final history = await PrefsHelper.getHistoryList();
    final snapshot = {
      'energy': data.energy,
      'power': data.power,
      'timestamp': DateTime.now().toIso8601String(),
    };
    history.add(snapshot);
    if (history.length > maxHistoryEntries) {
      history.removeRange(0, history.length - maxHistoryEntries);
    }
    await PrefsHelper.setHistoryList(history);
  }
}

// ======================================================
// CHART PAINTER
// ======================================================

class EnergyChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  EnergyChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final padding = size.width * 0.1;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - 30.0;
    final barCount = values.length;
    final gap = chartWidth * 0.12;
    final barWidth = (chartWidth - gap * (barCount - 1)) / barCount;
    final maxBarHeight = chartHeight - 20.0;
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    for (var i = 0; i < values.length; i++) {
      final barHeight = max(4.0, (values[i] / safeMax) * maxBarHeight);
      final x = padding + i * (barWidth + gap);
      final y = chartHeight - barHeight;

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [AppColors.accent, AppColors.accentLight],
      );
      final barPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);
    }

    final baselinePaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(padding, chartHeight),
      Offset(size.width - padding, chartHeight),
      baselinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant EnergyChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}

// ======================================================
// REUSABLE WIDGETS
// ======================================================

class ConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final DateTime? lastUpdated;

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? AppColors.success : AppColors.danger,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isConnected
                    ? AppColors.success.withOpacity(0.4)
                    : AppColors.danger.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isConnected ? 'LIVE' : 'OFFLINE',
          style: TextStyle(
            color: isConnected ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        if (lastUpdated != null) ...[
          const SizedBox(width: 12),
          Text(
            DateFormat('HH:mm:ss').format(lastUpdated!),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double? progress;

  const HeroCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardLight, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.accentLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  backgroundColor: AppColors.cardLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color valueColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: valueColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionTitle({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const HistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final values = history
        .map((e) => (e['energy'] as num?)?.toDouble() ?? 0.0)
        .toList();

    if (values.isEmpty) {
      return EmptyState(
        message: 'Usage history will appear as the app collects data.',
      );
    }

    final maxVal = values.reduce(max);

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: EnergyChartPainter(
                values: values,
                maxValue: maxVal,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${values.length} readings',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              Text(
                'Latest: ${values.last.toStringAsFixed(2)} kWh',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// HOME SCREEN
// ======================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ConsumerData? _currentData;
  ConsumerData? _lastGoodData;
  DateTime? _lastUpdated;
  bool _isConnected = false;
  bool _isLoading = true;
  Timer? _refreshTimer;
  Map<String, double>? _energyCache;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => _isLoading = true);
    }

    final data = await APIService.fetchConsumerData();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (data != null) {
        _lastGoodData = data;
        _currentData = data;
        _isConnected = true;
        _lastUpdated = DateTime.now();
      } else {
        _isConnected = false;
        if (_lastGoodData != null) {
          _currentData = _lastGoodData;
        }
      }
    });

    if (data != null) {
      _energyCache = await EnergyCalculator.compute(data);
      final lastEnergy = await PrefsHelper.getLastEnergy();
      if ((data.energy - lastEnergy).abs() > 0.001 || lastEnergy == 0.0) {
        await EnergyCalculator.storeSnapshot(data);
      }
    }
  }

  void _startRefreshTimer() async {
    final interval = await PrefsHelper.getRefreshInterval();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: interval), (_) {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _fetchData(isRefresh: true),
      color: AppColors.accent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _isLoading && _currentData == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildHeader(),
                    if (_currentData != null) ...[
                      _buildHeroCard(),
                      _buildMetricsRow(),
                      _buildMonthlySummary(),
                      _buildStatusCards(),
                    ] else
                      _buildErrorState(),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _fetchData(isRefresh: true),
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Refresh'),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMPET Link',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Energy. Connected.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                ConnectionIndicator(
                  isConnected: _isConnected,
                  lastUpdated: _lastUpdated,
                ),
              ],
            ),
            const Divider(
              height: 20,
              thickness: 1,
              color: AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final todayUsage = _energyCache?['todayUsage'] ?? 0.0;
    final todayCost = _energyCache?['todayCost'] ?? 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: HeroCard(
          title: "TODAY'S ENERGY",
          value: '${todayUsage.toStringAsFixed(2)} kWh',
          subtitle: 'Estimated Today: \u{20B9}${todayCost.toStringAsFixed(2)}',
          progress: (todayUsage / 50.0).clamp(0.0, 1.0),
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.bolt_outlined,
                label: 'VOLTAGE',
                value: _currentData?.voltage.toStringAsFixed(1) ?? '--',
                unit: 'Volts',
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.water_drop_outlined,
                label: 'CURRENT',
                value: _currentData?.current.toStringAsFixed(2) ?? '--',
                unit: 'Amps',
                accentColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                icon: Icons.lightbulb_outline,
                label: 'POWER',
                value: _currentData?.power.toStringAsFixed(0) ?? '--',
                unit: 'Watts',
                accentColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final monthlyUsage = _energyCache?['monthlyUsage'] ?? 0.0;
    final monthlyCost = _energyCache?['monthlyCost'] ?? 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTHLY USAGE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${monthlyUsage.toStringAsFixed(1)} kWh',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED BILL',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u{20B9}${monthlyCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '(Estimated)',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            InfoCard(
              icon: Icons.power_settings_new_outlined,
              title: 'SYSTEM STATUS',
              value: _currentData?.status ?? 'UNKNOWN',
              valueColor: _currentData?.status == 'NORMAL'
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(height: 12),
            InfoCard(
              icon: Icons.visibility_outlined,
              title: 'MONITORING STATUS',
              value: _currentData?.theft ?? 'UNKNOWN',
              valueColor: _currentData?.theft == 'SAFE'
                  ? AppColors.success
                  : AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: AppColors.textTertiary, size: 64),
              const SizedBox(height: 16),
              Text(
                'Connection Lost',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your network connection and try again.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _fetchData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Retry'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// USAGE SCREEN
// ======================================================

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  Map<String, double>? _energyCache;
  ConsumerData? _currentData;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await APIService.fetchConsumerData();
    if (!mounted) return;
    setState(() => _currentData = data);
    if (data != null) {
      _energyCache = await EnergyCalculator.compute(data);
    }
    _history = await PrefsHelper.getHistoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        color: AppColors.accent, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Usage',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            if (_currentData != null && _energyCache != null) ...[
              _buildSummaryCards(),
              _buildTotalSection(),
              _buildHistorySection(),
            ] else
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final cache = _energyCache!;
    final todayUsage = cache['todayUsage'] ?? 0.0;
    final todayCost = cache['todayCost'] ?? 0.0;
    final monthlyUsage = cache['monthlyUsage'] ?? 0.0;
    final monthlyCost = cache['monthlyCost'] ?? 0.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: 'TODAY', icon: Icons.today_outlined),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Usage',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${todayUsage.toStringAsFixed(2)} kWh',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Cost',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u{20B9}${todayCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(
                title: 'THIS MONTH', icon: Icons.calendar_month_outlined),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy Usage',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${monthlyUsage.toStringAsFixed(2)} kWh',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Bill',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u{20B9}${monthlyCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '(Estimated)',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final totalEnergy = _currentData?.energy ?? 0.0;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.15),
                AppColors.card,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: AppColors.accentLight,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL CUMULATIVE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalEnergy.toStringAsFixed(2)} kWh',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: 'RECENT HISTORY'),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              EmptyState(
                message: 'Usage history will appear as the app collects data.',
              )
            else
              HistoryChart(history: _history),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// INSIGHTS SCREEN
// ======================================================

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  ConsumerData? _currentData;
  List<Map<String, dynamic>> _history = [];
  String _insightPowerLevel = '';
  String _insightDailyComparison = '';
  String _insightMonthlyEstimate = '';
  String _insightStatus = '';
  bool _showHighUsageWarning = false;
  double _highUsageThreshold = defaultHighUsageThreshold;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await APIService.fetchConsumerData();
    if (!mounted) return;
    setState(() => _currentData = data);
    if (data != null) {
      await _generateInsights(data);
      if (mounted) setState(() {});
    }
    _history = await PrefsHelper.getHistoryList();
  }

  Future<void> _generateInsights(ConsumerData data) async {
    final power = data.power;
    final tariff = await PrefsHelper.getTariff();
    final highThreshold = await PrefsHelper.getHighUsageThreshold();

    if (power < lowUsageThreshold) {
      _insightPowerLevel =
          'LOW USAGE\nYour current energy consumption is low. Great job conserving energy!';
    } else if (power < moderateUsageThreshold) {
      _insightPowerLevel =
          'MODERATE USAGE\nYour current energy consumption is moderate. Keep monitoring your usage patterns.';
    } else {
      _insightPowerLevel =
          'HIGH USAGE\nHigh power consumption detected. Consider checking connected devices and reducing load.';
    }

    _showHighUsageWarning = power >= highThreshold;
    _highUsageThreshold = highThreshold;

    if (_history.length >= 2) {
      final todayEnergy = data.energy;
      final yesterdayEnergy =
          _history[_history.length - 2]['energy'] as num? ?? 0.0;
      if (yesterdayEnergy > 0) {
        final diff =
            ((todayEnergy - yesterdayEnergy) / yesterdayEnergy * 100).toInt();
        if (diff > 10) {
          _insightDailyComparison =
              'DAILY COMPARISON\nToday\'s usage is ${diff}% higher than your previous recorded day. Consider reviewing your appliance usage.';
        } else if (diff < -10) {
          _insightDailyComparison =
              'DAILY COMPARISON\nToday\'s usage is ${diff.abs()}% lower than your previous recorded day. Excellent energy savings!';
        } else {
          _insightDailyComparison =
              'DAILY COMPARISON\nToday\'s usage is similar to your previous recorded day. Consistent consumption pattern.';
        }
      } else {
        _insightDailyComparison =
            'DAILY COMPARISON\nNot enough data to compare with previous days.';
      }
    } else {
      _insightDailyComparison =
          'DAILY COMPARISON\nCollecting more data for daily comparisons. Check back after a few readings.';
    }

    _insightMonthlyEstimate =
        'MONTHLY ESTIMATE\nAt your current usage rate, your estimated monthly cost is approximately \u{20B9}${(data.power / 1000) * 24 * 30 * tariff}.';

    if (data.status == 'NORMAL') {
      _insightStatus =
          'SYSTEM STATUS\nYour AMPET system is operating normally. All sensors reporting correctly.';
    } else {
      _insightStatus =
          'SYSTEM STATUS\nYour AMPET system reports a non-normal status. Please check monitoring.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        color: AppColors.accent, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Insights',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            if (_currentData != null) ...[
              _buildInsightsList(),
              _buildHighUsageWarning(),
            ] else
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightCard(
              Icons.bolt_outlined,
              'Power Analysis',
              _insightPowerLevel,
              AppColors.warning,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              Icons.calendar_today_outlined,
              'Usage Trend',
              _insightDailyComparison,
              AppColors.info,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              Icons.timeline_outlined,
              'Monthly Projection',
              _insightMonthlyEstimate,
              AppColors.accent,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              Icons.security_outlined,
              'System Health',
              _insightStatus,
              AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      IconData icon, String title, String content, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighUsageWarning() {
    if (_currentData == null || !_showHighUsageWarning) return const SizedBox.shrink();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  color: AppColors.danger, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HIGH USAGE WARNING',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Power consumption (${_currentData!.power.toStringAsFixed(0)} W) has exceeded your threshold of ${_highUsageThreshold.toStringAsFixed(0)} W.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// SETTINGS SCREEN
// ======================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _tariffController;
  late TextEditingController _thresholdController;
  late TextEditingController _endpointController;
  int _refreshInterval = 2;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _ipController = TextEditingController(text: await PrefsHelper.getServerIp());
    _portController = TextEditingController(text: await PrefsHelper.getServerPort());
    _tariffController = TextEditingController(
      text: (await PrefsHelper.getTariff()).toStringAsFixed(2),
    );
    _thresholdController = TextEditingController(
      text: (await PrefsHelper.getHighUsageThreshold()).toStringAsFixed(0),
    );
    _endpointController = TextEditingController(
      text: await PrefsHelper.getConsumerEndpoint(),
    );
    _refreshInterval = await PrefsHelper.getRefreshInterval();
  }

  Future<void> _saveIp() async {
    await PrefsHelper.setServerIp(_ipController.text.trim());
    if (mounted) setState(() {});
    _showSavedSnackBar();
  }

  Future<void> _savePort() async {
    await PrefsHelper.setServerPort(_portController.text.trim());
    if (mounted) setState(() {});
    _showSavedSnackBar();
  }

  Future<void> _saveTariff() async {
    final v = double.tryParse(_tariffController.text);
    if (v != null) {
      await PrefsHelper.setTariff(v);
      _showSavedSnackBar();
    }
  }

  Future<void> _saveThreshold() async {
    final v = double.tryParse(_thresholdController.text);
    if (v != null) {
      await PrefsHelper.setHighUsageThreshold(v);
      _showSavedSnackBar();
    }
  }

  Future<void> _saveEndpoint() async {
    await PrefsHelper.setConsumerEndpoint(_endpointController.text.trim());
    _showSavedSnackBar();
  }

  void _showSavedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tariffController.dispose();
    _thresholdController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined,
                        color: AppColors.accent, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _buildServerSection(),
            _buildTariffSection(),
            _buildRefreshSection(),
            _buildThresholdSection(),
            _buildEndpointSection(),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.devices_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SERVER CONFIGURATION',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingsTextField(
                controller: _ipController,
                label: 'Server IP',
                icon: Icons.network_wifi,
                keyboardType: TextInputType.url,
                onFieldSubmitted: (_) => _saveIp(),
              ),
              const SizedBox(height: 12),
              _buildSettingsTextField(
                controller: _portController,
                label: 'Port',
                icon: Icons.devices_outlined,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _savePort(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTariffSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_gas_station_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ELECTRICITY TARIFF',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cost per kWh in Indian Rupees (\u{20B9})',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTextField(
                controller: _tariffController,
                label: '\u{20B9} per kWh',
                icon: Icons.attach_money_outlined,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onFieldSubmitted: (_) => _saveTariff(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveTariff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Save Tariff'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshSection() {
    final intervals = [1, 2, 3, 5];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.refresh_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'REFRESH INTERVAL',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: intervals.map((s) {
                  final selected = _refreshInterval == s;
                  return GestureDetector(
                    onTap: () async {
                      await PrefsHelper.setRefreshInterval(s);
                      if (mounted) setState(() => _refreshInterval = s);
                      _showSavedSnackBar();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        '$s sec',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'HIGH USAGE THRESHOLD',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Power threshold in Watts for high usage warning',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTextField(
                controller: _thresholdController,
                label: 'Threshold (Watts)',
                icon: Icons.speed_outlined,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _saveThreshold(),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveThreshold,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Save Threshold'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndpointSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.code_outlined,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'API ENDPOINT',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Replace with your existing Flask GET endpoint',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsTextField(
                controller: _endpointController,
                label: 'GET Endpoint Path',
                icon: Icons.link_outlined,
                keyboardType: TextInputType.url,
                onFieldSubmitted: (_) => _saveEndpoint(),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: /get_consumer_data',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ABOUT AMPET LINK',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: AppColors.accent,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'AMPET Link',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Your Energy. Connected.',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Consumer Energy Monitoring Application',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildAboutRow('Version', '1.0.0'),
              _buildAboutRow('Protocol', 'HTTP / JSON'),
              _buildAboutRow('Platform', 'Consumer Energy Monitor'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required void Function(String)? onFieldSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        filled: true,
        fillColor: AppColors.cardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ======================================================
// MAIN APP
// ======================================================

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    UsageScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    PrefsHelper.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textTertiary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Usage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// MAIN
// ======================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsHelper.init();
  runApp(const MainApp());
}