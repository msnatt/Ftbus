import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_appbus/api/func.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key});

  @override
  _BusScreenState createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> buses = {};
  Func function = Func();
  double radiusbtn = 24;
  double height = 50;
  double width = 90;
  String name_bus = "";
  String data_bus = "";
  var allow_gps = false;

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  Future<void> loadJsonData() async {
    final String response = await rootBundle.loadString('assets/buses.json');
    final Map<String, dynamic> jsonData = json.decode(response);
    setState(() {
      buses = jsonData["buses"];
    });
    print(jsonData);
  }

  void showStationPopup(BuildContext context, String name, String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                data,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด popup
              },
              child: const Text("ปิด", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 131, 36),
        title: const Text(
          'FtBus',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255), // เปลี่ยนสีไอคอนย้อนกลับ
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 60,
                  ),
                  const SizedBox(
                    child: Text(
                      "ข้อมูลรถบัสต่างๆ",
                      style: const TextStyle(
                          fontSize: 26,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      children: buses.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all<Size>(
                                  const Size(90, 50)),
                              backgroundColor: WidgetStateProperty.all(
                                  const Color.fromARGB(255, 235, 235, 235)),
                            ),
                            onPressed: () {
                              showStationPopup(
                                context,
                                entry.value["name"], // ชื่อสถานี
                                entry.value["data"], // รายละเอียด
                              );
                            },
                            child: Text(
                              entry.value["name"],
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
