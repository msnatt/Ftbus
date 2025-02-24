import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_appbus/api/func.dart';
import 'package:my_appbus/api/globalvar.dart';
import 'package:my_appbus/screen/bus.dart';
import 'package:my_appbus/screen/maps.dart';
import 'package:my_appbus/screen/pin_code_widget.dart';
import 'package:my_appbus/screen/station.dart';

class MenuScreen extends StatefulWidget {
  final String ipAddress;
  static LatLng? currentLocation;

  const MenuScreen({super.key, required this.ipAddress});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Func function = Func();
  Timer? _timer;
  LatLng? currentLocation;
  List<dynamic>? stations;
  Map<String, dynamic>? station;
  int roundCall = GetroundCall();
  int maxroundCall = Getmaxroundcall();

  String Stationtext = "กำลังค้นหาสถานี..";

  @override
  void initState() {
    super.initState();
    gps_tracking();
    startLocationUpdates();
  }

  Future<void> startLocationUpdates() async {
    stations = await function.Fetch_Stations();
    print(stations);
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      // GET roundCall
      roundCall = GetroundCall();
      // หา station ที่ใกล้ที่สุด
      station = await function.findNearestStation(currentLocation, stations);
      setState(() {
        if ((station?['distance'] <= 50)) {
          Stationtext = "คุณอยู่ใกล้ ${station?['name']}";
        } else {
          SetroundCall(0);
          Stationtext = "กำลังค้นหาสถานี..";
        }
      });
    });
  }

  Future<void> gps_tracking() async {
    print("Tracking..");
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // อัพเดตทุก 10 เมตร
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

  @override
  void dispose() {
    _timer?.cancel(); // หยุด Timer เมื่อ Widget ถูกทำลาย
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double radiusbtn = 24;
    double height = 100;
    double width = 110;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 90,
                    color: const Color.fromARGB(255, 255, 131, 26),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 40,
                        ),
                        Text(
                          "FtBus",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  const Text(
                    'เลือกเมนูที่ต้องการ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Stationtext,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 80),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: width,
                        height: height,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets
                                .zero, // ลบ padding เพื่อให้รูปเต็มปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusbtn),
                            ),
                          ),
                          onPressed: () async {
                            if (roundCall < maxroundCall) {
                              var success = await function.AddPassenger(
                                  currentLocation, stations);
                              if (success) {
                                AddroundCall(1);
                                int updateroundcall = GetroundCall();
                                setState(() {
                                  roundCall = updateroundcall;
                                });
                                Fluttertoast.showToast(
                                  msg: "เรียกรถสำเร็จแล้ว.",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green[700],
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              } else {
                                Fluttertoast.showToast(
                                  msg:
                                      "ตำแหน่งของคุณไม่อยู่ในเงื่อนไข. โปรดลองอีกครั้ง",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: "รถได้รับคำร้องแล้ว กรุณารอซักครู่!",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.green[700],
                                textColor: Colors.white,
                                fontSize: 16.0,
                              );
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radiusbtn),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/seach_btn.png'), // ใช้รูปภาพ
                                fit: BoxFit.cover, // ขยายรูปให้เต็มขนาดปุ่ม
                              ),
                            ),
                            child: Container(), // ใช้ Container เป็นลูกของ Ink
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        height: height,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets
                                .zero, // ลบ padding เพื่อให้รูปเต็มปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusbtn),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      maps(ipAddress: widget.ipAddress)),
                            );
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radiusbtn),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/map_btn.png'), // ใช้รูปภาพ
                                fit: BoxFit.cover, // ขยายรูปให้เต็มขนาดปุ่ม
                              ),
                            ),
                            child: Container(), // ใช้ Container เป็นลูกของ Ink
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: width,
                        height: height,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets
                                .zero, // ลบ padding เพื่อให้รูปเต็มปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusbtn),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => StationScreen()),
                            );
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radiusbtn),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/station_btn.png'), // ใช้รูปภาพ
                                fit: BoxFit.cover, // ขยายรูปให้เต็มขนาดปุ่ม
                              ),
                            ),
                            child: Container(), // ใช้ Container เป็นลูกของ Ink
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        height: height,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets
                                .zero, // ลบ padding เพื่อให้รูปเต็มปุ่ม
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusbtn),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BusScreen()),
                            );
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radiusbtn),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/images/bus_btn.png'), // ใช้รูปภาพ
                                fit: BoxFit.cover, // ขยายรูปให้เต็มขนาดปุ่ม
                              ),
                            ),
                            child: Container(), // ใช้ Container เป็นลูกของ Ink
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 8, // ระยะห่างจากซ้าย
            top: 36,
            child: FloatingActionButton(
                backgroundColor: const Color.fromARGB(255, 255, 131, 36),
                mini: true,
                elevation: 0,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const PinCodeWidget();
                      },
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: 3.1416, // 180 องศา (Pi เรเดียน)
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 25,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
