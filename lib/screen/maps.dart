import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_appbus/api/func.dart';
import 'package:my_appbus/api/globalvar.dart';

import 'package:my_appbus/screen/menuscreen.dart';

class maps extends StatefulWidget {
  final String ipAddress; // รับ ipAddress จากหน้า PinCodeWidget

  const maps(
      {super.key, required this.ipAddress}); // รับ ipAddress จาก constructor

  @override
  State<maps> createState() => _mapsState();
}

class _mapsState extends State<maps> {
  final MapController _mapController = MapController();
  final Func function = Func();
  String selectedRoute = 'BUS101';
  List<String> busRoutes = [];
  List<dynamic> allStations = [];
  Timer? _timer;
  LatLng? apiLocation; // ตัวแปรเก็บตำแหน่งจาก API
  LatLng? currentLocation = MenuScreen.currentLocation;
  List<dynamic>? stations;
  Map<String, dynamic>? station;
  int roundCall = GetroundCall();
  int maxroundCall = Getmaxroundcall();

  String stationtext = "กำลังค้นหาตำแหน่งของคุณ..";

  @override
  void initState() {
    super.initState();
    gpsTracking();
    fetchAlldata();
    startLocationUpdates();
  }

  Future<void> fetchAlldata() async {
    List<String> routes = await function.Fetch_Bus();
    stations = await function.Fetch_Stations();
    setState(() {
      busRoutes = routes;
      stations = stations;
    });
  }

  Future<void> startLocationUpdates() async {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // GET roundCall
      roundCall = GetroundCall();
      // หา station ที่ใกล้ที่สุด
      if (currentLocation != null) {
        station = function.findNearestStation(currentLocation, stations);
      }
      setState(() {
        try {
          if (station?['distance'] <= 50) {
            stationtext = "คุณอยู่ใกล้ ${station?['name']}";
          } else {
            SetroundCall(0);
            stationtext = "กำลังค้นหาตำแหน่งของคุณ..";
          }
        } catch (e) {
          SetroundCall(0);
          print("Error: $e");
          stationtext = "กำลังค้นหาตำแหน่งของคุณ..";
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer
    super.dispose();
  }

  void setcentermap(LatLng location) {
    _mapController.move(location, 15.0);
  }

  Future<void> gpsTracking() async {
    print("Tracking..");
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // อัพเดตทุก 10 เมตร
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) async {
      if (mounted) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
          print("Tracked ${currentLocation}");
        });
      }
    }, onError: (e) {
      print('Error: ${e.toString()}');
    });
  }

// ============================== UI ==================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation ?? const LatLng(13.8097, 100.66),
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                            child: const Icon(Icons.location_on,
                                size: 40, color: Colors.red),
                          ),
                        if (apiLocation != null)
                          Marker(
                            point: apiLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.directions_bus_sharp,
                                size: 40,
                                color: Color.fromARGB(255, 255, 131, 36)),
                          ),
                      ],
                    ),
                  ],
                ),
                // ปุ่มย้อนกลับแทน AppBar
                Positioned(
                  top: 40, // ระยะห่างจากด้านบน
                  left: 16, // ระยะห่างจากซ้าย
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    mini: true,
                    elevation: 3,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                // ปุ่มลอยสำหรับซูมไปที่ตำแหน่งปัจจุบัน
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    onPressed: () {
                      if (currentLocation != null) {
                        _mapController.move(
                            currentLocation!, 15); // ซูมไปที่ตำแหน่งปัจจุบัน
                      }
                    },
                    child: const Icon(Icons.my_location,
                        color: Color.fromARGB(255, 255, 131, 36)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), //
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ค้นหารถบัส",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            stationtext,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
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
                    color: const Color.fromARGB(255, 245, 131, 36),
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
                const Text(
                  "",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 245, 131, 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        var success =
                            await function.createDataSearch(selectedRoute);
                        if (success != null) {
                          setState(() {
                            apiLocation = success;
                          });
                          setcentermap(apiLocation ?? const LatLng(13.81, 100.66));
                          Fluttertoast.showToast(
                            msg: "พบตำแหน่งรถบัสแล้ว!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor:
                                const Color.fromARGB(255, 255, 131, 36),
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg: "ไม่พบตำแหน่งรถบัส กรุณาลองอีกครั้ง.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
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
                        backgroundColor:
                            const Color.fromARGB(255, 245, 131, 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                      ),
                      onPressed: () async {
                        if (roundCall < maxroundCall) {
                          var success = await function.AddPassenger(
                              currentLocation, stations);
                          if (success) {
                            AddroundCall(1);
                            setState(() {
                              roundCall = GetroundCall();
                            });
                            Fluttertoast.showToast(
                              msg: "เรียกรถสำเร็จแล้ว.",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: Colors.green[700],
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg:
                                  "ตำแหน่งของคุณไม่อยู่ในเงื่อนไข.                โปรดลองอีกครั้ง",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          }
                        } else {
                          Fluttertoast.showToast(
                            msg: "รถได้รับคำร้องแล้ว กรุณารอซักครู่!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Colors.green[700],
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child: const Text('เรียกรถ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ]));
  }
}
