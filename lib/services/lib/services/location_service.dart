import 'package:flutter/material.dart';
import 'services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();

    _askLocationPermission();
  }

  Future<void> _askLocationPermission() async {
    await LocationService.getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الرئيسية")),
      body: Center(
        child: ElevatedButton(
          onPressed: _getMyLocation,
          child: const Text("تحديد موقعي"),
        ),
      ),
    );
  }

  Future<void> _getMyLocation() async {
    final pos = await LocationService.getLocation();

    if (pos != null) {
      print("LAT: ${pos.latitude}");
      print("LNG: ${pos.longitude}");
    }
  }
}
