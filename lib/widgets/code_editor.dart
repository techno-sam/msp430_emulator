import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/editor/highlighter.dart';
import '../state/editor/input.dart';
import '../utils/async_utils.dart';
import 'editor_view.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, this.path = '', required this.restoreTextFromBucket, required this.setUnsavedState});
  final String path;
  final bool restoreTextFromBucket;
  final void Function(bool unsaved) setUnsavedState;
  @override
  State<Editor> createState() => _Editor();
}

class _Editor extends State<Editor> {
  late DocumentProvider doc;
  late CaretPulse pulse;
  final NestableLock _restoreLock = NestableLock();
  bool _firstRestore = true;

  void _loadFile({bool restoreInPlace = false}) {
    _restoreLock.lock();
    doc.openFile(widget.path, restoreInPlace: restoreInPlace)
        .then((value) => setState(_restoreLock.unlock));
  }

  void _unsavedNotifier() {
    widget.setUnsavedState(doc.doc.unsavedChanges);
  }

  @override
  void initState() {
    doc = DocumentProvider();
    doc.doc.unsavedNotifier = _unsavedNotifier;
    if (!widget.restoreTextFromBucket) {
      _loadFile();
    } else {
      doc.doc.docPath = widget.path;
    }
    pulse = CaretPulse();
    super.initState();
  }


  @override
  void dispose() {
    pulse.cancel();
    doc.doc.unsavedNotifier = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    doc.maybeInit(context);
    if (_restoreLock.isUnlocked) {
      if (_firstRestore) {
        _firstRestore = false;
        doc.restore(widget.restoreTextFromBucket); // potentially load cached text so scrolling is happy
        _loadFile(restoreInPlace: true);
      }
    }
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) {
        return doc;
      }),
      ChangeNotifierProvider(create: (context) => pulse),
      Provider(create: (context) => Highlighter()),
    ], child: Stack(
      children: [
        const InputListener(child: View(key: PageStorageKey("view"))),
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
              onPressed: () {
                doc.assemble(ScaffoldMessenger.of(context));
              },
              icon: const CompileStatusIcon(
                icon: CupertinoIcons.hammer,
              ),
              style: IconButton.styleFrom(
                backgroundColor: ColorExtension.deepSlateBlue,
                highlightColor: ColorExtension.blackGreen.withOpacity(0.5)
              ),
              tooltip: "Assemble",
            ),
          ),
        )
      ],
    ));
  }
}

class CompileStatusIcon extends StatelessWidget {
  const CompileStatusIcon({
    super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    return Icon(
      icon,
      color: doc.assemblyStatus.color,
    );
  }
}