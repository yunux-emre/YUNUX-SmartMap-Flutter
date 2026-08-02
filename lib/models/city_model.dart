import 'package:equatable/equatable.dart';

class City extends Equatable {
  final String name;
  final String lat;
  final String lon;

  const City({required this.name, required this.lat, required this.lon});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      lat: json['latitude'].toString(),
      lon: json['longitude'].toString(),
    );
  }

  City copyWith({String? name, String? lat, String? lon}) {
    return City(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  List<Object?> get props => [name, lat, lon];
}

class RouteCity extends Equatable {
  final String name;
  final String lat;
  final String lon;
  final String weather;
  final double temperature;

  const RouteCity({
    required this.name,
    required this.lat,
    required this.lon,
    required this.weather,
    required this.temperature,
  });

  factory RouteCity.fromJson(Map<String, dynamic> json) {
    return RouteCity(
      name: json['name'],
      lat: json['latitude'].toString(),
      lon: json['longitude'].toString(),
      temperature: json['temperature'],
      weather: json['weather'],
    );
  }

  RouteCity copyWith({
    String? name,
    String? lat,
    String? lon,
    double? temperature,
    String? weather,
  }) {
    return RouteCity(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      temperature: temperature ?? this.temperature,
      weather: weather ?? this.weather,
    );
  }

  @override
  List<Object?> get props => [
        name,
        lat,
        lon,
        temperature,
        weather,
      ];
}
