import 'package:flutter/material.dart';

extension ColorExtension on Color {
  static const Color deepSlateBlue = Color(0xFF3f6690);
  static const Color unselectedGreen = Color(0xFFD1EAD5);
  static const Color selectedGreen = Color(0xFF6DFD8C);
  static const Color blackGreen = Color(0xFF0A180C);

  Color get invert {
    return Color.fromARGB(alpha, 255-red, 255-green, 255-blue);
  }

  Color withBrightness(double brightness) {
    return Color.fromARGB(alpha, (red * brightness).round(), (green * brightness).round(), (blue * brightness).round());
  }
}

extension IntRepresentations on int {
  String get hexString4 {
    String str = toRadixString(16);
    return "0" * (4 - str.length) + str;
  }

  String get hexString2 {
    String str = toRadixString(16);
    return "0" * (2 - str.length) + str;
  }

  String get hexString1 {
    String str = toRadixString(16);
    return "0" * (1 - str.length) + str;
  }

  String get commaSeparatedString {
    String str = toString();
    String out = "";
    for (int i = 0; i < str.length; i++) {
      out = (i % 3 == 2 && i < str.length-1 ? ',' : '') + str[str.length - i - 1] + out;
    }
    return out;
  }
}

T wrap<T>(T value, bool apply, T Function(T v) modifier) {
  return apply ? modifier(value) : value;
}