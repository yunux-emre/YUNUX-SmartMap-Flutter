import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smart_routes/models/city_model.dart';
import 'package:smart_routes/models/road_incident_model.dart';
import 'package:http/http.dart' as http;

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  RouteBloc(this._firestore, this._firebaseAuth)
      : super(RouteState.initial()) {
    on<RouteInitial>(
      (event, emit) async {
        final fileData = await rootBundle.loadString('datas/cities.json');
        final jsonData = json.decode(fileData) as List;

        final List<City> cities =
            jsonData.map((e) => City.fromJson(e)).toList();

        emit(RouteState.initial());
        emit(state.copyWith(cities: cities));
      },
    );
    on<RouteFirstCitySelected>(
      (event, emit) async {
        emit(state.copyWith(firstCity: event.city));
      },
    );
    on<RouteSecondCitySelected>(
      (event, emit) async {
        emit(state.copyWith(secondCity: event.city));
      },
    );
    on<RouteNavigate>(
      (event, emit) async {
        assert(state.isReadyToNavigate);

        final startLat = state.firstCity!.lat;
        final startLng = state.firstCity!.lon;

        final endLat = state.secondCity!.lat;
        final endLng = state.secondCity!.lon;
        final routeName = "${state.firstCity!.name} - ${state.secondCity!.name}";

        final routesUrl =
            "https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson";

        final response = await http.get(
          Uri.parse(routesUrl),
          headers: {'User-Agent': 'SmartRoutes/1.0'},
        );
        if (response.statusCode != 200) {
          return;
        }

        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final routes = jsonData['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          return;
        }

        final firstRoute = routes[0] as Map<String, dynamic>;
        final coordinates = firstRoute['geometry']['coordinates'] as List;

        final double distanceKm = ((firstRoute['distance'] as num?) ?? 0) / 1000.0;
        final double durationMinutes = ((firstRoute['duration'] as num?) ?? 0) / 60.0;

        List<RoadIncident> incidents = [];
        try {
          final incidentsSnapshot = await _firestore
              .collection('incidents')
              .where('routeName', isEqualTo: routeName)
              .get();

          incidents = incidentsSnapshot.docs
              .map((doc) => RoadIncident.fromMap(doc.data(), doc.id))
              .toList();
        } catch (e) {
          debugPrint('Firestore incidents error: $e');
        }

        emit(state.copyWith(
          routeCoordinates: coordinates,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          incidents: incidents,
        ));

        final length = coordinates.length;
        List<List<dynamic>> sampledCoords = [];
        if (length <= 5) {
          sampledCoords = coordinates.cast<List<dynamic>>();
        } else {
          final step = (length - 1) / 4;
          for (var i = 0; i < 5; i++) {
            final idx = (i * step).round().clamp(0, length - 1);
            sampledCoords.add(coordinates[idx]);
          }
        }

        List<RouteCity> routeCities = [];

        for (var i = 0; i < sampledCoords.length; i++) {
          final lat = sampledCoords[i][1];
          final lon = sampledCoords[i][0];

          String cityName;
          if (i == 0) {
            cityName = state.firstCity!.name;
          } else if (i == sampledCoords.length - 1) {
            cityName = state.secondCity!.name;
          } else {
            final url =
                "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json";

            try {
              final response = await http.get(
                Uri.parse(url),
                headers: {
                  'User-Agent': 'SmartRoutes/1.0 (contact@smartroutes.local)',
                  'Accept-Language': 'tr',
                },
              );

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body) as Map<String, dynamic>;
                final address = jsonData['address'] as Map<String, dynamic>?;
                final province = (address?['city'] ?? address?['province'] ?? address?['state']) as String?;
                final district = (address?['town'] ?? address?['district'] ?? address?['county']) as String?;

                String cleanProvince = (province ?? '')
                    .replaceAll(' İli', '')
                    .replaceAll(' ili', '')
                    .replaceAll(' Province', '')
                    .trim();

                String cleanDistrict = (district ?? '')
                    .replaceAll(' İli', '')
                    .replaceAll(' ili', '')
                    .replaceAll(' District', '')
                    .trim();

                if (cleanProvince.isNotEmpty && cleanDistrict.isNotEmpty && cleanProvince != cleanDistrict) {
                  cityName = "$cleanProvince ($cleanDistrict)";
                } else if (cleanProvince.isNotEmpty) {
                  cityName = cleanProvince;
                } else if (cleanDistrict.isNotEmpty) {
                  cityName = cleanDistrict;
                } else {
                  cityName = 'Durak ${i + 1}';
                }
              } else {
                cityName = 'Durak ${i + 1}';
              }
            } catch (_) {
              cityName = 'Durak ${i + 1}';
            }
          }

          final weatherUrl =
              "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true";

          double temperature = 20.0;
          String weather = 'açık';

          try {
            final weatherResponse = await http.get(Uri.parse(weatherUrl));
            if (weatherResponse.statusCode == 200) {
              final weatherJsonData =
                  json.decode(weatherResponse.body) as Map<String, dynamic>;
              final currentWeather =
                  weatherJsonData['current_weather'] as Map<String, dynamic>;
              temperature = (currentWeather['temperature'] as num).toDouble();
              final weatherCode = (currentWeather['weathercode'] as num).toInt();
              weather = _getWeatherDescriptionFromCode(weatherCode);
            }
          } catch (_) {}

          if (routeCities.isNotEmpty && routeCities.last.name == cityName) {
            continue;
          }

          routeCities.add(
            RouteCity(
              name: cityName,
              lat: lat.toString(),
              lon: lon.toString(),
              temperature: temperature,
              weather: weather,
            ),
          );
        }

        emit(state.copyWith(routeCities: routeCities));
      },
    );

    on<RouteAddIncident>((event, emit) async {
      if (state.firstCity == null || state.secondCity == null) return;
      final routeName = "${state.firstCity!.name} - ${state.secondCity!.name}";
      final authorEmail = _firebaseAuth.currentUser?.email ?? 'Üye Sürücü';

      final incident = RoadIncident(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: event.type,
        title: event.title,
        authorEmail: authorEmail,
        lat: event.lat,
        lng: event.lng,
        routeName: routeName,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore.collection('incidents').add(incident.toMap());
      } catch (e) {
        debugPrint('Error saving incident to Firestore: $e');
      }

      final updatedIncidents = List<RoadIncident>.from(state.incidents)..add(incident);
      emit(state.copyWith(incidents: updatedIncidents));
    });
  }

  static String _getWeatherDescriptionFromCode(int code) {
    switch (code) {
      case 0:
        return 'açık';
      case 1:
      case 2:
        return 'parçalı bulutlu';
      case 3:
        return 'bulutlu';
      case 45:
      case 48:
        return 'sisli';
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return 'yağmurlu';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'karlı';
      case 95:
      case 96:
      case 99:
        return 'gök gürültülü yağmurlu';
      default:
        return 'açık';
    }
  }
}
