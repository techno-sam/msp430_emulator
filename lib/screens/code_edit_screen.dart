import 'dart:math';

import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart';
import 'package:msp430_emulator/language_def/msp430_lang.dart';
import 'package:msp430_emulator/utils/flags.dart';
import 'package:msp430_emulator/widgets/code_editor.dart';

import '../widgets/editor_view.dart';

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
                  print("Reloading");
                  highlight.registerLanguage('msp430', msp430_lang());
                },
                icon: Icon(Icons.language),
                label: Text("Reload Language")),
            ],
          ),
          Expanded(child: editor)
        ],
      ) : editor,
    );
  }
}