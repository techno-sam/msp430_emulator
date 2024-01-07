/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2024  Sam Wagenaar
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_dart/src/basic_datatypes.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart' as hl;
import 'package:msp430_emulator/state/shmem.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

class DisassemblyView extends StatefulWidget {
  const DisassemblyView({super.key});

  @override
  State<DisassemblyView> createState() => _DisassemblyViewState();
}

class _DisassemblyViewState extends State<DisassemblyView> {

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
  Widget build(BuildContext context) {
    MemoryProvider mem = context.watch<MemoryProvider>();
    final List<Pair<int, String>>? dis = mem.disassembled?.toList(growable: false);
    return Container(
      color: ColorExtension.deepSlateBlue.withBrightness(0.5),
      child: dis == null || dis.isEmpty
          ? const Center(child: Text("Load a program to view disassembly", style: TextStyle(color: ColorExtension.selectedGreen),))
          : ListView.builder(
            key: const PageStorageKey<String>("scroller_for_dis_view"),
            padding: const EdgeInsets.all(8.0),
            controller: scroller,
            itemCount: dis.length,
            itemBuilder: (BuildContext context, int idx) {
              Pair<int, String> data = dis[idx];
              return _DisassemblyLine(address: data.first, text: data.second);
            },
            prototypeItem: _DisassemblyLine.prototype,
          )
    );
  }
}

class _DisassemblyLine extends StatelessWidget {
  static const _DisassemblyLine prototype = _DisassemblyLine(address: 42, text: "everything");
  static const hl.Highlighter _hl = hl.Highlighter();

  final int address;
  final String text;

  const _DisassemblyLine({super.key, required this.address, required this.text});

  @override
  Widget build(BuildContext context) {
    final reg = context.watch<RegistersProvider>();
    bool active = address == reg.getValue(0);
    hl.Pair<List<InlineSpan>, Color?> spansAndColor = _hl.run(text, address);
    List<InlineSpan> spans = spansAndColor.first;

    final gutterStyle = GoogleFonts.firaCode(
        fontSize: hl.gutterFontSize,
        color: active ? Colors.cyanAccent : hl.editorTheme['comment']?.color,
    );

    double gutterPadding = 3;
    double gutterWidth =
        hl.getTextExtents(' 0x0000 ', gutterStyle).width + gutterPadding;

    Size size = Size.zero;
    RenderObject? obj = context.findRenderObject();
    RenderBox? box;
    if (obj != null) {
      box = obj as RenderBox;
      size = box.size;
    }

    TextPainter? textPainter;
    TextPainter? painter() {
      if (size.width > 0 && spans.isNotEmpty && spans[0] is TextSpan) {
        TextSpan ts = spans[0] as TextSpan;
        return TextPainter(
            text: TextSpan(text: text, style: ts.style),
            textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: size.width - gutterWidth);
      }
      return null;
    }

    textPainter ??= painter();

    return Stack(children: [
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
                      color: active ? Colors.cyanAccent : hl.editorTheme['root']?.color ?? Colors.black
                  )
              )
          ),
          child: Text('0x${address.hexString4} ', style: gutterStyle)
      ),
    ]);
  }
}