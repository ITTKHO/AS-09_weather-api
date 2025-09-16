import 'package:flutter/foundation.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  City? city;
  WeatherData? weather;
  bool loading = false;
  String? error;

  Future<void> searchAndLoad(String name) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final c = await WeatherService.searchCity(name);
      if (c == null) {
        error = 'ไม่พบเมือง: $name';
        weather = null;
        city = null;
      } else {
        city = c;
        weather = await WeatherService.fetchWeather(c.latitude, c.longitude);
      }
    } catch (e) {
      error = 'เกิดข้อผิดพลาด: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (city == null) return;
    return searchAndLoad(city!.name);
  }

  /// ✅ ค้นหาด้วยพิกัด lat/lon
  Future<void> loadByLatLon(double lat, double lon) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // ดึงพยากรณ์โดยตรง ไม่ต้องผ่าน geocoding
      weather = await WeatherService.fetchWeather(lat, lon);
      city = City(
        name: 'Lat:${lat.toStringAsFixed(2)}, Lon:${lon.toStringAsFixed(2)}',
        latitude: lat,
        longitude: lon,
      );
    } catch (e) {
      error = 'เกิดข้อผิดพลาด: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}