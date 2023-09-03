import 'dart:async';

import 'package:flutter/material.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/computer/isolated_computer.dart';

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
  late Key _listKey;
  final _TimeoutTracker _timeout = _TimeoutTracker();

  @override
  void initState() {
    scroller = ScrollController();
    scroller.addListener(() => _timeout.timeout(const Duration(milliseconds: 600)));
    _listKey = const Key("listViewMemoryThing");
    super.initState();
  }
  
  @override
  void dispose() {
    scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MainSideComputer computer = Provider.of<MainSideComputer>(context, listen: false);
    return Expanded(
      child: Container(
        color: ColorExtension.deepSlateBlue,
        child: ListView.builder(
          key: _listKey,
          padding: const EdgeInsets.all(8),
          controller: scroller,
          itemCount: (0x10000 / bytesPerLine).round() - 1, // 16 bytes per line
          itemBuilder: (BuildContext context, int idx) {
            return _MemoryViewLine(
              key: _MemoryLineKey(idx),
              index: idx,
              computer: computer,
              timeoutTracker: _timeout,
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

class _MemoryViewLine extends StatefulWidget {
  const _MemoryViewLine({super.key, required this.index, required this.computer, required this.timeoutTracker});
  final int index;
  final MainSideComputer computer;
  final _TimeoutTracker timeoutTracker;

  @override
  State<_MemoryViewLine> createState() => _MemoryViewLineState();
}

class _MemoryViewLineState extends State<_MemoryViewLine> {

  MemorySection? _memorySection;
  bool _disposed = false;
  final Object _changeKey = Object();
  final Object _registerChangeKey = Object();

  @override
  void initState() {
    _disposed = false;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (!widget.timeoutTracker.isTimedOut) {
        timer.cancel();
        _memorySection = widget.computer.trackMemory(
            widget.index * bytesPerLine,
            widget.index * bytesPerLine + bytesPerLine);
        _memorySection?.onChanged[_changeKey] = () => setState(() {});

        widget.computer.trackedRegisters.onChanged[_registerChangeKey] = () => setState(() {});
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_memorySection != null) {
      _memorySection!.onChanged.remove(_changeKey);
      int id = _memorySection!.id;
      _memorySection = null;
      Future.delayed(const Duration(microseconds: 1), () => widget.computer.untrackMemory(id));
    }
    widget.computer.trackedRegisters.onChanged.remove(_registerChangeKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MemorySection? memory = _memorySection;
    const TextStyle textStyle = TextStyle(fontFamily: fontFamily, fontSize: 14, color: ColorExtension.selectedGreen);
    const TextStyle textStyle2 = TextStyle(fontFamily: fontFamily, fontSize: 14, color: ColorExtension.unselectedGreen);
    const TextStyle pcStyle = TextStyle(fontFamily: fontFamily, fontSize: 14, color: Colors.cyanAccent);

    int pc = widget.computer.trackedRegisters.getIndexed(0);
    int sp = widget.computer.trackedRegisters.getIndexed(1);

    int lineStartAddress = widget.index * bytesPerLine;

    return Row(
      children: [
        Text(
          "0x${(widget.index * bytesPerLine).hexString4}",
          style: wrap<TextStyle>(
            (pc / bytesPerLine).floor() == widget.index
              ? pcStyle
              : textStyle,
              (sp / bytesPerLine).floor() == widget.index,
              (t) => t.copyWith(backgroundColor: Colors.deepPurple)
          )
        ),
        const SizedBox(width: 20),
        for (int i = 0; i < bytesPerLine/2; i++)
          ...[
            Text(
              memory == null ? "...." : memory.getWordIndexed(i*2).hexString4.replaceAll("0000", "----"),
              style: wrap<TextStyle>(
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
      ],
    );
  }
}