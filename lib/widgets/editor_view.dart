/*
 * Copyright (c) 2023-2024 Sam Wagenaar
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
 *
 * Copyright (c) 2022 icedman
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

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_dart/msp430_dart.dart' show LineId;
import 'package:msp430_emulator/language_def/tutor.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/utils/flags.dart';
import 'package:provider/provider.dart';
import 'package:msp430_dart/msp430_dart_assembler.dart' as msp430;

import '../state/editor/highlighter.dart';
import '../state/editor/document.dart';

const int caretHideInterval = 350;
const int caretShowInterval = 550;

class CaretPulse extends ChangeNotifier {
  bool show = false;
  Timer timer = Timer(const Duration(milliseconds: 0), () {});

  CaretPulse() {
    Future.delayed(const Duration(milliseconds: 0), flipCaret);
  }

  void flipCaret() {
    timer.cancel();
    timer = Timer(
        Duration(milliseconds: show ? caretShowInterval : caretHideInterval),
            () {
          show = !show;
          notifyListeners();
          flipCaret();
        });
  }

  void cancel() {
    timer.cancel();
  }
}

enum AssemblyStatus {
  success(ColorExtension.selectedGreen),
  unknown(Colors.amber),
  failure(Colors.red)
  ;
  final Color color;

  const AssemblyStatus(this.color);

  static AssemblyStatus fromSuccess(bool success) {
    return success ? AssemblyStatus.success : AssemblyStatus.failure;
  }
}

class DocumentProvider extends ChangeNotifier {
  BuildContext? _bucketContext;
  PageStorageBucket? _storageBucket;
  final Document doc = Document();
  final Map<String, void Function(BuildContext context, PageStorageBucket bucket)> _onRestore = {};
  // {lineNumberToDisplayOn: {'$fileName:$line'?: error msg}}
  final Map<int, Map<String?, String>> assemblyErrors = {};
  Map<int, Pair<int, List<int>>> _assembledLines = {};
  Map<int, Pair<int, List<int>>> get assembledLines => _assembledLines;

  bool _tutorEnabled = false;
  bool get tutorEnabled => _tutorEnabled;
  void toggleTutor() {
    _tutorEnabled = !_tutorEnabled;
    touch();
  }

  bool _showAssembled = false;
  bool get showAssembledData => _showAssembled;
  void toggleShowAssembled() {
    _showAssembled = !_showAssembled;
    touch();
  }

  AssemblyStatus get assemblyStatus {
    if (doc.unsavedChanges) {
      _assemblyStatus = AssemblyStatus.unknown;
    }
    return _assemblyStatus;
  }
  AssemblyStatus _assemblyStatus = AssemblyStatus.unknown;

  Future<void> assemble(ScaffoldMessengerState scaffoldMessenger) async {
    assemblyErrors.clear();
    assembledLines.clear();
    String contents = await doc.saveFile(path: doc.docPath);
    handleErrors(Map<LineId, String> errorMap) {
      for (MapEntry<LineId, String> entry in errorMap.entries) {
        int toDisplayOn = entry.key.includedByLine ?? entry.key.first;
        String? lineDesc = entry.key.second.isEmpty ? null : "${entry.key.second}:::${entry.key.first + 1}";
        if (!assemblyErrors.containsKey(toDisplayOn) || !assemblyErrors[toDisplayOn]!.containsKey(lineDesc)) { // associate first error for a line with that line
          if (assemblyErrors[toDisplayOn] == null) {
            assemblyErrors[toDisplayOn] = {};
          }
          assemblyErrors[toDisplayOn]![lineDesc] = entry.value;
        }
      }
    }
    Uint8List? assembled;
    msp430.MutableObject<msp430.ListingGenerator> listing = msp430.MutableObject();
    try {
      assembled = msp430.parse(
          contents,
          errorConsumer: handleErrors,
          silent: true,
          containingDirectory: Directory.fromUri(Uri.file(
              msp430.filePathToDirectory(doc.docPath)
          )),
          listingGen: listing
      );
    } catch (ignored) {
      assembled = null;
      listing.clear();
    }

    _assemblyStatus = AssemblyStatus.fromSuccess(assembled != null);
    _assembledLines = {};
    if (listing.get() != null) {
      for (msp430.ListingEntry line in listing.get()!.entries) {
        if (line.line.second != "") continue;
        _assembledLines[line.line.first] = Pair(line.pc, line.words);
      }
    }

    if (assembled != null) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text("Assembly of ${doc.docPath} succeeded!"),
        backgroundColor: ColorExtension.deepSlateBlue
      ));
      await msp430.writeCompiledByName(assembled, doc.docPath.replaceAll(".asm", ".bin"));
      if (listing.get() != null) {
        var listingFile = File(doc.docPath.replaceAll(".asm", ".lst"));
        await listingFile.writeAsString(listing.get()!.output(), flush: true);
      }
    } else {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: Text("Assembly of ${doc.docPath} failed!"),
          backgroundColor: Colors.red.shade900
      ));
    }

    touch();
  }

  /// restoreInPlace - if true, old lines will be returned as public 'lines' while loading new lines
  Future<bool> openFile(String path, {bool restoreInPlace = false}) async {
    bool res = await doc.openFile(path, restoreInPlace: restoreInPlace);
    touch();
    return res;
  }

  void touch() {
    notifyListeners();
  }

  void maybeInit(BuildContext context) {
    _bucketContext = context;
    _storageBucket = PageStorage.of(context);
  }

  @override
  void dispose() {
    doc.saveFile(path: doc.docPath);
    if (_bucketContext != null && _storageBucket != null) {
      doc.writeToBucket(_bucketContext!, _storageBucket!);
      _storageBucket!.writeState(_bucketContext!, _tutorEnabled, identifier: const ValueKey("tutorEnabled"));
      _storageBucket!.writeState(_bucketContext!, _assembledLines, identifier: const ValueKey("assembledLines"));
      _storageBucket!.writeState(_bucketContext!, _showAssembled, identifier: const ValueKey("showAssembled"));
    }
    super.dispose();
  }

  void restore(bool restoreTextFromBucket) {
    if (_bucketContext != null && _storageBucket != null) {
      doc.restoreFromBucket(_bucketContext!, _storageBucket!, restoreTextFromBucket);
      _tutorEnabled = _storageBucket!.readState(_bucketContext!, identifier: const ValueKey("tutorEnabled")) ?? false;
      _assembledLines = _storageBucket!.readState(_bucketContext!, identifier: const ValueKey("assembledLines")) ?? {};
      _showAssembled = _storageBucket!.readState(_bucketContext!, identifier: const ValueKey("showAssembled")) ?? false;
      for (void Function(BuildContext context, PageStorageBucket bucket) f in _onRestore.values) {
        f(_bucketContext!, _storageBucket!);
      }
    }
  }

  void onRestore(String key, void Function(BuildContext context, PageStorageBucket bucket) f) {
    _onRestore[key] = f;
  }

  /*@override
  void dispose() {}

  void actuallyDispose() {
    super.dispose();
  }*/
}

