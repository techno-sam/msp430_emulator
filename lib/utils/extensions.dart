/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2023-2024  Sam Wagenaar
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
import 'package:msp430_dart/msp430_dart.dart';
export 'package:msp430_dart/msp430_dart.dart' show IntRepresentations;

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

extension on int {
  String get hexString6 {
    String str = toRadixString(16);
    return "0" * (6 - str.length) + str;
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

class ClearableVoidCallback {
  VoidCallback? _callback;

  ClearableVoidCallback(this._callback);

  void call() {
    _callback?.call();
  }

  void clear() {
    _callback = null;
  }
}

extension Clearify on VoidCallback {
  ClearableVoidCallback clearable() {
    return ClearableVoidCallback(this);
  }
}

extension PrefixSuffixTrim on String {
  String trimPrefix(String prefix) {
    return startsWith(prefix) ? substring(prefix.length) : this;
  }

  String trimSuffix(String suffix) {
    return endsWith(suffix) ? substring(0, length - suffix.length) : this;
  }
}

extension CSSColor on Color {
  String get cssValue => "#${(value & 0xffffff).hexString6}${alpha.hexString2}";
}

extension HTMLableSpan on TextSpan {
  String toHtml([Color? defaultBackgroundColor]) {
    if (children?.isNotEmpty == true) {
      return "<h1>children not supported</h1>";
    }
    String text = this.text!.replaceAll(" ", "&nbsp;");
    final Map<String, dynamic> styles = {};
    // actual stuff
    styles["color"] = (style?.color ?? Colors.greenAccent).cssValue;
    styles["background-color"] = (style?.backgroundColor ?? defaultBackgroundColor)?.cssValue;
    styles["font-size"] = "${style?.fontSize ?? 18.0}pt";
    if (style?.decoration == TextDecoration.underline) {
      styles["text-decoration"] = "underline";
    }
    if (style?.decorationColor != null) {
      //print("deco color: ${style?.decorationColor}");
      styles["text-decoration-color"] = style?.decorationColor!.cssValue;
    }
    if (style?.fontWeight != null) {
      styles["font-weight"] = style?.fontWeight!.value;
    }
    if (style?.fontStyle != null) {
      styles["font-style"] = style?.fontStyle!.name;
    }
    styles["font-family"] = "'Fira Code',monospace";

    String styleStr = "";
    for (var entry in styles.entries) {
      if (entry.value == null) continue;
      styleStr += "${entry.key}: ${entry.value}; ";
    }
    return '<span style="$styleStr">$text</span>';
  }
}