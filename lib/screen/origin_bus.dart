import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../api/bus_api.dart';

class Bus extends StatefulWidget {
  final String ipAddress; // รับ ipAddress จากหน้า PinCodeWidget

  const Bus(
      {super.key, required this.ipAddress}); // รับ ipAddress จาก constructor

  @override
  State<Bus> createState() => _BusState();
}

class _BusState extends State<Bus> {
  final FetchApi fetchApi = FetchApi();
  String selectedRoute = 'BUS101';
  List<String> busRoutes = [];
  List<dynamic> allStations = [];

  String _data = '';
  String _data2 = '';
  LatLng? apiLocation; // ตัวแปรเก็บตำแหน่งจาก API

  @override
  void initState() {
    super.initState();
    // เรียกฟังก์ชัน fetchBus() และรอผลลัพธ์
    _loadBusRoutes();

    trackLocation();
  }

  // ฟังก์ชันสำหรับโหลดข้อมูล
  Future<void> _loadBusRoutes() async {
    List<String> routes = await fetchApi.fetchBus();
    List<dynamic> stations = await fetchApi.fetchAllStations();
    setState(() {
      allStations = stations;
      busRoutes = routes; // อัปเดตค่า busRoutes
    });
  }

  // ฟังก์ชันที่ใช้ในการจัดการข้อมูลจาก API
  void handleData2() {
    if (_data2.isNotEmpty) {
      final parsedData = jsonDecode(_data2); // แปลง JSON เป็น Map

      // ตรวจสอบ success และดึง latitude และ longtitude
      if (parsedData['result']['success'] == 'True') {
        final double latitude = parsedData['result']['data']['latitude'];
        final double longitude = parsedData['result']['data']['longtitude'];

        // เก็บค่าในตัวแปร apiLocation
        setState(() {
          apiLocation = LatLng(latitude, longitude);
        });

        print('Latitude: $latitude');
        print('Longitude: $longitude');
      } else {
        print('Failed to fetch valid data.');
      }
    }
  }

  Future<bool> createDataGet(neareststation) async {


    var url = Uri.parse(
        'http://49.0.69.152:4491/update_passenger'); // ใช้ ipAddress ที่รับมา
    var response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json' // Set content-type to application/json
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {
          "name": neareststation['name'],
          "distance" : neareststation['distance'],
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _data = 'Data created successfully : ${response.body}';
      });
      return true; // ส่งสำเร็จ
    } else {
      print('Failed to create data: ${response.body}');
      setState(() {
        _data = "Failed to create data";
      });
      return false; // ส่งไม่สำเร็จ
    }
  }

  Future<bool> createDataSearch() async {
    var url = Uri.parse(
        'http://49.0.69.152:4491/call_bus'); // ใช้ ipAddress ที่รับมา
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json' // Set content-type to application/json
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {"name": selectedRoute}
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _data2 = response.body; // บันทึกข้อมูลใน _data2
      });
      handleData2(); // เรียกใช้ฟังก์ชันนี้เพื่อแสดงหมุดเขียว
      return true; // ส่งสำเร็จ
    } else {
      setState(() {
        _data2 = "Failed to create data";
      });
      return false; // ส่งไม่สำเร็จ
    }
  }

  LatLng? currentLocation;


  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        currentLocation =
            LatLng(position.latitude, position.longitude); // อัพเดตตำแหน่ง
            print('== Latitude: ${position.latitude}');
            print('== Longitude: ${position.longitude}');
            
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

Map<String, dynamic>? findNearestStation() {
  if (currentLocation == null || allStations.isEmpty) return null;

  Map<String, dynamic>? nearestStation;
  double minDistance = double.infinity;

  for (var station in allStations) {
    double latitude = double.tryParse(station['latitude'].toString()) ?? 0.0;
    double longitude = double.tryParse(station['longitude'].toString()) ?? 0.0;
    String name = station['name'].toString(); // ชื่อสถานี
    print(latitude);
    print(longitude);
    print(name);
    double distance = Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      latitude,
      longitude,
    );

    if (distance < minDistance) {
      minDistance = distance;
      nearestStation = {
        'name': name,
        'latitude': latitude,
        'longtitude': longitude,
        'distance': minDistance, // เก็บระยะห่างไว้ด้วย
      };
    }
  }
  return nearestStation;
}

  void trackLocation() {
    var locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // อัพเดตทุก 10 เมตร
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) async {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    
    }, onError: (e) {
      print('Error: ${e.toString()}');
    });
  }


  Future<bool> AddPassenger() async {
    Map<String, dynamic>? nearestStation = findNearestStation();

      if (nearestStation!['distance'] <= 50) {
        bool success = await createDataGet(nearestStation);
        print(nearestStation['name']);
        if (success) {
          print("อยู่ใกล้สถานี < 50 m");
          return true;
        } else {
          print("ส่งข้อมูลไม่สำเร็จ");
          return false;
        }
      }
      return false;
  }

  // ฟังก์ชันที่จะเรียกใช้เมื่อคุณต้องการแสดง Pop-up
  void _showSuccessToast() {
    var snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เรียกรถสำเร็จ!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                selectedRoute,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ฟังก์ชันที่จะเรียกใช้เมื่อคุณต้องการแสดง Pop-up
  void _searchSuccessToast() {
    var snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ค้นหารถ! $selectedRoute',
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_bus, size: 30),
            Spacer(),
          ],
        ),
        backgroundColor: Color(0xFFD9D9D9),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),            
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRoute,
                  icon: const Icon(Icons.arrow_drop_down, size: 30),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.blue,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRoute = newValue!;
                    });
                  },
                  items:
                      busRoutes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        var success = await createDataSearch();
                        if (success) {
                          _searchSuccessToast();
                        } else {
                          Fluttertoast.showToast(
                            msg: "Failed to create data search",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child: const Text('ค้นหา'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        var success = await AddPassenger();
                        if (success) {
                          _showSuccessToast();
                        } else {
                          Fluttertoast.showToast(
                            msg: "Failed to create data get",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child: const Text('เรียกรถ'),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: 100,
                //   child: SingleChildScrollView(
                //     child: Text(_data),
                //   ),
                // ),
                // SizedBox(
                //   height: 100,
                //   child: SingleChildScrollView(
                //     child: Text(_data2),
                //   ),
                // ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: 
                  //currentLocation ?? LatLng(7.167384, 100.613034),     //songkla
                  currentLocation ?? LatLng(13.8097, 100.66),   //bkk
                initialZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.evo.app',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    if (currentLocation != null)
                      Marker(
                        point: currentLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.location_on,
                            size: 40, color: Colors.red),
                      ),
                    if (apiLocation != null)
                      Marker(
                        point: apiLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.directions_bus,
                            size: 40, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
