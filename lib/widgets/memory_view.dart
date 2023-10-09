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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/shmem.dart';

const int bytesPerLine = 16;

class _MemoryLineKey extends ValueKey<int> {
  const _MemoryLineKey(super.value);
}

class _TimeoutTracker {
  DateTime _endTime = DateTime.fromMicrosecondsSinceEpoch(0);
  void timeout(Duration duration) {
    DateTime end = DateTime.now().add(duration);
    if (end.isAfter(_endTime)) {
      _endTime = end.add(duration);
    }
  }

  bool get isTimedOut => DateTime.now().isBefore(_endTime);
}

class MemoryView extends StatefulWidget {
  const MemoryView({super.key});

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView> {

  late ScrollController scroller;
  final _TimeoutTracker _timeout = _TimeoutTracker();

  @override
  void initState() {
    scroller = ScrollController();
    scroller.addListener(() => _timeout.timeout(const Duration(milliseconds: 600)));
    super.initState();
  }
  
  @override
  void dispose() {
    scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: ColorExtension.deepSlateBlue.withBrightness(0.5),
        child: ListView.builder(
          key: const PageStorageKey<String>("scroller_for_mem_view"),//_listKey,
          padding: const EdgeInsets.all(8),
          controller: scroller,
          itemCount: (0x10000 / bytesPerLine).round() - 1, // 16 bytes per line
          itemBuilder: (BuildContext context, int idx) {
            return _MemoryViewLine(
              key: _MemoryLineKey(idx),
              index: idx,
            );
          },
          findChildIndexCallback: (key) {
            if (key is _MemoryLineKey) {
              return key.value;
            } else {
              return null;
            }
          },
        ),
      ),
    );
  }
}

/*class _MemoryViewLine extends StatefulWidget {
  const _MemoryViewLine({super.key, required this.index, required this.computer, required this.timeoutTracker});
  final int index;
  final MainSideComputer computer;
  final _TimeoutTracker timeoutTracker;

  @override
  State<_MemoryViewLine> createState() => _MemoryViewLineState();
}*/

class _MemoryViewLine extends StatelessWidget {

  final int index;

  const _MemoryViewLine({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final RegistersProvider reg = Provider.of<RegistersProvider>(context);
    final MemoryProvider mem = Provider.of<MemoryProvider>(context);
    TextStyle textStyle = GoogleFonts.firaCode(fontSize: 14, color: ColorExtension.selectedGreen);
    TextStyle textStyle2 = GoogleFonts.firaCode(fontSize: 14, color: ColorExtension.unselectedGreen);
    TextStyle pcStyle = GoogleFonts.firaCode(fontSize: 14, color: Colors.cyanAccent);

    int pc = reg.getValue(0);
    int sp = reg.getValue(1);

    int lineStartAddress = index * bytesPerLine;

    String lineString = "";

    for (int i = 0; i < bytesPerLine; i++) {
      int memVal = mem.get(lineStartAddress + i);
      lineString += memVal < 32 || memVal > 126 ? "." : String.fromCharCode(memVal);
    }

    return Row(
      children: [
        Text(
          "0x${(index * bytesPerLine).hexString4}",
          style: applyConditional<TextStyle>(
            (pc / bytesPerLine).floor() == index
              ? pcStyle
              : textStyle,
              (sp / bytesPerLine).floor() == index,
              (t) => t.copyWith(backgroundColor: Colors.deepPurple)
          )
        ),
        const SizedBox(width: 20),
        for (int i = 0; i < bytesPerLine/2; i++)
          ...[
            Text(
              mem.getWord(lineStartAddress + i*2).hexString4.replaceAll("0000", "----"),
              style: applyConditional<TextStyle>(
                (lineStartAddress + (i * 2) == pc)
                  ? pcStyle
                  : (i % 2 == 1 ? textStyle : textStyle2),
                  (lineStartAddress + (i * 2)) == sp,
                  (t) => t.copyWith(
                    backgroundColor: Colors.deepPurple
                  )
              )
            ),
            const SizedBox(width: 10),
          ],
        const SizedBox(width: 30),
        Text(
          lineString,
          style: textStyle
        ),
      ],
    );
  }
}