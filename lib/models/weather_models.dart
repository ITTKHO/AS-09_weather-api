class City {
  final String name;
  final String? country;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    this.country,
    required this.latitude,
    required this.longitude,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temp;
  final int weatherCode;
  final int precipProb;
  final double wind;
  final double apparent;

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.weatherCode,
    required this.precipProb,
    required this.wind,
    required this.apparent,
  });
}

/// ✅ เพิ่มพยากรณ์รายวัน
class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final double rainSum;

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.rainSum,
  });
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double apparent;
  final int weatherCode;
  final double windSpeed;
  final bool isDay;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily; // ✅ เพิ่มรายวัน

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.apparent,
    required this.weatherCode,
    required this.windSpeed,
    required this.isDay,
    required this.hourly,
    required this.daily,
  });
}
