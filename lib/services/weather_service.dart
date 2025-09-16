import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class WeatherService {
  /// ค้นหาเมือง
  static Future<City?> searchCity(String name) async {
    final url = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeComponent(name)}&count=1&language=th&format=json',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('ค้นหาเมืองล้มเหลว');
    final data = jsonDecode(res.body);
    final list = (data?['results'] as List?) ?? [];
    if (list.isEmpty) return null;
    final r = list.first;
    return City(
      name: r['name'] ?? '',
      country: r['country'],
      latitude: (r['latitude'] as num).toDouble(),
      longitude: (r['longitude'] as num).toDouble(),
    );
  }

  /// ดึงข้อมูลพยากรณ์
  static Future<WeatherData> fetchWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m'
      '&hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability,wind_speed_10m'
      '&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum'
      '&timezone=auto',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('ดึงพยากรณ์ล้มเหลว');
    final data = jsonDecode(res.body);

    // ---------------- Hourly ----------------
    final hourly = (data['hourly'] as Map?) ?? {};
    final times = (hourly['time'] as List? ?? []).cast<String>();
    final temps = (hourly['temperature_2m'] as List? ?? []).cast<num>();
    final codes = (hourly['weather_code'] as List? ?? []).cast<num>();
    final precs = (hourly['precipitation_probability'] as List? ?? []).cast<num>();
    final winds = (hourly['wind_speed_10m'] as List? ?? []).cast<num>();
    final apparents = (hourly['apparent_temperature'] as List? ?? []).cast<num>();

    final list = <HourlyForecast>[];
    final n = [times.length, temps.length, codes.length, precs.length, winds.length, apparents.length]
        .reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < n; i++) {
      list.add(HourlyForecast(
        time: DateTime.parse(times[i]),
        temp: temps[i].toDouble(),
        weatherCode: codes[i].toInt(),
        precipProb: precs[i].toInt(),
        wind: winds[i].toDouble(),
        apparent: apparents[i].toDouble(),
      ));
    }

    // ---------------- Daily ----------------
    final daily = (data['daily'] as Map?) ?? {};
    final dTimes = (daily['time'] as List? ?? []).cast<String>();
    final dMax = (daily['temperature_2m_max'] as List? ?? []).cast<num>();
    final dMin = (daily['temperature_2m_min'] as List? ?? []).cast<num>();
    final dCode = (daily['weather_code'] as List? ?? []).cast<num>();
    final dRain = (daily['precipitation_sum'] as List? ?? []).cast<num>();

    final dailyList = <DailyForecast>[];
    final dn = [dTimes.length, dMax.length, dMin.length, dCode.length, dRain.length]
        .reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < dn; i++) {
      dailyList.add(DailyForecast(
        date: DateTime.parse(dTimes[i]),
        tempMax: dMax[i].toDouble(),
        tempMin: dMin[i].toDouble(),
        weatherCode: dCode[i].toInt(),
        rainSum: dRain[i].toDouble(),
      ));
    }

    final current = (data['current'] as Map?) ?? {};
    return WeatherData(
      temperature: (current['temperature_2m'] as num? ?? 0).toDouble(),
      humidity: (current['relative_humidity_2m'] as num? ?? 0).toDouble(),
      apparent: (current['apparent_temperature'] as num? ?? 0).toDouble(),
      weatherCode: (current['weather_code'] as num? ?? 0).toInt(),
      windSpeed: (current['wind_speed_10m'] as num? ?? 0).toDouble(),
      isDay: (current['is_day'] as num? ?? 1) == 1,
      hourly: list,
      daily: dailyList,
    );
  }

  /// อธิบาย WMO code
  static String describeWMO(int code) {
    const map = {
      0: 'ท้องฟ้าแจ่มใส',
      1: 'แดดบางส่วน',
      2: 'เมฆเป็นบางส่วน',
      3: 'เมฆมาก',
      45: 'หมอก',
      51: 'ฝนปรอย',
      61: 'ฝนเล็กน้อย',
      63: 'ฝนปานกลาง',
      65: 'ฝนหนัก',
      71: 'หิมะ',
      80: 'ฝนซู่',
      95: 'พายุฝนฟ้าคะนอง',
    };
    return map[code] ?? 'ไม่ทราบ';
  }

  static String emojiForWMO(int code) {
    if (code == 0) return '☀️';
    if ([1, 2].contains(code)) return '🌤️';
    if (code == 3) return '☁️';
    if ({51,61,63,65,80}.contains(code)) return '🌧️ ';
    if ({95}.contains(code)) return '⛈️';
    if ({71}.contains(code)) return '❄️';
    if ({45}.contains(code)) return '🌫️';
    return '🌡️';
  }
}
