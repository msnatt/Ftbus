import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_appbus/screen/pin_code_widget.dart';
import '../api/bus_api.dart';

class StationAdmin extends StatefulWidget {
  final String ipAddress; // รับ ipAddress จากหน้า PinCodeWidget

  const StationAdmin(
      {super.key, required this.ipAddress}); // รับ ipAddress จาก constructor

  @override
  State<StationAdmin> createState() => _StationAdminState();
}

class _StationAdminState extends State<StationAdmin> {
  final FetchApi fetchApi = FetchApi();
  List<dynamic> allStations = [];

  LatLng? apiLocation; // ตัวแปรเก็บตำแหน่งจาก API

  @override
  void initState() {
    super.initState();
    // เรียกฟังก์ชัน fetchBus() และรอผลลัพธ์
    _loadBusRoutes();
  }

  // ฟังก์ชันสำหรับโหลดข้อมูล
  Future<void> _loadBusRoutes() async {
    List<dynamic> stations = await fetchApi.fetchAllStations();
    setState(() {
      allStations = stations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const SizedBox(
                    height: 60,
                    child: Text(
                      'ข้อมูลสถานีทั้งหมด',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ), // เว้นที่ด้านบน
                  Expanded(
                    child: allStations.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context)
                                  .size
                                  .width, // ทำให้ตารางเต็มจอ
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: DataTable(
                                  columnSpacing: 20.0,
                                  columns: const [
                                    DataColumn(label: Text('ชื่อสถานี')),
                                    DataColumn(label: Text('จำนวนผู้โดยสาร')),
                                  ],
                                  rows: allStations.map<DataRow>((station) {
                                    return DataRow(cells: [
                                      DataCell(Text(station['name'])),
                                      DataCell(Text(station['total_passenger']
                                          .toString())),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // ปุ่มย้อนกลับอยู่บนซ้าย
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16), // ปรับตำแหน่ง
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                mini: true,
                elevation: 3,
                onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return const PinCodeWidget();
                    },
                  ),
                );
                },
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
