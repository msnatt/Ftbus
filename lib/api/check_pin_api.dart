import 'dart:convert';

import 'package:http/http.dart' as http;

class CheckPinApi {
  Future<List<dynamic>> checkPin(
      {required String pin, required String ipAddress}) async {
    Map<String, dynamic>? result;
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request(
        'POST', Uri.parse('http://49.0.69.152:4491/check_pin')); // production
    request.body = json.encode({
      "jasonrpc": 2.0,
      "params": {"pin": pin}
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      result = json.decode(await response.stream.bytesToString());
      // print(await response.stream.bytesToString());
    } else {
      print(response.reasonPhrase);
    }
    return result?['result'] ?? [];
  }
}
