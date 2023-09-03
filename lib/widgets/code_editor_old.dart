import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:highlight/highlight.dart';

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

class _StyleStack {
  final TextStyle? defaultStyle;
  final List<TextStyle> _styles = [];

  _StyleStack(this.defaultStyle);
  
  void push(TextStyle style) {
    _styles.add(style);
  }
  
  TextStyle? pop() {
    return _styles.isEmpty ? defaultStyle : _styles.removeLast();
  }
  
  TextStyle? peek() {
    return _styles.isEmpty ? defaultStyle : _styles.last;
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

  const CustomWidgetSpan({required super.child, required this.line});
}

Size getTextExtents(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

Offset screenToCursor(RenderObject? obj, Offset pos) {
  List<RenderParagraph> pars = <RenderParagraph>[];
  findRenderParagraphs(obj, pars);

  RenderParagraph? targetPar;
  int line = -1;

  for (final par in pars) {
    Rect bounds = const Offset(0, 0) & par.size;
    Offset offsetForCaret = par.localToGlobal(
        par.getOffsetForCaret(const TextPosition(offset: 0), bounds));
    Rect parBounds =
    offsetForCaret & Size(par.size.width * 10, par.size.height);
    if (parBounds.inflate(2).contains(pos)) {
      targetPar = par;
      break;
    }
  }

  if (targetPar == null) return const Offset(-1, -1);

  Rect bounds = const Offset(0, 0) & targetPar.size;
  List<InlineSpan> children =
      (targetPar.text as TextSpan).children ?? <InlineSpan>[];
  Size fontCharSize = const Size(0, 0);
  int textOffset = 0;
  bool found = false;
  for (var span in children) {
    if (found) break;
    if (span is! TextSpan) {
      continue;
    }

    if (fontCharSize.width == 0) {
      fontCharSize = getTextExtents(' ', span.style ?? const TextStyle());
    }

    String txt = (span).text ?? '';
    for (int i = 0; i < txt.length; i++) {
      Offset offsetForCaret = targetPar.localToGlobal(targetPar
          .getOffsetForCaret(TextPosition(offset: textOffset), bounds));
      Rect charBounds = offsetForCaret & fontCharSize;
      if (charBounds.inflate(2).contains(Offset(pos.dx + 1, pos.dy + 1))) {
        found = true;
        break;
      }
      textOffset++;
    }
  }

  if (children.isNotEmpty && children.last is CustomWidgetSpan) {
    line = (children.last as CustomWidgetSpan).line;
  }

  return Offset(textOffset.toDouble(), line.toDouble());
}

void findRenderParagraphs(RenderObject? obj, List<RenderParagraph> res) {
  if (obj is RenderParagraph) {
    res.add(obj);
    return;
  }
  obj?.visitChildren((child) {
    findRenderParagraphs(child, res);
  });
}

class CodeEditor extends StatefulWidget {
  late final List<String> lines;
  final String language;
  final Map<String, TextStyle> theme;
  CodeEditor({
    super.key,
    required String text,
    required this.language,
    required this.theme,
  }) {
    lines = text.split("\n");
  }

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);

  // TODO: dart:io is not available at web platform currently
  // See: https://github.com/flutter/flutter/issues/39998
  // So we just use monospace here for now
  static const _defaultFontFamily = 'monospace';

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  int cursorColumn = 0;
  int cursorLine = 0;
  /*
  List of 'tokens':
  PushStyle(style)
  Text("string")
  PopStyle
   */
  List<InlineSpan> _convert(List<Node> nodes, int line) {
    _TokenList tokens = _TokenList();

    traverse(Node node) {
      if (node.value != null) {
        if (node.className == null || widget.theme[node.className!] == null) {
          tokens.text(node.value!);
        } else {
          tokens.style(widget.theme[node.className!]!, node.className!);
          tokens.text(node.value!);
          tokens.popStyle();
        }
      } else if (node.children != null) {
        var style = widget.theme[node.className!];
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

    /*spans.add(
      WidgetSpan(
        alignment: ui.PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 1.2, color: Colors.yellow
              )
            ),
          ),
          child: Text("h", style: TextStyle(letterSpacing: -1.5, fontFamily: "monospace"))
        ),
      )
    );*/

    // convert tokens to spans
    List<InlineSpan> spans = [];

    _StyleStack styleStack = _StyleStack(null);

    //int cursorColumn = 13;
    //int cursorLine = 5;

    int column = 0;

    TextStyle? prevStyle;

    if (cursorColumn == 0 && cursorLine == line && (tokens.internal.isEmpty
        || (tokens.internal.length == 1 && tokens.internal.first is _TextToken && (tokens.internal.first as _TextToken).text == ""))) {
//      print(tokens.internal);
      spans.add(WidgetSpan(
          //alignment: ui.PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(
                      width: 1.2,
                      color: (styleStack.peek() ?? prevStyle)?.color ?? Colors.black,
                    )
                )
            ),
            child: Text("",
                style: (styleStack.peek() ?? prevStyle)?.copyWith(
                    letterSpacing: -1.2, fontFamily: "monospace"))
          )
      ));
    }

