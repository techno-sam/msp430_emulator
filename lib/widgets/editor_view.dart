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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/utils/flags.dart';
import 'package:provider/provider.dart';
import 'package:msp430_dart/msp430_dart.dart' as msp430;

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
  final Map<int, String> assemblyErrors = {};

  AssemblyStatus get assemblyStatus {
    if (doc.unsavedChanges) {
      _assemblyStatus = AssemblyStatus.unknown;
    }
    return _assemblyStatus;
  }
  AssemblyStatus _assemblyStatus = AssemblyStatus.unknown;

  Future<void> assemble(ScaffoldMessengerState scaffoldMessenger) async {
    assemblyErrors.clear();
    String contents = await doc.saveFile(path: doc.docPath);
    handleErrors(Map<int, String> errorMap) {
      for (MapEntry<int, String> entry in errorMap.entries) {
        if (!assemblyErrors.containsKey(entry.key)) { // associate first error for a line with that line
          assemblyErrors[entry.key] = entry.value;
        }
      }
    }
    Uint8List? assembled = msp430.parse(contents, errorConsumer: handleErrors, silent: true);
    _assemblyStatus = AssemblyStatus.fromSuccess(assembled != null);

    if (assembled != null) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text("Assembly of ${doc.docPath} succeeded!"),
        backgroundColor: ColorExtension.deepSlateBlue
      ));
      await msp430.writeCompiledByName(assembled, doc.docPath.replaceAll(".asm", ".bin"));
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
    }
    super.dispose();
  }

  void restore(bool restoreTextFromBucket) {
    if (_bucketContext != null && _storageBucket != null) {
      doc.restoreFromBucket(_bucketContext!, _storageBucket!, restoreTextFromBucket);
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

class ViewLine extends StatelessWidget {
  const ViewLine({this.lineNumber = 0, this.text = '', super.key});

  final int lineNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    CaretPulse pulse = Provider.of<CaretPulse>(context);
    Highlighter hl = Provider.of<Highlighter>(context);
    Pair<List<InlineSpan>, Color?> spansAndColor = hl.run(text, lineNumber, doc.doc);
    List<InlineSpan> spans = spansAndColor.first;
    List<Widget> carets = [];

    bool lineHasError = doc.assemblyErrors.containsKey(lineNumber);

    if (lineHasError) {
      spans.insert(spans.length - 1, IgnorableTextSpan(
          ignoreForCursor: true,
          children: [
            const WidgetSpan(child: SizedBox(width: 40)),
            TextSpan(
              text: "; ${doc.assemblyErrors[lineNumber] ?? ''}",
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
    }

    final gutterStyle = GoogleFonts.firaCode(
        fontSize: gutterFontSize,
        color: lineHasError ? Colors.red : editorTheme['comment']?.color,
        fontWeight: lineHasError ? FontWeight.bold : null
    );
    double gutterPadding = 3;
    double gutterWidth =
        getTextExtents(' ${doc.doc.lines.length} ', gutterStyle).width + gutterPadding;

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

    if (doc.doc.cursor.line == lineNumber) {
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
      if (lineNumber == doc.doc.cursor.line)
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
          message: doc.assemblyErrors[lineNumber] ?? "",
          child: Text('${lineNumber + 1} ', style: gutterStyle),
        )
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