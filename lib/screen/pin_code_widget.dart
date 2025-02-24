import 'package:my_appbus/api/globalvar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_appbus/screen/menuscreen.dart';
import 'package:my_appbus/screen/station_admin.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import '../api/check_pin_api.dart';

class PinCodeWidget extends StatefulWidget {
  const PinCodeWidget({super.key});

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> {
  final CheckPinApi checkPinApi = CheckPinApi();
  String enteredPin = '';
  String checkpin = '';
  String check = '';
  bool isadmin = false;
  String ipAddress = '49.0.69.152'; //add
  bool isPinVisible = false;
  Color backgroundColor = GetBackgroundColor();
  Color primaryColor = GetPrimaryColor();
  Color secondaryColor = GetSecondaryColor();

  LatLng? currentLocation;

  // Start for call API
  void startCheckPin(String chkpin) async {
    List<Map<String, dynamic>> tmpResult = [];
    check = '';

    if (ipAddress.isEmpty) {
      // หาก IP Address ว่าง แสดงข้อความเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter IP Address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Call API
    await checkPinApi.checkPin(pin: chkpin, ipAddress: ipAddress).then((value) {
      tmpResult = value.cast<Map<String, dynamic>>();
    });

    for (Map<String, dynamic>? message in tmpResult) {
      check = message?['message'] ??
          ''; // ถ้า message เป็น null จะใช้ค่าเริ่มต้นเป็น '' (string ว่าง)
      isadmin = message?['isadmin'] ?? false;
    }

    // Check PIN if found next page
    if (check == 'found') {
      if (isadmin) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => StationAdmin(ipAddress: ipAddress)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return MenuScreen(ipAddress: ipAddress);
            },
          ),
        );
      }
    } else {
      // If PIN is incorrect, show SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัส PIN ไม่ถูกต้อง กรุณากรอกใหม่'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  // End call API

  /// This widget will be used for each digit
  Widget numButton(int number) {
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: TextButton(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all<Size>(
            const Size(66, 66)), // กำหนดขนาดปุ่ม (กว้าง x สูง)
          backgroundColor: WidgetStateProperty.all<Color>(
            Color.fromARGB(255, 255, 255, 255), // กำหนดสีพื้นหลังของปุ่ม
          ),
        ),
        onPressed: () {
          setState(() {
            if (enteredPin.length < 4) {
              enteredPin += number.toString();
            }
            if (enteredPin.length == 4) {
              // Check for PIN with JSON Odoo
              checkpin = enteredPin;
              enteredPin = '';
              // START CALL API CHECK PIN
              startCheckPin(checkpin);
            }
          });
        },
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),
    );
  }

  Widget viewpin() {
    return SizedBox(
      width: 400,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Enter Your Pin',
                style: TextStyle(
                  fontSize: 26,
                  color: Color.fromARGB(255, 245, 131, 36),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        color: index < enteredPin.length
                            ? const Color.fromARGB(255, 245, 131, 36)
                            : const Color.fromARGB(128, 77, 77, 77)),
                    child: isPinVisible && index < enteredPin.length
                        ? Center(
                            child: Text(
                              enteredPin[index],
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ));
  }

  Widget btnpin() {
    return Expanded(
      child: Container(
        color: const Color.fromARGB(8, 0, 0, 0), // กำหนดสีพื้นหลังที่ต้องการ
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (index) => numButton(
                      1 + 3 * i + index,
                    ),
                  ).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        enteredPin = '';
                      });
                    },
                    child: const Icon(
                      Icons.replay_rounded,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 24,
                    ),
                  ),
                  numButton(0),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (enteredPin.isNotEmpty) {
                          enteredPin =
                              enteredPin.substring(0, enteredPin.length - 1);
                        }
                      });
                    },
                    child: const Icon(
                      Icons.backspace,
                      color: Color.fromARGB(255, 0, 0, 0),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > constraints.maxHeight) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  viewpin(),
                  btnpin(),
                ],
              );
            } else {
              // จัดเป็น Column ถ้าอยู่ในโหมดตั้งขึ้น
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  viewpin(),
                  btnpin(),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
