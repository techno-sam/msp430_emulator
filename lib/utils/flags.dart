import 'package:flutter/material.dart';

class Flags {
  Flags._();

  static const bool langDebug = false;
}

class IgnorableTextSpan extends TextSpan {
  final bool ignoreForCursor;

  const IgnorableTextSpan({
    required this.ignoreForCursor,
    super.text,
    super.children,
    super.style,
    super.recognizer,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
    super.semanticsLabel,
    super.locale,
    super.spellOut
  });
}