    for (_Token token in tokens.internal) {
      if (token is _PushStyleToken) {
        styleStack.push(token.style);
        prevStyle = token.style;
      } else if (token is _TextToken) {
        if (line != cursorLine || column > cursorColumn || column + token.text.length < cursorColumn) {
          spans.add(TextSpan(
              text: token.text,
              style: styleStack.peek(),
              mouseCursor: MaterialStateMouseCursor.textable
          ));
        } else {
          int localCursor = cursorColumn - column;

          String preCursor = token.text.substring(0, localCursor);
          spans.add(TextSpan(
              text: preCursor,
              style: styleStack.peek(),
              mouseCursor: MaterialStateMouseCursor.textable
          ));

          if (localCursor + 1 <= token.text.length) {
            String underCursor = token.text.substring(
                localCursor, localCursor + 1);
            /*spans.add(TextSpan(
              text: underCursor,
              style: _styleStack.peek()?.copyWith(color: Colors.red),
          ));*/
            spans.add(WidgetSpan(
                alignment: ui.PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(
                            width: 1.2,
                            color: (styleStack.peek() ?? prevStyle)?.color ?? Colors.purpleAccent,
                          )
                      )
                  ),
                  child: Text(underCursor,
                      style: (styleStack.peek() ?? prevStyle)?.copyWith(
                          letterSpacing: -1.2, fontFamily: "monospace"))
                )
            ));

            String postCursor = token.text.substring(localCursor + 1);
            spans.add(TextSpan(
                text: postCursor,
                style: styleStack.peek(),
                mouseCursor: MaterialStateMouseCursor.textable
            ));
          }
        }
        column += token.text.length;
      } else if (token is _PopStyleToken) {
        styleStack.pop();
      } else {
        throw "Unexpected token $token (${token.runtimeType})";
      }
    }

    spans.add(CustomWidgetSpan(
        child: const SizedBox(height: 1, width: 8),
        line: line)
    );
    return spans;
  }

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    var textStyle = TextStyle(
      fontFamily: CodeEditor._defaultFontFamily,
      color: widget.theme[CodeEditor._rootKey]?.color ?? CodeEditor._defaultFontColor,
    );
    /*Result result = highlight.parse(text, language: language);
    return Container(
      color: theme[_rootKey]?.backgroundColor ?? _defaultBackgroundColor,
      child: RichText(
        text: TextSpan(
          style: textStyle,
          children: _convert(result.nodes!),
        ),
      )
    );*/
    // fixme this is broken use editor_from_scratch
    return GestureDetector(
      child: Focus(
        focusNode: focusNode,
        autofocus: true,
        child: Container(
          color: widget.theme[CodeEditor._rootKey]?.backgroundColor ?? CodeEditor._defaultBackgroundColor,
          child: ListView.builder(itemBuilder: (context, line) {
            if (line >= widget.lines.length) {
              return null;
            }
            return RichText(
              text: TextSpan(
                style: textStyle,
                children: _convert(highlight.parse(widget.lines[line], language: widget.language).nodes!, line),
                mouseCursor: MaterialStateMouseCursor.textable
              )
            );
          })
        ),
        onKey: (FocusNode node, RawKeyEvent event) {
          return KeyEventResult.handled;
        },
      ),
      onTapDown: (TapDownDetails details) {
        Offset o = screenToCursor(context.findRenderObject(), details.globalPosition);
        print(o);
        setState(() {
          cursorLine = o.dy.round();
          cursorColumn = o.dx.round();
        });
      },
    );
  }
}