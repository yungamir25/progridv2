import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tower.dart';
import 'tower_details_page.dart';
import 'tower_list_page.dart';
import 'profile.dart'; // Import the new profile screen
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'; // New Import for Marker Clustering

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 8.0; // Initial zoom level

  // Malaysia bounds for map interaction
  final LatLngBounds _malaysiaBounds = LatLngBounds(
    const LatLng(0.85, 99.5),
    const LatLng(7.5, 119.5),
  );

  // Define LatLngBounds for each region
  final Map<String, LatLngBounds> _regionBounds = {
    'Northern': LatLngBounds(const LatLng(5.0, 100.0), const LatLng(6.8, 101.0)),
    'Central': LatLngBounds(const LatLng(2.4, 101.0), const LatLng(3.8, 102.5)),
    'Southern': LatLngBounds(const LatLng(1.2, 103.0), const LatLng(2.4, 104.5)),
    'East Coast': LatLngBounds(const LatLng(3.5, 102.5), const LatLng(6.5, 103.5)),
    'Sabah': LatLngBounds(const LatLng(4.0, 115.5), const LatLng(7.5, 118.5)),
    'Sarawak': LatLngBounds(const LatLng(0.8, 109.5), const LatLng(5.0, 115.0)),
  };

  // Function to navigate to a specific region on the map
  void _goToRegion(String regionName) {
    if (_regionBounds.containsKey(regionName)) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: _regionBounds[regionName]!,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  // Get progress color based on tower status
  Color _getProgressColor(String progress) {
    switch (progress) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.yellow;
      default:
        return Colors.red;
    }
  }

  // Build marker for each tower
  Marker _buildTowerMarker(Tower tower) {
    final bool showText = _currentZoom >= 9.0;

    return Marker(
      point: LatLng(tower.latitude, tower.longitude),
      width: showText ? 60.0 : 40.0,
      height: showText ? 60.0 : 40.0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TowerDetailsPage(tower: tower)),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: showText ? 10.0 : 0,
              child: Icon(
                Icons.location_on,
                color: _getProgressColor(tower.progress),
                size: 40,
              ),
            ),
            if (showText)
              Positioned(
                top: 35.0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black12)],
                  ),
                  constraints: const BoxConstraints(maxWidth: 50),
                  child: Text(
                    tower.id,
                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progridv2'),
        backgroundColor: const Color.fromARGB(255, 152, 193, 234),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('towers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final towers = snapshot.data!.docs
              .map((doc) => Tower.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          // Make sure allMarkers is not empty before passing to MarkerClusterLayerWidget
          final allMarkers = towers.map(_buildTowerMarker).toList();

          return Stack( // Use a Stack to layer the map and buttons
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(3.1583, 101.721),
                  initialZoom: 8.0,
                  maxZoom: 18.0,
                  minZoom: 5.0,
                  cameraConstraint: CameraConstraint.contain(bounds: _malaysiaBounds),
                  onPositionChanged: (position, _) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  },
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.progridv2',
                  ),
                  // Add MarkerClusterLayerWidget only if there are markers
                  if (allMarkers.isNotEmpty)
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 120, // Adjust this value to change how markers are grouped
                        size: const Size(40, 40),
                        builder: (context, markers) {
                          return FloatingActionButton(
                            heroTag: null,
                            onPressed: () {
                              // Fit the camera to the bounds of the markers
                              _mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(
                                    markers.map((m) => m.point).toList(),
                                  ),
                                  padding: const EdgeInsets.all(50),
                                ),
                              );
                            },
                            backgroundColor: const Color.fromARGB(237, 108, 108, 108),
                            child: markers.isNotEmpty
                                ? Text(
                                    markers.length.toString(),
                                    style: const TextStyle(color: Color.fromARGB(255, 239, 239, 239)),
                                  )
                                : const Icon(Icons.zoom_in, color: Color.fromARGB(255, 239, 239, 239)),
                          );
                        },
                        markers: allMarkers,
                      ),
                    ),
                ],
              ),
              Positioned(
                top: 16.0,
                right: 16.0,
                child: Column( // Use a Column for a vertical arrangement
                  children: [
                    FloatingActionButton(
                      heroTag: "searchBtn",
                      onPressed: () async {
                        try {
                          final snapshot = await FirebaseFirestore.instance.collection('towers').get();
                          final towers = snapshot.docs.map((doc) => Tower.fromMap(doc.data())).toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TowerListPage(towers: towers)),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      child: const Icon(Icons.search),
                    ),
                    const SizedBox(height: 10), // Add vertical spacing
                    FloatingActionButton(
                      heroTag: "regionBtn",
                      onPressed: () {
                        _showRegionSelection(context);
                      },
                      child: const Icon(Icons.map),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Function to show the region selection dialog
  void _showRegionSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _regionBounds.keys.map((regionName) {
              return ListTile(
                title: Text(regionName),
                onTap: () {
                  _goToRegion(regionName);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
