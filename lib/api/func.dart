import 'package:latlong2/latlong.dart';
import 'package:my_appbus/api/bus_api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class Func {
  final FetchApi fetchApi = FetchApi();
  List<String> busRoutes = [];
  List<dynamic> allStations = [];

  String _data2 = '';
  LatLng? apiLocation; // ตัวแปรเก็บตำแหน่งจาก API
  LatLng? currentLocation;

  // ฟังก์ชันสำหรับโหลดข้อมูล
  Future<List<String>> Fetch_Bus() async {
    List<String> routes = await fetchApi.fetchBus();
    busRoutes = routes; // อัปเดตค่า busRoutes
    return busRoutes;
  }

  Future<List<dynamic>> Fetch_Stations() async {
    List<dynamic> stations = await fetchApi.fetchAllStations();
    allStations = stations;
    return allStations;
  }

  

// ======================== GET Location on phone =========================
  Future<LatLng?> trackLocation() async {
    Fetch_Bus();
    Fetch_Stations();
    print("func Tracking..");
    var locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // อัพเดตทุก 10 เมตร
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) async {
        currentLocation = LatLng(position.latitude, position.longitude);
        print("func tracked ${currentLocation}");
    }, onError: (e) {
      print('Error: ${e.toString()}');
    });
    return null;
  }

  LatLng? handleData2(businfo) {
    LatLng? location;
    if (businfo.isNotEmpty) {
      final parsedData = jsonDecode(businfo); // แปลง JSON เป็น Map

      // ตรวจสอบ success และดึง latitude และ longtitude
      if (parsedData['result']['success'] == 'True') {
        final double latitude = parsedData['result']['data']['latitude'];
        final double longitude = parsedData['result']['data']['longtitude'];

        location = LatLng(latitude, longitude);
      } else {
        print('Failed to fetch valid data businfo.');
      }
    }
    return location;
  }

  Future<LatLng?> createDataSearch(selectedRoute) async {
    var url = Uri.parse('http://49.0.69.152:4491/call_bus');
    var response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json' // Set content-type to application/json
      },
      body: jsonEncode({
        "jsonrpc": "2.0",
        "params": {"name": selectedRoute}
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      _data2 = response.body; // บันทึกข้อมูลใน _data2

      apiLocation =
          handleData2(_data2); // เรียกใช้ฟังก์ชันนี้เพื่อแสดงหมุดเขียว
      return apiLocation; // ส่งสำเร็จ
    } else {
      _data2 = "Failed to create data";
      return apiLocation; // ส่งไม่สำเร็จ
    }
  }

// ============================ Call btn ==============================
  Future<bool> AddPassenger(currentLocation, stations) async {
    print('Call Btn : $currentLocation $allStations');
    try {
      Map<String, dynamic>? nearestStation = findNearestStation(currentLocation, allStations);
    
      if (nearestStation?['distance'] <= 50) {
      bool success = await createDataGet(nearestStation);
      print(nearestStation?['name']);
      return success;
    }
    } catch (e) {
      return false;
    }
    
    return false;
  }

  Map<String, dynamic>? findNearestStation(LatLng? currentLocation, List<dynamic>? allStations) {
    Map<String, dynamic>? nearestStation;
    double minDistance = double.infinity;

    for (var station in allStations!) {
      double latitude = double.tryParse(station['latitude'].toString()) ?? 0.0;
      double longitude =
          double.tryParse(station['longitude'].toString()) ?? 0.0;
      String name = station['name'].toString(); // ชื่อสถานี
      double distance = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation.longitude,
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
          "distance": neareststation['distance'],
        }
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Data created successfully : ${response.body}');
      return true; // ส่งสำเร็จ
    } else {
      print('Failed to create data: ${response.body}');
      print("Failed to create data");
      return false; // ส่งไม่สำเร็จ
    }
  }
// ============================ End Call btn ==============================


}
