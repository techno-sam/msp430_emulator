/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2023  Sam Wagenaar
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

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

T applyConditional<T>(T value, bool apply, T Function(T v) modifier) {
  return apply ? modifier(value) : value;
}

Completer<T> wrapInCompleter<T>(Future<T> future) {
  final completer = Completer<T>();
  future.then(completer.complete).catchError(completer.completeError);
  return completer;
}

extension CharCounter on TextSpan {
  int getCharCount() {
    int count = text?.length ?? 0;
    for (final child in children ?? []) {
      if (child is TextSpan) {
        count += child.getCharCount();
      }
    }
    return count;
  }
}