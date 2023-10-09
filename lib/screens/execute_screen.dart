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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/widgets/memory_view.dart';
import 'package:msp430_emulator/widgets/register_list.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../state/shmem.dart';
import '../widgets/text_buffer_view.dart';

class ExecuteScreen extends StatelessWidget {
  const ExecuteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ShmemProvider shmem = Provider.of<ShmemProvider>(context);
    return Center(
      child: Column(
        children: [
          ExecuteToolbar(shmem: shmem),
          const RegisterList(compact: true),
          const Expanded(
            child: Row(
              children: [
                MemoryView(),
                VerticalDivider(color: ColorExtension.unselectedGreen, width: 8,),
                TextBufferView(),
              ],
            ),
          )
        ],
      ),
    );
  }

}

class ExecuteToolbar extends StatelessWidget {
  const ExecuteToolbar({
    super.key,
    required this.shmem,
  });

  final ShmemProvider shmem;

  @override
  Widget build(BuildContext context) {
    int endFlex = 50;
    int intraGroupFlex = 5;
    int interGroupFlex = 40;
    const buttonColor = Color(0xff69103a);
    return Container(
      //color: ColorExtension.deepSlateBlue.withBrightness(0.5),
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: ColorExtension.deepSlateBlue.withBrightness(0.5)
      ),
      child: Row(
        children: [
          Spacer(flex: endFlex),
          const ReloadButton(),
          Spacer(flex: interGroupFlex),
          IconButton(
            onPressed: () async {
              Directory initialDirectory = Directory.fromUri(
                  (await path_provider.getApplicationDocumentsDirectory())
                      .uri.resolve("AssemblyFiles")
              );
              await initialDirectory.create(recursive: true);
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  initialDirectory: initialDirectory.path,
                  type: FileType.custom,
                  allowedExtensions: [
                    "bin"
                  ]
              );

              if (result != null && result.files.single.path != null) {
                if (kDebugMode) {
                  print("loading program");
                }
                shmem.loadProgram(result.files.single.path!);
                if (kDebugMode) {
                  print("Done (on main) loading program");
                }
              }
            },
            tooltip: "Open",
            icon: const Icon(Icons.file_open_outlined),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
              backgroundColor: buttonColor
            ),
          ),
          Spacer(flex: interGroupFlex),
          IconButton(
            onPressed: shmem.runProgram,
            tooltip: "Run",
            icon: const Icon(Icons.play_circle_outline),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
                backgroundColor: buttonColor
            ),
          ),
          Spacer(flex: intraGroupFlex),
          IconButton(
            onPressed: shmem.stopProgram,
            tooltip: "Stop",
            icon: const Icon(Icons.stop_circle_outlined),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
                backgroundColor: buttonColor
            ),
          ),
          Spacer(flex: interGroupFlex),
          for (int i in [1, 5, 10, 20, 100, 200])
            ...[
              Tooltip(
                message: "Step $i",
                child: TextButton(
                  onPressed: () {
                    shmem.stepProgram(i);
                  },
                  //color: ColorExtension.selectedGreen,
                  style: TextButton.styleFrom(
                    backgroundColor: buttonColor,
                    minimumSize: const Size(48, 48)
                  ),
                  child: Text("$i", style: const TextStyle(color: ColorExtension.selectedGreen)),
                ),
              ),
              if(i != 200)
                Spacer(flex: intraGroupFlex),
          ],
          Spacer(flex: endFlex),
        ],
      ),
    );
  }
}

class ReloadButton extends StatelessWidget {
  const ReloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ShmemProvider shmem = Provider.of<ShmemProvider>(context);
    final bool isReal = shmem.shmem.isReal();
    return IconButton(
      onPressed: () {
        shmem.reload();
      },
      tooltip: "Reload backend (${isReal ? 'present' : 'not present'})",
      icon: const Icon(Icons.refresh_outlined),
      color: isReal
          ? ColorExtension.selectedGreen
          : Colors.red,
      style: IconButton.styleFrom(
          backgroundColor: isReal
              ? const Color(0xff69103a)
              : ColorExtension.selectedGreen.invert.withBrightness(0.2)
      ),
    );
  }
}