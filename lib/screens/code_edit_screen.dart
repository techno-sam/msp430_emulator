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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart';
import 'package:msp430_emulator/language_def/msp430_lang.dart';
import 'package:msp430_emulator/utils/flags.dart';
import 'package:msp430_emulator/widgets/code_editor.dart';

class CodeEditScreen extends StatefulWidget {
  final String path;
  final void Function(bool unsaved) setUnsavedState;
  const CodeEditScreen({super.key, required this.path, required this.setUnsavedState});

  @override
  State<CodeEditScreen> createState() => _CodeEditScreenState();
}

class _CodeEditScreenState extends State<CodeEditScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PageStorageKey<String> storageKey = PageStorageKey<String>("_actual_editor_storage_${widget.path}");
    PageStorageBucket? bucket = PageStorage.of(context).readState(context, identifier: storageKey);

    bool restoreTextFromBucket = bucket != null;
    if (bucket == null) {
      bucket = PageStorageBucket();
      PageStorage.of(context).writeState(context, bucket, identifier: storageKey);
    }

    Widget editor = Editor(
      key: PageStorageKey<String>("_actual_editor_${widget.path}"),
      path: widget.path,
      restoreTextFromBucket: restoreTextFromBucket,
      setUnsavedState: widget.setUnsavedState,
    );

    return PageStorage(
      bucket: bucket,
      key: storageKey,
      child: Flags.langDebug ? Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (kDebugMode) {
                    print("Reloading");
                  }
                  highlight.registerLanguage('msp430', msp430Lang());
                },
                icon: const Icon(Icons.language),
                label: const Text("Reload Language")),
            ],
          ),
          Expanded(child: editor)
        ],
      ) : editor,
    );
  }
}