const tutorAlignColumn = 20;

String? generateError(Map<String?, String>? error) {
  if (error == null || error.isEmpty) return null;
  String out = error[null] ?? "";
  for (MapEntry<String?, String> entry in error.entries) {
    if (entry.key == null) continue;
    List<String> split = entry.key!.split(":::");
    out += "\n; <${split[0]}: ${split[1]}>: ${entry.value}";
  }
  return out;
}

class ViewLine extends StatelessWidget {
  const ViewLine({this.lineNumber = 0, this.text = '', super.key});

  final int lineNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    CaretPulse pulse = Provider.of<CaretPulse>(context);
    Highlighter hl = Provider.of<Highlighter>(context);
    Pair<List<InlineSpan>, Color?> spansAndColor = hl.run(
        text, lineNumber, doc.doc);
    List<InlineSpan> spans = spansAndColor.first;
    List<Widget> carets = [];
    final bool isActiveLine = doc.doc.cursor.line == lineNumber;

    bool lineHasError = doc.assemblyErrors.containsKey(lineNumber);

    if (lineHasError) {
      spans.insert(spans.length - 1, IgnorableTextSpan(
          ignoreForCursor: true,
          children: [
            const WidgetSpan(child: SizedBox(width: 40)),
            TextSpan(
              text: "; ${generateError(doc.assemblyErrors[lineNumber]) ?? ''}",
              style: GoogleFonts.firaCode(
                textStyle: editorTheme['comment'],
                fontSize: fontSize,
                decoration: TextDecoration.underline,
                decorationThickness: 4,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: Colors.red,
              ),
            )
          ]
      ));
    } else if (doc.tutorEnabled && doc.doc.cursor.line <= lineNumber && lineNumber <= doc.doc.cursor.line+2) {
      /* Assemble relevant line */
      int existingChars = 0;
      for (final span in spans) {
        if (span is TextSpan) {
          existingChars += span.getCharCount();
        }
      }
      final line = msp430.Line(LineId(doc.doc.cursor.line, ""), doc.doc.lines[doc.doc.cursor.line]);
      final List<msp430.Pair<msp430.Line, String>> errors = [];

      bool failed = false;
      List<msp430.Token<dynamic>> tokens;
      try {
        tokens = msp430.parseTokens([line], errors);
      } catch (e) {
        tokens = [];
        failed = true;
      }
      List<msp430.Pair<LineId, String>> instrErrors = [];
      msp430.Instruction? instruction;
      if (!failed) {
        try {
          final instructions = msp430.parseInstructions(tokens, instrErrors);
          if (instructions.isNotEmpty) {
            instruction = instructions[0];
          }
        } catch (e) {
          failed = true;
        }
      }

      if (errors.isEmpty && instrErrors.isEmpty && !failed) {
        String? mnemonic;

        final stream = msp430.TokenStream(tokens);
        while (stream.isNotEmpty) {
          final token = stream.pop();
          if (token.token == msp430.Tokens.lineStart) continue;
          if (token.token == msp430.Tokens.mnemonic) {
            mnemonic = token.value;
          }
          break;
        }

        String? msg;

        if (mnemonic != null && isActiveLine) {
          msg = mnemonicTutors[mnemonic];
        } else if (lineNumber == doc.doc.cursor.line + 1 && instruction != null) {
          final msp430.Operand? src;
          final bool bw;
          if (instruction is msp430.SingleOperandInstruction) {
            src = instruction.op1;
            bw = instruction.bw;
          } else if (instruction is msp430.DoubleOperandInstruction) {
            src = instruction.src;
            bw = instruction.bw;
          } else {
            src = null;
            bw = false;
          }

          if (src != null) {
            final description = describeOperand(src, bw) ?? "unknown description";
            msg = "^ src: $description";
          }
        } else if (lineNumber == doc.doc.cursor.line + 2 && instruction != null) {
          final msp430.Operand? dst;
          final bool bw;
          if (instruction is msp430.DoubleOperandInstruction) {
            dst = instruction.dst;
            bw = instruction.bw;
          } else {
            dst = null;
            bw = false;
          }

          if (dst != null) {
            final description = describeOperand(dst, bw)  ?? "unknown description";
            msg = "^ dst: $description";
          }
        }

        if (msg != null) {
          final int paddingAmt = max(tutorAlignColumn - existingChars, 0);
          spans.insert(spans.length - 1, IgnorableTextSpan(
              ignoreForCursor: true,
              children: [
                const WidgetSpan(child: SizedBox(width: 40)),
                TextSpan(
                  text: "${" " * paddingAmt}; $msg",
                  style: GoogleFonts.firaCode(
                    textStyle: editorTheme['comment']?.copyWith(
                        color: Colors.lightBlue),
                    fontSize: fontSize,
                    /*decoration: TextDecoration.underline,
                  decorationThickness: 4,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: Colors.lightBlue,*/
                  ),
                )
              ]
          ));
        }
      }
    }

