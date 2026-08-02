import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_routes/blocs/auth_bloc/auth_bloc.dart';
import 'package:smart_routes/blocs/route_bloc/route_bloc.dart';
import 'package:smart_routes/blocs/comments_bloc/comments_bloc.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:smart_routes/colors.dart';
import 'package:smart_routes/comments_popup.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  bool showWeather = true;

  int selectedIndex = 0;

  @override
  void initState() {
    mapController.mapEventStream.listen((event) {
      if (event.zoom > 12) {
        setState(() {
          showWeather = false;
        });
      } else {
        setState(() {
          showWeather = true;
        });
      }
    });
    super.initState();
  }

  Icon getWeatherIcon(String weather) {
    if (weather.contains("bulut")) {
      return const Icon(Icons.cloud, color: Colors.grey, size: 24);
    } else if (weather.contains("güneş") || weather.contains("açık")) {
      return const Icon(Icons.wb_sunny, color: Colors.yellow, size: 24);
    } else if (weather.contains("yağmur") || weather.contains("sağanak")) {
      return const Icon(Icons.cloudy_snowing, color: Colors.blue, size: 24);
    } else if (weather.contains("kar")) {
      return const Icon(Icons.ac_unit, color: Colors.white, size: 24);
    } else if (weather.contains("kapalı") || weather.contains("sis")) {
      return const Icon(Icons.cloud, color: Colors.grey, size: 24);
    }
    return const Icon(Icons.wb_sunny, color: Colors.yellow, size: 24);
  }

  Widget buildCityTitleWidget(String fullName, {double mainSize = 13, double subSize = 10}) {
    if (fullName.contains(' (')) {
      final parts = fullName.split(' (');
      final province = parts[0];
      final district = '(${parts[1]}';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            province,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: mainSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            district,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subSize,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      );
    } else {
      return Text(
        fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: mainSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }
  }

  void _showAddIncidentBottomSheet(BuildContext context, RouteState state) {
    final authState = context.read<AuthBloc>().state;
    if (authState.isGuest) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield, color: Colors.orange),
              SizedBox(width: 8),
              Text("Üyelik Gereklidir"),
            ],
          ),
          content: const Text(
              "Sürüş esnasında canlı yol olayı bildirebilmek için lütfen ücretsiz üye girişi yapın."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Kapat"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogout());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text("Giriş Yap / Üye Ol"),
            ),
          ],
        ),
      );
      return;
    }

    final routeName = "${state.firstCity!.name} - ${state.secondCity!.name}";

    String legSegment = routeName;
    if (state.routeCities.isNotEmpty) {
      final currentIdx = selectedIndex.clamp(0, state.routeCities.length - 1);
      if (currentIdx < state.routeCities.length - 1) {
        final currentCityName = state.routeCities[currentIdx].name;
        final nextCityName = state.routeCities[currentIdx + 1].name;
        legSegment = "$currentCityName - $nextCityName";
      } else if (currentIdx > 0) {
        final prevCityName = state.routeCities[currentIdx - 1].name;
        final currentCityName = state.routeCities[currentIdx].name;
        legSegment = "$prevCityName - $currentCityName";
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "$legSegment Yol Olayı Bildir",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$legSegment arası tek dokunuşla bildirim yapın:",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickIncidentButton(
                    context: bottomCtx,
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red,
                    label: "Kaza",
                    onTap: () {
                      context.read<CommentsBloc>().add(CommentAdd(
                            commentName: routeName,
                            comment: "$legSegment arası Kaza bildirildi.",
                          ));
                      Navigator.pop(bottomCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$legSegment arası Kaza bildirimi eklendi!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                  _buildQuickIncidentButton(
                    context: bottomCtx,
                    icon: Icons.local_police,
                    color: Colors.blue,
                    label: "Radar",
                    onTap: () {
                      context.read<CommentsBloc>().add(CommentAdd(
                            commentName: routeName,
                            comment: "$legSegment arası Radar uyarısı bildirildi.",
                          ));
                      Navigator.pop(bottomCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$legSegment arası Radar uyarısı eklendi!"),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  _buildQuickIncidentButton(
                    context: bottomCtx,
                    icon: Icons.engineering,
                    color: Colors.orange,
                    label: "Yol Çalışması",
                    onTap: () {
                      context.read<CommentsBloc>().add(CommentAdd(
                            commentName: routeName,
                            comment: "$legSegment arası Yol çalışması bildirildi.",
                          ));
                      Navigator.pop(bottomCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$legSegment arası Yol çalışması eklendi!"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickIncidentButton(
                    context: bottomCtx,
                    icon: Icons.report_problem,
                    color: Colors.amber.shade800,
                    label: "Tehlike",
                    onTap: () {
                      context.read<CommentsBloc>().add(CommentAdd(
                            commentName: routeName,
                            comment: "$legSegment arası Tehlike bildirildi.",
                          ));
                      Navigator.pop(bottomCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$legSegment arası Tehlike bildirimi eklendi!"),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    },
                  ),
                  _buildQuickIncidentButton(
                    context: bottomCtx,
                    icon: Icons.traffic,
                    color: Colors.purple,
                    label: "Yoğun Trafik",
                    onTap: () {
                      context.read<CommentsBloc>().add(CommentAdd(
                            commentName: routeName,
                            comment: "$legSegment arası Yoğun trafik bildirildi.",
                          ));
                      Navigator.pop(bottomCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$legSegment arası Yoğun trafik bildirimi eklendi!"),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickIncidentButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: appBackgroundColor,
        body: SafeArea(
          child: BlocConsumer<RouteBloc, RouteState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state.routeCoordinates.isEmpty || state.routeCities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/map_animation.json',
                        width: 180,
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Veriler yükleniyor...",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Lottie.asset(
                        'assets/loading.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircularProgressIndicator(
                            color: Colors.white,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }

              final temps =
                  state.routeCities.map((e) => e.temperature).toList();
              double total = temps.reduce((a, b) => a + b);
              double averageTemp = total / temps.length;

              final hours = (state.durationMinutes / 60).floor();
              final mins = (state.durationMinutes.toInt() % 60);

              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height / 1.5,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          zoom: 9,
                          center: state.routeCoordinates
                              .map((e) => LatLng(e[1], e[0]))
                              .first,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'dev.fleaflet.flutter_map.example',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: state.routeCoordinates
                                    .map((e) => LatLng(e[1], e[0]))
                                    .toList(),
                                strokeWidth: 4.0,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(
                                  state.routeCoordinates.first[1],
                                  state.routeCoordinates.first[0],
                                ),
                                builder: (context) => const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 14.0,
                                ),
                              ),
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(
                                  state.routeCoordinates.last[1],
                                  state.routeCoordinates.last[0],
                                ),
                                builder: (context) => const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 14.0,
                                ),
                              ),
                            ],
                          ),
                          if (showWeather)
                            for (final city in state.routeCities)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    height: 130,
                                    width: 140,
                                    point: LatLng(
                                      double.parse(city.lat),
                                      double.parse(city.lon),
                                    ),
                                    builder: (context) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: appCardBackgroundColor,
                                          borderRadius: BorderRadius.circular(12.0),
                                          border: Border.all(color: Colors.white24, width: 1),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              blurRadius: 6,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            buildCityTitleWidget(city.name, mainSize: 13, subSize: 10),
                                            Text(
                                              "Hava ${city.weather}",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            getWeatherIcon(city.weather),
                                            Text(
                                              "${city.temperature.toInt()}°C",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: MediaQuery.sizeOf(context).height / 10,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: appCardBackgroundColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                context.read<RouteBloc>().add(RouteInitial());
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Canlı Harita & Hava Durumu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: appCardBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                height: 5,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (state.distanceKm > 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.straighten,
                                                color: Colors.white, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              "${state.distanceKm.toStringAsFixed(0)} km",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                color: Colors.white, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              hours > 0
                                                  ? "$hours sa $mins dk"
                                                  : "$mins dk",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            "Başlangıç: ${state.firstCity!.name}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Varış: ${state.secondCity!.name}",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Ortalama sıcaklık\n${averageTemp.toInt()}°C",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: appPrimaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {
                                              showCommentsPopup(
                                                context,
                                                commentsName:
                                                    "${state.firstCity!.name} - ${state.secondCity!.name}",
                                              );
                                            },
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.message, size: 16, color: appPrimaryColor),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Yorum Yap",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: appPrimaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 44),
                                    backgroundColor: Colors.white,
                                    foregroundColor: appPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showAddIncidentBottomSheet(
                                          context, state),
                                  icon: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: appPrimaryColor),
                                  label: const Text(
                                    "Yol Olayı Bildir",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: appPrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final data in state.routeCities) ...[
                                    InkWell(
                                      onTap: () {
                                        mapController.move(
                                          LatLng(
                                            double.parse(data.lat),
                                            double.parse(data.lon),
                                          ),
                                          9,
                                        );

                                        setState(() {
                                          selectedIndex =
                                              state.routeCities.indexOf(data);
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        width: 140,
                                        decoration: BoxDecoration(
                                          color: appSurfaceColor,
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          border: Border.all(
                                            color: selectedIndex ==
                                                    state.routeCities.indexOf(
                                                      data,
                                                    )
                                                ? appPrimaryColor
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            buildCityTitleWidget(data.name, mainSize: 13, subSize: 10),
                                            const SizedBox(height: 4),
                                            getWeatherIcon(data.weather),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Hava ${data.weather}",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${data.temperature.toInt()}°C",
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
