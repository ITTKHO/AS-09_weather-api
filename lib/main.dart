import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/th_cities.dart';
import 'models/weather_models.dart';
import 'providers/weather_provider.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH');
  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider()..searchAndLoad('Chiang Mai'),
      child: const WeatherApp(),
    ),
  );
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ใส-Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});
  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final _controller = TextEditingController(text: 'Chiang Mai');

  Future<void> _showLatLonDialog() async {
    final latCtl = TextEditingController();
    final lonCtl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('โหลดจากพิกัด'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Latitude (เช่น 13.7563)'),
            ),
            TextField(
              controller: lonCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'Longitude (เช่น 100.5018)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latCtl.text.trim());
              final lon = double.tryParse(lonCtl.text.trim());
              if (lat == null || lon == null) return;
              context.read<WeatherProvider>().loadByLatLon(lat, lon);
              Navigator.pop(context);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WeatherProvider>();

    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF74EBD5), Color(0xFF9FACE6)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: prov.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Glass(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'พิมพ์ชื่อเมือง เช่น Bangkok, Chiang Mai',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (v) {
                            final q = v.trim();
                            if (q.isNotEmpty) context.read<WeatherProvider>().searchAndLoad(q);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CircleButton(
                      icon: Icons.search,
                      onTap: () {
                        final q = _controller.text.trim();
                        if (q.isNotEmpty) context.read<WeatherProvider>().searchAndLoad(q);
                      },
                    ),
                    const SizedBox(width: 12),
                    _CircleButton(
                      icon: Icons.location_searching,
                      onTap: _showLatLonDialog, // กรอกพิกัดเอง
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: thCities.take(8).map((c) {
                    return ActionChip(
                      label: Text(c),
                      onPressed: () {
                        _controller.text = c;
                        context.read<WeatherProvider>().searchAndLoad(c);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                if (prov.loading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  )),

                if (prov.error != null && !prov.loading)
                  _Glass(padding: const EdgeInsets.all(16), child: Text(prov.error!, style: const TextStyle(color: Colors.red))),

                if (prov.weather != null && !prov.loading) ...[
                  _HeaderCity(city: prov.city!),
                  const SizedBox(height: 12),
                  _CurrentWeatherCard(data: prov.weather!),
                  const SizedBox(height: 16),
                  const Text('รายชั่วโมงถัดไป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _HourlyList(hourly: prov.weather!.hourly.take(12).toList()),
                  const SizedBox(height: 16),
                  const Text('พยากรณ์ 7 วันถัดไป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _DailyList(daily: prov.weather!.daily),
                  const SizedBox(height: 24),
                  Opacity(opacity: 0.7, child: Center(child: Text('แหล่งข้อมูล: Open-Meteo'))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- UI Widgets ---------- */

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Glass({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(padding: const EdgeInsets.all(12), child: Icon(icon, size: 24)),
    );
  }
}

class _HeaderCity extends StatelessWidget {
  final City city;
  const _HeaderCity({required this.city});
  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${city.name}${city.country != null ? " • ${city.country}" : ""}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          Text('${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  final WeatherData data;
  const _CurrentWeatherCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final desc = WeatherService.describeWMO(data.weatherCode);
    final emoji = WeatherService.emojiForWMO(data.weatherCode);
    final now = DateFormat('EEE d MMM HH:mm', 'th_TH').format(DateTime.now());

    return _Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${data.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('รู้สึกเหมือน: ${data.apparent.toStringAsFixed(1)}°C'),
                  Text('ความชื้น: ${data.humidity.toStringAsFixed(0)}%'),
                  Text('ลม: ${data.windSpeed.toStringAsFixed(0)} km/h'),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Opacity(opacity: 0.8, child: Text('อัปเดต: $now')),
        ],
      ),
    );
  }
}

class _HourlyList extends StatelessWidget {
  final List<HourlyForecast> hourly;
  const _HourlyList({required this.hourly});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // ป้องกันล้น
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final h = hourly[i];
          final t = DateFormat('HH:mm').format(h.time);
          final emoji = WeatherService.emojiForWMO(h.weatherCode);
          return SizedBox(
            width: 120,
            child: _Glass(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text('${h.temp.toStringAsFixed(0)}°C'),
                  Opacity(
                    opacity: 0.8,
                    child: Text('ฝน ${h.precipProb} %', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DailyList extends StatelessWidget {
  final List<DailyForecast> daily;
  const _DailyList({required this.daily});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: daily.take(7).map((d) {
        final emoji = WeatherService.emojiForWMO(d.weatherCode);
        final day = DateFormat('EEE d MMM', 'th_TH').format(d.date);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _Glass(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(day)),
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('${d.tempMin.toStringAsFixed(0)}° / ${d.tempMax.toStringAsFixed(0)}°C'),
                const SizedBox(width: 8),
                Opacity(
                  opacity: 0.8,
                  child: Text('ฝน ${d.rainSum.toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
