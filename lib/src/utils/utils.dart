import 'package:flutter/material.dart';

final Color primaryAppBarColor = Color.fromRGBO(254, 86, 14, 1);
final Color primaryButtonColor = Color.fromRGBO(254, 86, 14, 1);
final int versionNumber = 100; // patern must be 3 digits 
class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class Fonts {
  static const primaryFont = "TitilliumWeb";
}