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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/shmem.dart';

const int bytesPerLine = 16;

class AddressScrollRequester {
  AddressScrollRequester();

  final Map<Object, void Function(int address)> _handlers = {};
  void request(int address) {
    for (var handler in _handlers.values) {
      handler(address);
    }
  }

  Object registerHandler(void Function(int address) handler) {
    Object key = Object();
    _handlers[key] = handler;
    return key;
  }

  void clearHandler(Object key) {
    _handlers.remove(key);
  }
}

class _MemoryLineKey extends ValueKey<int> {
  const _MemoryLineKey(super.value);
}

/*class _TimeoutTracker {
  DateTime _endTime = DateTime.fromMicrosecondsSinceEpoch(0);
  void timeout(Duration duration) {
    DateTime end = DateTime.now().add(duration);
    if (end.isAfter(_endTime)) {
      _endTime = end.add(duration);
    }
  }

  bool get isTimedOut => DateTime.now().isBefore(_endTime);
}*/

class MemoryView extends StatefulWidget {
  final AddressScrollRequester scrollRequester;
  const MemoryView({super.key, required this.scrollRequester});

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView> {

  late ScrollController scroller;
  late Object _scrollRequestHandlerKey;
  //final _TimeoutTracker _timeout = _TimeoutTracker();

  @override
  void initState() {
    scroller = ScrollController();
    //scroller.addListener(() => _timeout.timeout(const Duration(milliseconds: 600)));
    _scrollRequestHandlerKey = widget.scrollRequester.registerHandler(_scrollToAddress);
    super.initState();
  }

  @override
  void dispose() {
    scroller.dispose();
    widget.scrollRequester.clearHandler(_scrollRequestHandlerKey);
    super.dispose();
  }

  /*int _getChildCount([Element? element]) {
    int count = 0;
    if (element == null) {
      context.visitChildElements((element) {
        count += _getChildCount(element);
      });
    }

    element?.visitChildElements((element) {
      if (element.widget is _MemoryViewLine) {
        count += 1;
      } else {
        count += _getChildCount(element);
      }
    });
    return count;
  }*/

  double? _getLineHeight([Element? element]) {
    double? height;
    if (element == null) {
      context.visitChildElements((element) {
        height ??= _getLineHeight(element);
      });
    }
    element?.visitChildElements((element) {
      if (element.widget is _MemoryViewLine) {
        height ??= element.renderObject?.semanticBounds.height ?? 0;
      } else {
        height ??= _getLineHeight(element);
      }
    });
    return height;
  }

  void _scrollTo(int index) {
    double? height = _getLineHeight();
    double target = (height ?? 20) * (index + 0.5);
    scroller.animateTo(
      target,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut
    );
    //scroller.jumpTo(target);
  }

  void _scrollToAddress(int address) {
    _scrollTo((address/16).floor());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorExtension.deepSlateBlue.withBrightness(0.5),
      child: ListView.builder(
        key: const PageStorageKey<String>("scroller_for_mem_view"),//_listKey,
        padding: const EdgeInsets.all(8),
        controller: scroller,
        itemCount: (0x10000 / bytesPerLine).round(), // 16 bytes per line
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
        prototypeItem: const _MemoryViewLine(index: 0, key: _MemoryLineKey(0)),
      ),
    );
  }
}

class _MemoryViewLine extends StatelessWidget {
  static final TextStyle textStyle = GoogleFonts.firaCode(fontSize: 14, color: ColorExtension.selectedGreen);
  static final TextStyle textStyle2 = GoogleFonts.firaCode(fontSize: 14, color: ColorExtension.unselectedGreen);
  static final TextStyle pcStyle = GoogleFonts.firaCode(fontSize: 14, color: Colors.cyanAccent);

  final int index;

  const _MemoryViewLine({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final RegistersProvider reg = Provider.of<RegistersProvider>(context);
    final MemoryProvider mem = Provider.of<MemoryProvider>(context);

    int pc = reg.getValue(0);
    int sp = reg.getValue(1);

    int lineStartAddress = index * bytesPerLine;

    String lineString = "";

    for (int i = 0; i < bytesPerLine; i++) {
      int memVal = mem.get(lineStartAddress + i);
      lineString += memVal < 32 || memVal > 126 ? "." : String.fromCharCode(memVal);
    }

    List<InlineSpan> spans = [
      for (int i = 0; i < bytesPerLine/2; i++)
        ...[
          TextSpan(
              text: mem.getWord(lineStartAddress + i*2).hexString4.replaceAll("0000", "----"),
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
          const WidgetSpan(child: SizedBox(width: 10)),
        ],
    ];

    TextSpan parentSpan = TextSpan(children: spans);

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
        RichText(text: parentSpan, softWrap: false),
        const SizedBox(width: 30),
        Text(
          lineString,
          style: textStyle
        ),
      ],
    );
  }
}