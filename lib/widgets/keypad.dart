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
import 'package:flutter/services.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/shmem.dart';

class Keypad extends StatefulWidget {
  const Keypad({super.key});

  static final List<String> keys = [
    "1", "2", "3", "+",
    "4", "5", "6", "-",
    "7", "8", "9", "*",
    "<", "0", ">", "=",
  ];

  static final List<int> indexes = [
     1,  2,  3,  10,
     4,  5,  6,  11,
     7,  8,  9,  12,
    14,  0, 15,  13,
  ];

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  late FocusNode focusNode;


  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  Future<void> _sendPressed(ShmemProvider shmem, int i) async {
    int keyId = Keypad.indexes[i];
    print("awaiting memory ready");
    await shmem.ready;
    print("setting memory");
    shmem.setMem(0x0002, keyId);
    print("interrupting waiting");
    await shmem.ready;
    print("interrupting");
    shmem.interrupt(0xfffc);
    print("interrupted");
  }

  @override
  Widget build(BuildContext context) {
    final ShmemProvider shmem = Provider.of<ShmemProvider>(context);

    return MouseRegion(
      onEnter: (details) {
        focusNode.requestFocus();
      },
      onExit: (details) {
        focusNode.unfocus();
      },
      child: GestureDetector(
        onTapDown: (details) {
          focusNode.requestFocus();
        },
        child: Focus(
          focusNode: focusNode,
          onKey: (node, event) {
            focusNode.requestFocus();
            if (event is RawKeyDownEvent && !event.repeat) {
              String? char = event.character;
              String label = event.logicalKey.keyLabel;
              if (label.startsWith("Numpad ")) {
                char ??= int.tryParse(label.replaceFirst("Numpad ", ""))?.toString();
              }
              switch (label) {
                case "Enter": char = "="; break;
                case "Numpad Enter": char = "="; break;
                case "Arrow Right": char = ">"; break;
                case "Arrow Left": char = "<"; break;
              }
              print("lbl: ${event.logicalKey.keyLabel}, char: $char");
              if (char != null && Keypad.keys.contains(char)) {
                int i = Keypad.keys.indexOf(char);
                _sendPressed(shmem, i);
                return KeyEventResult.handled;
              }
            }

            return KeyEventResult.ignored;
          },
          child: Card(
            color: ColorExtension.deepSlateBlue.withBrightness(focusNode.hasFocus ? 3/8 : 1/8),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: SizedBox(
                width: 200,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (int i = 0; i < 16; i++)
                      KeypadButton(
                        text: Keypad.keys[i],
                        onPressed: () async {
                          await _sendPressed(shmem, i);
                        }
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KeypadButton extends StatelessWidget {
  KeypadButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color(0xff165b88); //0xff69103a
    bool pressed = text == "2";
    return SizedBox(
      width: 20,
      height: 20,
      child: ClipOval(
        child: Container(
          color: buttonColor,
          padding: const EdgeInsets.all(2),
          child: TextButton(
            onPressed: onPressed,
            statesController: MaterialStatesController({
              MaterialState.pressed
            }),
            style: TextButton.styleFrom(
              backgroundColor: pressed ? buttonColor : const Color(0xff000000),
              minimumSize: const Size(12, 12),
              foregroundColor: buttonColor.withBrightness(1.5),
            ),
            child: Text(
              text,
              style: const TextStyle(color: ColorExtension.selectedGreen)
            ),
          ),
        ),
      ),
    );
  }
}