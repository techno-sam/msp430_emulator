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
import 'package:msp430_emulator/state/shmem.dart';
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
    RegistersProvider trackedRegisterProvider = Provider.of<RegistersProvider>(context);
    Map<int, String> namedRegisters = {
      0: "pc",
      1: "sp",
      2: "sr",
      3: "cg"
    };
    TextStyle textStyle = GoogleFonts.firaCode(
      textStyle: theme.textTheme.labelMedium,
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
                message: trackedRegisterProvider.getValue(i == 16 ? 2 : i).commaSeparatedString,
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
                    Text(i == 16 ? flagString : trackedRegisterProvider.getValue(i).hexString4, style: textStyle),
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