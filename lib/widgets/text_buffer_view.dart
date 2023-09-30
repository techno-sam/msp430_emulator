// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/state/shmem.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

class TextBufferView extends StatelessWidget {
  const TextBufferView({super.key});

  @override
  Widget build(BuildContext context) {
    MemoryProvider memoryProvider = Provider.of<MemoryProvider>(context);

    List<Text> lines = [];

    for (int lineNo = 0; lineNo < 24; lineNo++) {
      int address = 0xfc00 + lineNo * 32;
      String line = "";
      for (int i = 0; i < 32; i++) {
        int memVal = memoryProvider.get(address + i);
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