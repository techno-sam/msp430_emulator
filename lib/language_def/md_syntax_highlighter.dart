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

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:msp430_emulator/state/editor/highlighter.dart';

class MDSyntaxHighlighter implements SyntaxHighlighter {
  const MDSyntaxHighlighter();

  @override
  TextSpan format(String source) {
    return TextSpan(
      children: const Highlighter().run(source, 0, null, null).first
    );
  }
}