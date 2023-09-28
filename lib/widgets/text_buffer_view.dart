import 'package:flutter/material.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/computer/isolated_computer.dart';

class TextBufferView extends StatefulWidget {
  const TextBufferView({super.key});

  @override
  State<TextBufferView> createState() => _TextBufferViewState();
}

class _TextBufferViewState extends State<TextBufferView> {

  TextBufferMemorySection? _textBuffer;

  @override
  void dispose() {
    _textBuffer?.onChanged.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MainSideComputer computer = Provider.of<MainSideComputer>(context, listen: false);
    if (_textBuffer == null) {
      _textBuffer = computer.textBuffer;
      _textBuffer!.onChanged[this] = () => setState(() {});
    }

    List<Text> lines = [];

    for (int lineNo = 0; lineNo < 24; lineNo++) {
      int address = lineNo * 32;
      String line = "";
      for (int i = 0; i < 32; i++) {
        int memVal = _textBuffer!.getIndexed(address + i);
        line += memVal < 32 || memVal > 126 ? " " : String.fromCharCode(memVal);
        if (i < 31) {
          line += " ";
        }
      }
      lines.add(Text(
          line,
          style: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              color: ColorExtension.selectedGreen
          )
      ));
    }

    return Expanded(
      child: Container(
        color: ColorExtension.deepSlateBlue.withOpacity(0.8),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: lines
        )
      ),
    );
  }
}