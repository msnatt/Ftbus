import 'dart:convert';

import 'package:http/http.dart' as http;

class FetchApi {
  Future<List<dynamic>> fetchAllStations() async {
    final url = Uri.parse('http://49.0.69.152:4491/get_allstation');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data; // ส่งคืนข้อมูล busRoutes
      } else {
        print('Failed to load stations: ${response.statusCode}');
        return []; // หากเกิดข้อผิดพลาด, ส่งคืน list ว่าง
      }
    } catch (e) {
      print('Error fetching stations: $e');
      return []; // ส่งคืน list ว่างในกรณีเกิดข้อผิดพลาด
    }
  }

  Future<List<String>> fetchBus() async {
    final url = Uri.parse('http://49.0.69.152:4491/get_allbus');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // ดึงชื่อรถบัสจากข้อมูล JSON และเก็บใน list
        List<String> busRoutes =
            data.map((bus) => bus['name'].toString()).toList();

        return busRoutes; // ส่งคืนข้อมูล busRoutes
      } else {
        print('Failed to load buses: ${response.statusCode}');
        return []; // หากเกิดข้อผิดพลาด, ส่งคืน list ว่าง
      }
    } catch (e) {
      print('Error fetching buses: $e');
      return []; // ส่งคืน list ว่างในกรณีเกิดข้อผิดพลาด
    }
  }
}
