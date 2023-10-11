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
import 'package:flutter/material.dart';
import 'package:msp430_emulator/screens/code_edit_screen.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/widgets/tab_button.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class TabbedEditorScreen extends StatefulWidget {
  const TabbedEditorScreen({super.key});

  @override
  State<TabbedEditorScreen> createState() => _TabbedEditorScreenState();
}

class _TabbedEditorScreenState extends State<TabbedEditorScreen> {
  BuildContext? _bucketContext;
  PageStorageBucket? _storageBucket;
  bool _alreadyRestored = false;

  final Map<String, bool> _unsavedChanges = {};

  void _setUnsaved(String file, bool unsaved) {
    if (_unsavedChanges[file] != unsaved) {
      setState(() {
        _unsavedChanges[file] = unsaved;
      });
    }
  }

  bool _isUnsaved(String file) {
    return _unsavedChanges[file] ?? false;
  }

  final List<String> _openFiles = [];

  String? _selectedFile;

  String? get selectedFile => _openFiles.contains(_selectedFile) ? _selectedFile : null;
  
  Future<void> _openFile() async {
    Directory initialDirectory = Directory.fromUri(
        (await path_provider.getApplicationDocumentsDirectory())
            .uri.resolve("AssemblyFiles/")
    );
    await initialDirectory.create(recursive: true);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        initialDirectory: initialDirectory.path,
        type: FileType.custom,
        allowedExtensions: [
          "asm"
        ]
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        String path = result.files.single.path!;
        if (!_openFiles.contains(path)) {
          _openFiles.add(path);
        }
        _selectedFile = path;
      });
    }
  }

  Future<void> _newFile() async {
    Directory initialDirectory = Directory.fromUri(
        (await path_provider.getApplicationDocumentsDirectory())
            .uri.resolve("AssemblyFiles/")
    );
    await initialDirectory.create(recursive: true);
    String? result = await FilePicker.platform.saveFile(
        initialDirectory: initialDirectory.path,
        type: FileType.custom,
        allowedExtensions: [
          "asm"
        ]
    );

    if (result != null) {
      if (!result.endsWith(".asm")) {
        result += ".asm";
      }
      setState(() {
        if (!_openFiles.contains(result)) {
          _openFiles.add(result!);
        }
        _selectedFile = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _bucketContext = context;
    _storageBucket = PageStorage.of(context);

    if (!_alreadyRestored) {
      List<String>? oldOpenFiles = _storageBucket!.readState(context, identifier: const ValueKey("tabbed_editor_file_list"));
      if (oldOpenFiles != null) {
        _openFiles
          ..clear()
          ..addAll(oldOpenFiles);
      }
      _alreadyRestored = true;
    }

    final theme = Theme.of(context);
    if (selectedFile == null && _openFiles.isNotEmpty) {
      _selectedFile = _openFiles[0];
    }
    if (_openFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "No files open",
              style: theme.textTheme.headlineMedium?.copyWith(color: const Color(0xFF6DFD8C))
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openFile,
                  icon: const Icon(
                    Icons.file_open_outlined,
                    color: ColorExtension.selectedGreen
                  ),
                  label: Text(
                    "Open File",
                    style: theme.textTheme.labelLarge?.copyWith(color: ColorExtension.selectedGreen),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorExtension.deepSlateBlue
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _newFile,
                  icon: const Icon(
                      Icons.create_outlined,
                      color: ColorExtension.selectedGreen
                  ),
                  label: Text(
                    "New File",
                    style: theme.textTheme.labelLarge?.copyWith(color: ColorExtension.selectedGreen),
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ColorExtension.deepSlateBlue
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }
    final String finalSelectedFile = selectedFile!;
    return Center(
      child: Column(
        children: [
          Container(
            color: ColorExtension.blackGreen,
            padding: const EdgeInsets.only(
              left: 2.0,
              right: 2.0,
              top: 4.0,
              bottom: 0.0
            ),
            child: Row(
              children: [
                for (String fileName in _openFiles)
                  TabButton(
                    selected: _selectedFile == fileName,
                    label: (_isUnsaved(fileName) ? "* " : "") + fileName,
                    onExit: () {
                      setState(() {
                        _openFiles.remove(fileName);
                      });
                    },
                    onClick: () {
                      setState(() {
                        _selectedFile = fileName;
                      });
                    },
                  ),
                IconButton(
                  onPressed: _openFile,
                  icon: Icon(
                    Icons.add,
                    color: ColorExtension.selectedGreen.withOpacity(0.75),
                    size: 18,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2,),
          Expanded(
              child: CodeEditScreen(
                key: PageStorageKey("editor_page_$finalSelectedFile"),
                path: finalSelectedFile,
                setUnsavedState: (b) => _setUnsaved(finalSelectedFile, b),
              ), // each code edit screen handles its own page storage bucket
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_bucketContext != null && _storageBucket != null) {
      _storageBucket!.writeState(_bucketContext!, _openFiles, identifier: const ValueKey("tabbed_editor_file_list"));
    }
    super.dispose();
  }
}