    final gutterStyle = GoogleFonts.firaCode(
        fontSize: gutterFontSize,
        color: lineHasError ? Colors.red : editorTheme['comment']?.color,
        fontWeight: lineHasError ? FontWeight.bold : null
    );
    final String gutterPrefix;
    if (doc.showAssembledData) {
      Pair<int, List<int>>? assembledLine = doc.assembledLines[lineNumber];
      if (assembledLine != null) {
        List<String> out = [];
        for (int i = 0; i < 3; i++) {
          if (i < assembledLine.second.length) {
            out.add(assembledLine.second[i].hexString4);
          } else {
            out.add(" "*4);
          }
        }
        String paddedWords = out.join(" ");

        gutterPrefix = "0x${assembledLine.first.hexString4}  $paddedWords";
      } else {
        gutterPrefix = " " * "0x4242  1111 2222 3333".length;
      }
    } else {
      gutterPrefix = "";
    }
    double gutterPadding = 3;
    double gutterWidth =
        getTextExtents(' $gutterPrefix${gutterPrefix.isNotEmpty ? "  " : ""}${doc.doc.lines.length} ', gutterStyle).width + gutterPadding;

    //Offset pos = Offset.zero;
    Size extents = Size.zero;
    Size size = Size.zero;
    RenderObject? obj = context.findRenderObject();
    RenderBox? box;
    if (obj != null) {
      box = obj as RenderBox;
      size = box.size;
      //pos = box.localToGlobal(pos);
    }

