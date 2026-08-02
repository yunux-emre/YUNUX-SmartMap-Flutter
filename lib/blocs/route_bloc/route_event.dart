part of 'route_bloc.dart';

class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object> get props => [];
}

class RouteInitial extends RouteEvent {}

class RouteFirstCitySelected extends RouteEvent {
  final City city;

  const RouteFirstCitySelected(this.city);

  @override
  List<Object> get props => [city];
}

class RouteSecondCitySelected extends RouteEvent {
  final City city;

  const RouteSecondCitySelected(this.city);

  @override
  List<Object> get props => [city];
}

class RouteNavigate extends RouteEvent {}

class RouteAddIncident extends RouteEvent {
  final String type;
  final String title;
  final double lat;
  final double lng;

  const RouteAddIncident({
    required this.type,
    required this.title,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object> get props => [type, title, lat, lng];
}
