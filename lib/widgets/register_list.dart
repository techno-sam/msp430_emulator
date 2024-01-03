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
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/state/shmem.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/widgets/memory_view.dart';
import 'package:provider/provider.dart';

import '../language_def/tutor.dart' show namedRegisters;

class RegisterList extends StatefulWidget {
  const RegisterList({
    super.key,
    required this.compact,
    required this.scrollRequester
  });

  final bool compact;
  final AddressScrollRequester scrollRequester;

  @override
  State<RegisterList> createState() => _RegisterListState();
}

class _RegisterListState extends State<RegisterList> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    RegistersProvider trackedRegProv = Provider.of<RegistersProvider>(context);
    TextStyle textStyle = GoogleFonts.firaCode(
      textStyle: theme.textTheme.labelMedium,
      fontSize: widget.compact ? 14 : fontSize,
      color: ColorExtension.selectedGreen
    );
    String flagString = "";
    for (Pair<String, bool> entry in [
      Pair("N", trackedRegProv.srN),
      Pair("Z", trackedRegProv.srZ),
      Pair("C", trackedRegProv.srC),
      Pair("V", trackedRegProv.srV)
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
              InkWell(
                onTap: () {
                  int addr = trackedRegProv.getValue(i == 16 ? 2 : i);
                  widget.scrollRequester.request(addr);
                },
                child: Tooltip(
                  message: trackedRegProv.getValue(i == 16 ? 2 : i).commaSeparatedString + (
                    i == 16 ? "\nCPU: ${trackedRegProv.srCPUOFF ? 'off' : 'on'}"
                        "\nInterrupts: ${trackedRegProv.srGIE ? 'on' : 'off'}" : ""
                  ),
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
                      Text(i == 16 ? flagString : trackedRegProv.getValue(i).hexString4, style: textStyle),
                      SizedBox(width: widget.compact ? 45 : 50)
                    ],
                  ),
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