    TextPainter? textPainter;
    TextPainter? painter() {
      if (size.width > 0 && spans.isNotEmpty && spans[0] is TextSpan) {
        TextSpan ts = spans[0] as TextSpan;
        extents = getTextExtents('|', ts.style ?? const TextStyle());
        return TextPainter(
            text: TextSpan(text: text, style: ts.style),
            textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: size.width - gutterWidth);
      }
      return null;
    }

    textPainter ??= painter();

    Offset caretOffset = textPainter?.getOffsetForCaret(TextPosition(offset: doc.doc.cursor.column), Rect.zero) ?? Offset.zero;

    if (isActiveLine) {
      double w = 2;
      double h = extents.height;
      carets.add(Positioned(
          left: gutterWidth + caretOffset.dx,
          top: caretOffset.dy,
          child: Container(
            width: w,
            height: h,
            color: pulse.show ? spansAndColor.second : null,
          )
      ));
    }

    return Stack(children: [
      if (isActiveLine)
        Container(
          color: selection.withOpacity(0.25),
          child: const Center(
            child: Text(""),
          ),
      ),// */
      Padding(
        padding: EdgeInsets.only(left: gutterWidth),
        child: RichText(text: TextSpan(children: spans), softWrap: true)
      ),
      Container(
        width: gutterWidth - gutterPadding,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: lineHasError ? Colors.red : editorTheme['root']?.color ?? Colors.black
            )
          )
        ),
        child: Tooltip(
          message: generateError(doc.assemblyErrors[lineNumber]) ?? "Toggle assembled preview",
          child: InkWell(
            onTap: doc.toggleShowAssembled,
            child: Text('${lineNumber + 1} ', style: gutterStyle),
          ),
        )
      ),
      if (gutterPrefix.isNotEmpty)
        Container(
          width: gutterWidth - gutterPadding,
          alignment: Alignment.centerLeft,
          /*decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(
                      color: lineHasError ? Colors.red : editorTheme['root']?.color ?? Colors.black
                  )
              )
          ),*/
          child: Text(' $gutterPrefix', style: gutterStyle)
        ),
      ...carets
    ]);
  }
}

class AnimatedCursor extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const AnimatedCursor({super.key, required this.width, required this.height, this.color});

  @override
  Widget build(BuildContext context) {
    CaretPulse pulse = Provider.of<CaretPulse>(context);
    return Container(
      width: width,
      height: height,
      color: pulse.show ? color : null
    );
  }
}

class View extends StatefulWidget {
  const View({super.key, this.path = ''});

  final String path;

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  late ScrollController scroller;

  @override
  void initState() {
    msp430.initInstructionInfo();
    scroller = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    return Container(
      color: editorTheme['root']?.backgroundColor,
      child: MouseRegion(
        cursor: MaterialStateMouseCursor.textable,
        child: ListView.builder(
          key: PageStorageKey<String>("scroller_for_${doc.doc.docPath}"),
          controller: scroller,
          itemCount: doc.doc.lines.length,
          itemBuilder: (BuildContext context, int index) {
            return ViewLine(lineNumber: index, text: doc.doc.lines[index]);
          }),
      ),
    );
  }}