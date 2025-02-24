// global.dart
library global;

import 'dart:ui';

Color color = const Color.fromARGB(255, 221, 221, 221);
Color primaryColor = const Color.fromARGB(255, 245, 131, 36);
Color secondaryColor = const Color.fromARGB(255,254, 254, 254);

int maxroundCall = 1;
int roundCall = 0;

Color GetBackgroundColor() { 
  return color;
}
Color GetPrimaryColor() { 
  return primaryColor;
}
Color GetSecondaryColor() { 
  return secondaryColor;
}

// หรือสามารถใช้ global function ได้
int GetroundCall() {
  return roundCall;
}
void AddroundCall(int x){
  roundCall += x;
}
void SetroundCall(int x){
  roundCall = x;
}
int Getmaxroundcall() {
  return maxroundCall;
}
