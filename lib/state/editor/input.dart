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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:msp430_emulator/utils/flags.dart';
import 'package:provider/provider.dart';

import '../../widgets/editor_view.dart';
import 'document.dart';
import 'highlighter.dart';

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
    offsetForCaret & Size(par.size.width * 1000, par.size.height);
    if (parBounds.inflate(4).contains(pos)) {
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

    if (span is IgnorableTextSpan && span.ignoreForCursor) {
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
    if (obj.text is IgnorableTextSpan && (obj.text as IgnorableTextSpan).ignoreForCursor) {
      return;
    }
    res.add(obj);
    return;
  }
  obj?.visitChildren((child) {
    findRenderParagraphs(child, res);
  });
}

class InputListener extends StatefulWidget {
  final Widget child;

  const InputListener({required this.child, super.key});
  @override
  State<InputListener> createState() => _InputListener();
}

class _InputListener extends State<InputListener> {
  late FocusNode focusNode;
  bool _shiftDown = false;

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

    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    Document d = doc.doc;
    return GestureDetector(
        child: Focus(
            // ignore: sort_child_properties_last
            child: widget.child,
            focusNode: focusNode,
            autofocus: true,
            onKey: (FocusNode node, RawKeyEvent event) {
              String key = event.character ?? '';
              if (event.logicalKey.keyLabel.length > 1) {
                key = event.logicalKey.keyLabel;
              }
              _shiftDown = event.isShiftPressed;
              if (event.runtimeType.toString() == 'RawKeyDownEvent') {
                switch (key) {
                  case 'Home':
                    if (event.isControlPressed) {
                      d.moveCursorToStartOfDocument();
                    } else {
                      d.moveCursorToStartOfLine();
                    }
                    break;
                  case 'End':
                    if (event.isControlPressed) {
                      d.moveCursorToEndOfDocument();
                    } else {
                      d.moveCursorToEndOfLine();
                    }
                    break;
                  case 'Tab':
                    d.insertText('    ');
                    break;
                  case 'Enter':
                    d.deleteSelectedText();
                    d.insertNewLine();
                    break;
                  case 'Backspace':
                    if (d.cursor.hasSelection()) {
                      d.deleteSelectedText();
                    } else {
                      d.moveCursorLeft();
                      d.deleteText();
                    }
                    break;
                  case 'Delete':
                    if (d.cursor.hasSelection()) {
                      d.deleteSelectedText();
                    } else {
                      d.deleteText();
                    }
                    break;
                  case 'Arrow Left':
                    d.moveCursorLeft(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Right':
                    d.moveCursorRight(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Up':
                    d.moveCursorUp(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Down':
                    d.moveCursorDown(keepAnchor: event.isShiftPressed);
                    break;
                  default:
                    {
                      int k = event.logicalKey.keyId;
                      if ((k >= LogicalKeyboardKey.keyA.keyId &&
                          k <= LogicalKeyboardKey.keyZ.keyId) ||
                          (k + 32 >= LogicalKeyboardKey.keyA.keyId &&
                              k + 32 <= LogicalKeyboardKey.keyZ.keyId)) {
                        String ch = String.fromCharCode(
                            97 + k - LogicalKeyboardKey.keyA.keyId);
                        if (event.isControlPressed) {
                          d.command('ctrl+$ch');
                          break;
                        }
                        /*if (event.isShiftPressed) {
                          ch = ch.toUpperCase();
                        }*/
                        /*if (event.character != null) {
                          d.insertText(event.character!);
                        }*/
                        if (key.length == 1) {
                          d.insertText(key);
                        }
                        break;
                      }
                    }
                    //if (event.logicalKey.keyLabel.length == 1) {
                    //  d.insertText(event.character!);//event.logicalKey.keyLabel);
                    //}
                    if (key.length == 1) {
                      d.insertText(key);
                    }
                    // print(event.logicalKey.keyLabel);
                    break;
                }
                doc.touch();
              }
              if (event.runtimeType.toString() == 'RawKeyUpEvent') {}
              return KeyEventResult.handled;
            }),
        onTapDown: (TapDownDetails details) {
          Offset o = screenToCursor(
              context.findRenderObject(), details.globalPosition);
          if (o.dx == -1 || o.dy == -1) return;
          d.moveCursor(o.dy.round(), (o.dx+0.5).round(), keepAnchor: (details.kind == PointerDeviceKind.mouse || details.kind == PointerDeviceKind.trackpad) && _shiftDown);
          doc.touch();
        },
        onPanUpdate: (DragUpdateDetails details) {
          Offset o = screenToCursor(
              context.findRenderObject(), details.globalPosition);
          if (o.dx == -1 || o.dy == -1) return;
          d.moveCursor(o.dy.round(), (o.dx+0.5).round(), keepAnchor: true);
          doc.touch();
        });
  }
}