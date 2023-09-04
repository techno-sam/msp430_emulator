import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/widgets/memory_view.dart';
import 'package:msp430_emulator/widgets/register_list.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../state/computer/isolated_computer.dart';

class ExecuteScreen extends StatelessWidget {
  const ExecuteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MainSideComputer computer = Provider.of<MainSideComputer>(context);
    return Center(
      child: Column(
        children: [
          ExecuteToolbar(computer: computer),
          const RegisterList(compact: true),
          const MemoryView()
        ],
      ),
    );
  }

}

class ExecuteToolbar extends StatelessWidget {
  const ExecuteToolbar({
    super.key,
    required this.computer,
  });

  final MainSideComputer computer;

  @override
  Widget build(BuildContext context) {
    int endFlex = 50;
    int intraGroupFlex = 5;
    int interGroupFlex = 40;
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
                File file = File(result.files.single.path!);
                print("loading program");
                computer.loadProgram(await file.readAsBytes());
                print("Done (on main) loading program");
              }
            },
            tooltip: "Open",
            icon: const Icon(Icons.file_open_outlined),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
              backgroundColor: ColorExtension.selectedGreen.invert.withBrightness(0.75)
            ),
          ),
          Spacer(flex: interGroupFlex),
          IconButton(
            onPressed: computer.runProgram,
            tooltip: "Run",
            icon: const Icon(Icons.play_circle_outline),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
                backgroundColor: ColorExtension.selectedGreen.invert.withBrightness(0.75)
            ),
          ),
          Spacer(flex: intraGroupFlex),
          IconButton(
            onPressed: computer.stopProgram,
            tooltip: "Stop",
            icon: const Icon(Icons.stop_circle_outlined),
            color: ColorExtension.selectedGreen,
            style: IconButton.styleFrom(
                backgroundColor: ColorExtension.selectedGreen.invert.withBrightness(0.75)
            ),
          ),
          Spacer(flex: interGroupFlex),
          for (int i in [1, 5, 10, 20, 100, 500])
            ...[
              Tooltip(
                message: "Step $i",
                child: TextButton(
                  onPressed: () {
                    computer.stepProgram(i);
                  },
                  //color: ColorExtension.selectedGreen,
                  style: TextButton.styleFrom(
                    backgroundColor: ColorExtension.selectedGreen.invert.withBrightness(0.75),
                    minimumSize: const Size(48, 48)
                  ),
                  child: Text("$i", style: const TextStyle(color: ColorExtension.selectedGreen)),
                ),
              ),
              if(i != 500)
                Spacer(flex: intraGroupFlex),
          ],
          Spacer(flex: endFlex),
        ],
      ),
    );
  }
}