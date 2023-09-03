import 'package:flutter/material.dart';
import 'package:msp430_emulator/state/computer/isolated_computer.dart';
import 'package:msp430_emulator/state/computer/memory_section_provider.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

class RegisterList extends StatefulWidget {
  const RegisterList({super.key, required this.compact});

  final bool compact;

  @override
  State<RegisterList> createState() => _RegisterListState();
}

class _RegisterListState extends State<RegisterList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    MemorySectionProvider trackedRegisterProvider = Provider.of<MemorySectionProvider>(context);
    Map<int, String> namedRegisters = {
      0: "pc",
      1: "sp",
      2: "sr",
      3: "cg"
    };
    TextStyle textStyle = (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontFamily: fontFamily,
      fontSize: widget.compact ? 14 : fontSize,
      color: ColorExtension.selectedGreen
    );
    String flagString = "";
    for (Pair<String, bool> entry in [
      Pair("N", trackedRegisterProvider.srN),
      Pair("Z", trackedRegisterProvider.srZ),
      Pair("C", trackedRegisterProvider.srC),
      Pair("V", trackedRegisterProvider.srV)
    ]) {
      flagString += entry.second ? entry.first : "_";
    }
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              height: widget.compact ? 30 : 40,
              child: const VerticalDivider(color: ColorExtension.deepSlateBlue, width: 2, thickness: 2,)
          ),
          for (int i = 0; i <= 16; i++)
            ...[
              Tooltip(
                message: trackedRegisterProvider.memorySection.getIndexed(i == 16 ? 2 : i).commaSeparatedString,
                child: Column(
                  children: [
                    Text(i == 16 ? "FLAG" : (namedRegisters.containsKey(i) ? "${namedRegisters[i]!}_$i" : " ${i < 10 ? '0' : ''}$i "), style: textStyle),
                    SizedBox(height: widget.compact ? 1 : 2),
                    Container(
                      color: i == 0 ? Colors.cyanAccent : (i == 1 ? Colors.deepPurple : Colors.amber),
                      child: SizedBox(
                        height: 2,
                        width: widget.compact ? 35 : 40,
                      ),
                    ),
                    Text(i == 16 ? flagString : trackedRegisterProvider.memorySection.getIndexed(i).hexString4, style: textStyle),
                    SizedBox(width: widget.compact ? 45 : 50)
                  ],
                ),
              ),
              SizedBox(
                height: widget.compact ? 30 : 40,
                child: const VerticalDivider(color: ColorExtension.deepSlateBlue, width: 2, thickness: 2,)
              ),
            ]
        ],
      ),
    );
  }
}