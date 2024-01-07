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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:provider/provider.dart';

import '../state/editor/highlighter.dart';
import '../state/editor/input.dart';
import '../utils/async_utils.dart';
import 'editor_view.dart' as ev;

class Editor extends StatefulWidget {
  const Editor({super.key, this.path = '', required this.restoreTextFromBucket, required this.setUnsavedState});
  final String path;
  final bool restoreTextFromBucket;
  final void Function(bool unsaved) setUnsavedState;
  @override
  State<Editor> createState() => _Editor();
}

class _Editor extends State<Editor> {
  late ev.DocumentProvider doc;
  late ev.CaretPulse pulse;
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
    doc = ev.DocumentProvider();
    doc.doc.unsavedNotifier = _unsavedNotifier;
    if (!widget.restoreTextFromBucket) {
      _loadFile();
    } else {
      doc.doc.docPath = widget.path;
    }
    pulse = ev.CaretPulse();
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
      Provider(create: (context) => const Highlighter()),
    ], child: Stack(
      children: [
        const InputListener(child: ev.View(key: PageStorageKey("view"))),
        Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    doc.toggleTutor();
                  },
                  icon: const TutorStatusIcon(
                    icon: CupertinoIcons.hammer,
                  ),
                  style: IconButton.styleFrom(
                      backgroundColor: ColorExtension.deepSlateBlue,
                      highlightColor: ColorExtension.blackGreen.withOpacity(0.5)
                  ),
                  tooltip: "Toggle Tutor",
                ),
                const SizedBox(width: 16.0),
                IconButton(
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
              ],
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
    ev.DocumentProvider doc = Provider.of<ev.DocumentProvider>(context);
    return Icon(
      icon,
      color: doc.assemblyStatus.color,
    );
  }
}

class TutorStatusIcon extends StatelessWidget {
  const TutorStatusIcon({
    super.key,
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    ev.DocumentProvider doc = Provider.of<ev.DocumentProvider>(context);
    final questionIcon = Icon(
      Icons.help_outline,
      color: doc.tutorEnabled ? ColorExtension.selectedGreen : Colors.red,
    );
    if (doc.tutorEnabled) {
      return questionIcon;
    } else {
      return Stack(
        children: [
          const Icon(
            Icons.not_interested_outlined,
            color: Colors.red,
          ),
          questionIcon
        ],
      );
    }
  }
}