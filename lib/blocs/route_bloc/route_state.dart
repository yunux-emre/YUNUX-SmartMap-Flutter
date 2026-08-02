part of 'route_bloc.dart';

class RouteState extends Equatable {
  const RouteState({
    required this.cities,
    required this.firstCity,
    required this.secondCity,
    required this.routeCities,
    required this.routeCoordinates,
    this.distanceKm = 0.0,
    this.durationMinutes = 0.0,
    this.incidents = const [],
  });

  final List<City> cities;
  final City? firstCity;
  final City? secondCity;

  final List<RouteCity> routeCities;
  final List routeCoordinates;

  final double distanceKm;
  final double durationMinutes;
  final List<RoadIncident> incidents;

  factory RouteState.initial() {
    return const RouteState(
      cities: [],
      firstCity: null,
      secondCity: null,
      routeCities: [],
      routeCoordinates: [],
      distanceKm: 0.0,
      durationMinutes: 0.0,
      incidents: [],
    );
  }

  RouteState copyWith({
    List<City>? cities,
    City? firstCity,
    City? secondCity,
    List<RouteCity>? routeCities,
    List? routeCoordinates,
    double? distanceKm,
    double? durationMinutes,
    List<RoadIncident>? incidents,
  }) {
    return RouteState(
      cities: cities ?? this.cities,
      firstCity: firstCity ?? this.firstCity,
      secondCity: secondCity ?? this.secondCity,
      routeCities: routeCities ?? this.routeCities,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      incidents: incidents ?? this.incidents,
    );
  }

  List<City> get availableCities {
    final selectedCities = [firstCity, secondCity];
    return cities
        .where((element) => !selectedCities.contains(element))
        .toList();
  }

  bool get isReadyToNavigate {
    return firstCity != null && secondCity != null;
  }

  @override
  List<Object?> get props => [
        cities,
        firstCity,
        secondCity,
        routeCities,
        routeCoordinates,
        distanceKm,
        durationMinutes,
        incidents,
      ];
}
