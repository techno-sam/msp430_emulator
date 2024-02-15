/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2024  Sam Wagenaar
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

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:msp430_emulator/language_def/md_syntax_highlighter.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';
import 'package:msp430_emulator/utils/extensions.dart';

import 'rebuilder.dart';

class MarkdownDocumentationCard extends StatefulWidget {
  const MarkdownDocumentationCard({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<MarkdownDocumentationCard> createState() => _MarkdownDocumentationCardState();
}

class _MarkdownDocumentationCardState extends State<MarkdownDocumentationCard> {
  late final MarkdownStyleSheet _styleSheet = MarkdownStyleSheet.fromTheme(widget.theme).copyWith(
    h1: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.displayLarge,
        color: ColorExtension.selectedGreen
    ),
    h2: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.displayMedium,
        color: ColorExtension.selectedGreen
    ),
    h3: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.displaySmall,
        color: ColorExtension.selectedGreen
    ),
    h4: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.headlineMedium,
        color: ColorExtension.selectedGreen
    ),
    h5: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.headlineSmall,
        color: ColorExtension.selectedGreen
    ),
    h6: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.titleLarge,
        color: ColorExtension.selectedGreen
    ),
    p: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.bodyMedium,
        color: ColorExtension.selectedGreen
    ),
    listBullet: GoogleFonts.firaCode(
        textStyle: widget.theme.textTheme.bodyMedium,
        color: ColorExtension.selectedGreen
    ),
    del: GoogleFonts.firaCode(
      textStyle: widget.theme.textTheme.bodyMedium,
      color: ColorExtension.selectedGreen,
      decoration: TextDecoration.lineThrough,
      decorationColor: ColorExtension.selectedGreen,
      decorationThickness: 4,
    ),
    //*
    codeblockDecoration: BoxDecoration(
      color: editorTheme['root']?.backgroundColor,
      borderRadius: const BorderRadiusDirectional.all(Radius.circular(3.0))
    ), // */
  );

  late ScrollController _controller;
  bool _restored = false;

  void _saveScrollPos() {
    double pos = _controller.offset;
    log("Saving scroll to $pos");
    PageStorage.maybeOf(context)?.writeState(context, pos);
  }

  void _loadScrollPos() {
    if (_restored) return;
    double? pos = PageStorage.maybeOf(context)?.readState(context);
    if (pos != null) {
      log("Restoring scroll to $pos");
      _restored = true;
      try {
        _controller.jumpTo(pos);
      } catch (e) {
        _restored = false;
      }
    }
  }

  @override
  void initState() {
    _controller = ScrollController(keepScrollOffset: true);
    _controller.addListener(_saveScrollPos);
    log("INITIALIZING CONTROLLER");
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    log("DISPOSING CONTROLLER");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _loadScrollPos();
    return Card(
      color: ColorExtension.blackGreen.withBrightness(1.25),
      child: Rebuilder(
        child: Markdown(
          key: const PageStorageKey<String>("documentation_scroller"),
          controller: _controller,
          selectable: false,
          extensionSet: md.ExtensionSet(
              md.ExtensionSet.gitHubFlavored.blockSyntaxes,
              <md.InlineSyntax>[
                ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
              ]
          ),
          data: """
# Test###########################
- one
- two
- three
## Testing
test 456
testing 123
lorem ipsum dolor sit amet. lorem ipsum dolor sit amet. lorem ipsum dolor sit amet.
# h1
## h2
### h3
#### h4
##### h5
###### h6
1. alpha
2. beta
3. gamma
4. delta
* test
  * test test
* test 2
  * test test 2
    * 3 deep
    * even more
  * back to 2

```json
{
  "test": [0, 1, 2, 3],
  "other": true
}
```
`print()`
**this is bold**
*and this is italic*

```dart
void code(int test) {}
```

```msp430
mov #0x5212 0(r6)
```

<u>Underlined!</u>

<a href="https://google.com">Testing link</a>

[startpage.com](https://google.com)

~~strikethrough~~
        """,
          styleSheet: _styleSheet,
          syntaxHighlighter: const MDSyntaxHighlighter(),
        ),
      ),
    );
  }
}