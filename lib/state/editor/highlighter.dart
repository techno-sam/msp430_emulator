/*
 * MIT License
 *
 * Copyright (c) 2022-2023 icedman, Sam Wagenaar
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'package:flutter/material.dart';
import 'package:flutter_highlighter/themes/atom-one-dark-reasonable.dart';
import 'package:highlight/highlight.dart';
import 'package:google_fonts/google_fonts.dart';

import 'document.dart';

const double fontSize = 18;
const double gutterFontSize = 16;
const Color selection = Color(0xff3f6690);//const Color(0xff44475a);
Map<String, TextStyle> get editorTheme {
  Map<String, TextStyle> newTheme = Map.of(atomOneDarkReasonableTheme);
  newTheme['function'] = newTheme['function']!.copyWith(fontWeight: FontWeight.bold);
  newTheme['normal_weight'] = const TextStyle(fontWeight: FontWeight.normal);
  newTheme['normal_style'] = const TextStyle(fontStyle: FontStyle.normal);
  newTheme['normal'] = const TextStyle(fontWeight: FontWeight.normal, fontStyle: FontStyle.normal);
  newTheme['underline'] = const TextStyle(decoration: TextDecoration.underline);
  newTheme['attribute'] = newTheme['attribute']!.copyWith(decoration: TextDecoration.underline);
  newTheme['operator'] = newTheme['operator']!.copyWith(decoration: TextDecoration.underline);
  newTheme['meta'] = const TextStyle(color: Color(0xff17e1c9));
  return newTheme;//gradientDarkTheme;
}
//var editorTheme = atelierHeathDarkTheme;

Size getTextExtents(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

class LineDecoration {
  int start = 0;
  int end = 0;
  Color? color;
  Color? background;
  bool? underline;
  bool? italic;
  bool? bold;

  TextStyle apply(TextStyle style) {
    if (color != null) {
      style = style.copyWith(color: color);
    }

    if (background != null) {
      style = style.copyWith(backgroundColor: background);
    }

    if (underline == true) {
      style = style.copyWith(decoration: TextDecoration.underline, decorationThickness: 4.0);
    } else if (underline == false) {
      style = style.copyWith(decoration: TextDecoration.none);
    }

    if (italic == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    } else if (italic == false) {
      style = style.copyWith(fontStyle: FontStyle.normal);
    }

    if (bold == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    } else if (bold == false) {
      style = style.copyWith(fontWeight: FontWeight.normal);
    }
    return style;
  }

  LineDecoration.of(TextStyle style) {
    color = style.color;
    background = style.backgroundColor;

    italic = style.fontStyle == null ? null : style.fontStyle == FontStyle.italic;
    bold = style.fontWeight == null ? null : style.fontWeight == FontWeight.bold;
    underline = style.decoration == null ? null : style.decoration == TextDecoration.underline;
  }
}

class Pair<A, B> {
  A first;
  B second;

  Pair(this.first, this.second);
}

class _Token {}

class _PushStyleToken extends _Token {
  final TextStyle style;
  final String className;

  _PushStyleToken(this.style, this.className);

  @override
  String toString() {
    return "_PushStyleToken($className)";
  }
}

class _TextToken extends _Token {
  final String text;

  _TextToken(this.text);

  @override
  String toString() {
    return "_TextToken($text)";
  }
}

class _PopStyleToken extends _Token {
  @override
  String toString() {
    return "_PopStyleToken()";
  }
}

class _Stack<T> {
  final List<T> _internal = [];

  _Stack();

  void push(T item) {
    _internal.add(item);
  }

  T? pop() {
    return _internal.isEmpty ? null : _internal.removeLast();
  }

  T? peek() {
    return _internal.isEmpty ? null : _internal.last;
  }
}

class _TokenList {
  final List<_Token> internal = [];

  void style(TextStyle style, String className) {
    internal.add(_PushStyleToken(style, className));
  }

  void text(String text) {
    if (internal.isNotEmpty && internal.last is _TextToken) {
      _TextToken last = internal.removeLast() as _TextToken;
      text = last.text + text;
    }
    internal.add(_TextToken(text));
  }

  void popStyle() {
    internal.add(_PopStyleToken());
  }
}

class CustomWidgetSpan extends WidgetSpan {
  final int line;
  const CustomWidgetSpan({required Widget child, this.line = 0})
      : super(child: child);
}

List<LineDecoration> _decorate(String text, int line, Document document) {
  String language = 'dart';
  language = 'msp430';

  List<Node> nodes = highlight.parse(text, language: language).nodes!;

  _TokenList tokens = _TokenList();

  traverse(Node node) {
    if (node.value != null) {
      if (node.className == null || editorTheme[node.className!] == null) {
        tokens.text(node.value!);
      } else {
        tokens.style(editorTheme[node.className!]!, node.className!);
        tokens.text(node.value!);
        tokens.popStyle();
      }
    } else if (node.children != null) {
      var style = editorTheme[node.className!];
      if (style != null) {
        tokens.style(style, node.className!);
      }

      // iterate
      for (var n in node.children!) {
        traverse(n);
      }

      if (style != null) {
        tokens.popStyle();
      }
    }
  }

  for (var node in nodes) {
    traverse(node);
  }

  List<LineDecoration> decorations = [];

  int column = 0;

  _Stack<Pair<int, TextStyle>> stack = _Stack();

  for (_Token token in tokens.internal) {
    if (token is _PushStyleToken) {
      stack.push(Pair(column, token.style));
    } else if (token is _TextToken) {
      column += token.text.length;
    } else if (token is _PopStyleToken) {
      Pair<int, TextStyle>? pair = stack.pop();
      if (pair != null) {
        decorations.add(LineDecoration.of(pair.second)
        ..start = pair.first
        ..end = column - 1
        ..color = pair.second.color);
      }
    }
  }

  return decorations;
}

class Highlighter {
  Pair<List<InlineSpan>, Color?> run(String text, int line, Document document) {
    TextStyle defaultStyle = GoogleFonts.firaCode(
        fontSize: fontSize, color: editorTheme['root']?.color
    );
    List<InlineSpan> res = [];
    List<LineDecoration> decors = _decorate(text, line, document);

    Color? cursorColor;

    text += ' ';
    String prevText = '';

    for (int i = 0; i < text.length; i++) {
      String ch = text[i];
      TextStyle style = defaultStyle.copyWith();
      Cursor cur = document.cursor.normalized();

      // decorate
      for (LineDecoration d in decors.reversed) {
        if (i >= d.start && i <= d.end) {
          style = d.apply(style);
        }
      }

      // selection
      if (cur.hasSelection()) {
        if (line < cur.line ||
            (line == cur.line && i < cur.column) ||
            line > cur.anchorLine ||
            (line == cur.anchorLine && i + 1 > cur.anchorColumn)) {
        } else {
          style = style.copyWith(backgroundColor: selection.withOpacity(0.75));
        }
      }

      // is within caret
      if ((line == document.cursor.line && i == document.cursor.column))
      {
        cursorColor = style.color ?? Colors.yellow;
        /*res.add(WidgetSpan(
            alignment: ui.PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(
                            width: 1.2, color: style.color ?? Colors.yellow))),
                child: Text(ch, style: style.copyWith(letterSpacing: -1.5)))));
        continue;*/
      }

      if (res.isNotEmpty && res[res.length - 1] is! WidgetSpan) {
        TextSpan prev = res[res.length - 1] as TextSpan;
        if (prev.style == style) {
          prevText += ch;
          res[res.length - 1] = TextSpan(
              text: prevText,
              style: style,
              mouseCursor: MaterialStateMouseCursor.textable);
          continue;
        }
      }

      res.add(TextSpan(
          text: ch,
          style: style,
          mouseCursor: MaterialStateMouseCursor.textable));
      prevText = ch;
    }

    res.add(CustomWidgetSpan(
        child: const SizedBox(height: 1, width: 8), line: line));
    return Pair(res, cursorColor);
  }

}