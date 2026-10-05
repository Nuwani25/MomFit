import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dashboard.dart';

class StepsCal extends StatefulWidget {
  @override
  _ActivityCalState createState() => _ActivityCalState();
}

class _ActivityCalState extends State<StepsCal> with WidgetsBindingObserver {
  late GoogleMapController _mapController;
  Location _location = Location();
  List<LatLng> _route = [];
  Set<Polyline> _polylines = {};
  LatLng _currentLatLng = LatLng(6.9271, 79.8612); // Default: Colombo

  late StreamSubscription<StepCount> _stepSubscription;
  int _stepCount = 0;
  double _distance = 0;
  double _calories = 0;
  int _moveMinutes = 0;
  final StopWatchTimer _stopWatchTimer = StopWatchTimer();
  String _walkingTime = '00:00:00';
  double caloriesBurned = 0;
  double distanceWalked = 0;
  bool startCount = false;
  int _startCount = 0;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _startLocationTracking();
    _startTimer();
  }

  Future<void> _requestPermissions() async {
    await Permission.activityRecognition.request();
    if (await Permission.activityRecognition.isGranted) {
      _initPedometer();
    } else {
      debugPrint("[PERMISSION] Activity recognition permission not granted.");
    }
  }

  void _initPedometer() {
    debugPrint("[PEDOMETER] Initializing pedometer...");
    _stepSubscription = Pedometer.stepCountStream
        .asBroadcastStream()
        .listen(_onStepCount, onError: _onError, cancelOnError: true);
  }

  void _onStepCount(StepCount event) {
    debugPrint("[STEP] ${event.steps}");
    double dis = (event.steps - _startCount) * 0.66;

    if (_isStarted) {
      if (startCount) {
        _startCount = event.steps;
        startCount = false;
      }
      setState(() {
        _stepCount = event.steps - _startCount;
        distanceWalked = dis / 100;
        caloriesBurned = (_stepCount) * 0.05;
      });
    }
  }

  void _onError(error) {
    debugPrint("[PEDOMETER ERROR] $error");
  }

  void _startLocationTracking() {
    _location.onLocationChanged.listen((loc) {
      setState(() {
        _currentLatLng = LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0);
        _route.add(_currentLatLng);
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            visible: true,
            points: _route,
            color: Colors.pink,
            width: 5,
          )
        };
        if (_isStarted) {
          _mapController.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
        }
      });
    });
  }

  void _startTimer() {
    _stopWatchTimer.rawTime.listen((value) {
      setState(() {
        _walkingTime = StopWatchTimer.getDisplayTime(value);
        _moveMinutes = value;
      });
    });
  }

  Future<void> _toggleTracking() async {
    setState(() {
      if (_isStarted) {
        _stopWatchTimer.onStopTimer();
      } else {
        _stopWatchTimer.onStartTimer();
      }
      _isStarted = !_isStarted;
      startCount = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('_stepCount', _stepCount.toString());
    await prefs.setString('distanceWalked', distanceWalked.toStringAsFixed(2).toString()+" km");
    await prefs.setString('caloriesBurned', caloriesBurned.toStringAsFixed(2).toString()+" kcal");
    await prefs.setString('moveMinutes', _moveMinutes.toString()+" min");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("[LIFECYCLE] App resumed. Reinitializing pedometer.");
      _initPedometer();
    }
  }

  @override
  void dispose() {
    _stopWatchTimer.dispose();
    _stepSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLatLng,
                zoom: 17,
              ),
              myLocationEnabled: true,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text('${distanceWalked.toStringAsFixed(2)} / 5.00 km',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(Icons.directions_walk, '$_stepCount', 'steps'),
                      _buildStat(Icons.local_fire_department, '${caloriesBurned.toStringAsFixed(1)}', 'cal'),
                      _buildStat(Icons.timer, _walkingTime, ''),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.stop_circle, size: 50, color: Colors.red),
                        onPressed: _isStarted ? _toggleTracking : null,
                      ),
                      SizedBox(width: 40),
                      IconButton(
                        icon: Icon(Icons.play_circle_fill, size: 50, color: Colors.pink),
                        onPressed: !_isStarted ? _toggleTracking : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('_stepCount', _stepCount.toString());
                await prefs.setString('distanceWalked', distanceWalked.toStringAsFixed(2).toString()+" km");
                await prefs.setString('caloriesBurned', caloriesBurned.toStringAsFixed(2).toString()+" kcal");
                await prefs.setString('moveMinutes', _moveMinutes.toString()+" min");

                Navigator.push(context,MaterialPageRoute(builder: (context) => Dashboard()));

              },
              child: Text("Save Data",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
