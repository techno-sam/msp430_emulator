/*
 * Copyright (c) 2023 Sam Wagenaar
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
 *
 * Copyright (c) 2022 icedman
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Cursor {
  Cursor(
      {this.line = 0,
        this.column = 0,
        this.anchorLine = 0,
        this.anchorColumn = 0});

  int line = 0;
  int column = 0;
  int anchorLine = 0;
  int anchorColumn = 0;

  Cursor copy() {
    return Cursor(
      line: line,
      column: column,
      anchorLine: anchorLine,
      anchorColumn: anchorColumn
    );
  }

  Cursor normalized() {
    Cursor res = copy();
    if (line > anchorLine || (line == anchorLine && column > anchorColumn)) {
      res.line = anchorLine;
      res.column = anchorColumn;
      res.anchorLine = line;
      res.anchorColumn = column;
      return res;
    }
    return res;
  }

  bool hasSelection() {
    return line != anchorLine || column != anchorColumn;
  }
}

extension NameExtension on Object {

}

class Document {
  String docPath = '';
  List<String>? _oldLines;
  List<String> _lines = [];

  List<String> get lines => _oldLines ?? _lines;

  Cursor cursor = Cursor();
  String _clipboardText = '';

  // ignore: unnecessary_getters_setters
  String get clipboardText => _clipboardText;
  set clipboardText(String clipboardText) {
    _clipboardText = clipboardText;
  }

  set unsavedNotifier(void Function()? unsavedNotifier) {
    _unsavedNotifier = unsavedNotifier;
  }

  //WeakReference<void Function()>? _unsavedNotifier;
  void Function()? _unsavedNotifier;

  bool __unsavedChanges = false;

  bool get unsavedChanges => __unsavedChanges;

  set _unsavedChanges(bool unsavedChanges) {
    __unsavedChanges = unsavedChanges;
    final void Function()? notifier = _unsavedNotifier;
    if (notifier != null) {
      notifier();
    }
  }

  void restoreFromBucket(BuildContext context, PageStorageBucket bucket, bool restoreTextFromBucket) {
    _clipboardText = bucket.readState(context, identifier: const ValueKey("clipboardText")) ?? _clipboardText;
    cursor.anchorColumn = bucket.readState(context, identifier: const ValueKey("anchorColumn")) ?? cursor.anchorColumn;
    cursor.anchorLine = bucket.readState(context, identifier: const ValueKey("anchorLine")) ?? cursor.anchorLine;
    cursor.column = bucket.readState(context, identifier: const ValueKey("column")) ?? cursor.column;
    cursor.line = bucket.readState(context, identifier: const ValueKey("line")) ?? cursor.line;
    if (restoreTextFromBucket) {
      _lines = bucket.readState(context, identifier: const ValueKey("lines")) ?? _lines;
    }
  }

  void writeToBucket(BuildContext context, PageStorageBucket bucket) {
    bucket.writeState(context, _clipboardText, identifier: const ValueKey("clipboardText"));
    bucket.writeState(context, cursor.anchorColumn, identifier: const ValueKey("anchorColumn"));
    bucket.writeState(context, cursor.anchorLine, identifier: const ValueKey("anchorLine"));
    bucket.writeState(context, cursor.column, identifier: const ValueKey("column"));
    bucket.writeState(context, cursor.line, identifier: const ValueKey("line"));
    bucket.writeState(context, _lines, identifier: const ValueKey("lines"));
  }

  Future<bool> openFile(String path, {bool restoreInPlace = false}) async {
    Cursor oldCursor = cursor;
    cursor = Cursor();
    if (restoreInPlace) {
      _oldLines = _lines;
    }
    _lines = <String>[''];
    docPath = path;
    File f = File(docPath);
    await f.openRead().map(utf8.decode).transform(const LineSplitter()).forEach((l) {
      insertText(l);
      insertNewLine();
    });
    cursor = oldCursor;
    if (_lines.length > 1) {
      _lines.removeAt(_lines.length - 1);
    }
    _validateCursor(true);
    _oldLines = null;
    //moveCursorToStartOfDocument();
    _unsavedChanges = false;
    return true;
  }

  Future<String> saveFile({String? path}) async {
    File f = File(path ?? docPath);
    String content = '';
    for (var l in _lines) {
      content += '$l\n';
    }
    await f.writeAsString(content);
    _unsavedChanges = false;
    return content;
  }

  void _validateCursor(bool keepAnchor) {
    if (cursor.line >= _lines.length) {
      cursor.line = _lines.length - 1;
    }

    if (cursor.line < 0) cursor.line = 0;
    if (cursor.column > _lines[cursor.line].length) {
      cursor.column = _lines[cursor.line].length;
    }
    if (cursor.column == -1) cursor.column = _lines[cursor.line].length;
    if (cursor.column < 0) cursor.column = 0;
    if (!keepAnchor) {
      cursor.anchorLine = cursor.line;
      cursor.anchorColumn = cursor.column;
    }
  }

  void moveCursor(int line, int column, {bool keepAnchor = false}) {
    cursor.line = line;
    cursor.column = column;
    _validateCursor(keepAnchor);
  }

  void moveCursorLeft({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column - count;
    if (cursor.column < 0) {
      moveCursorUp(keepAnchor: keepAnchor);
      moveCursorToEndOfLine(keepAnchor: keepAnchor);
    }
    _validateCursor(keepAnchor);
  }

  void moveCursorRight({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;
    if (cursor.column > _lines[cursor.line].length) {
      moveCursorDown(keepAnchor: keepAnchor);
      moveCursorToStartOfLine(keepAnchor: keepAnchor);
    }
    _validateCursor(keepAnchor);
  }

  void moveCursorUp({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line - count;
    _validateCursor(keepAnchor);
  }

  void moveCursorDown({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line + count;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfLine({bool keepAnchor = false}) {
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfLine({bool keepAnchor = false}) {
    cursor.column = _lines[cursor.line].length;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfDocument({bool keepAnchor = false}) {
    cursor.line = 0;
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfDocument({bool keepAnchor = false}) {
    cursor.line = _lines.length - 1;
    cursor.column = _lines[cursor.line].length;
    _validateCursor(keepAnchor);
  }

  void insertNewLine() {
    deleteSelectedText();
    insertText('\n');
  }

  void insertText(String text) {
    _unsavedChanges = true;
    deleteSelectedText();
    String l = _lines[cursor.line];
    String left = l.substring(0, cursor.column);
    String right = l.substring(cursor.column);

    // handle new line
    if (text == '\n') {
      _lines[cursor.line] = left;
      _lines.insert(cursor.line + 1, right);
      moveCursorDown();
      moveCursorToStartOfLine();
      return;
    }

    _lines[cursor.line] = left + text + right;
    moveCursorRight(count: text.length);
  }

  void deleteText({int numberOfCharacters = 1}) {
    if (numberOfCharacters == 0) {
      if (_lines[cursor.line].isEmpty) {
        _unsavedChanges = true;
        _lines.removeAt(cursor.line);
      }
      return;
    }
    _unsavedChanges = true;
    String l = _lines[cursor.line];

    // handle join lines
    if (cursor.column >= l.length) {
      Cursor cur = cursor.copy();
      if (_lines.length == 1) {
        return;
      }
      _lines[cursor.line] += _lines[cursor.line + 1];
      moveCursorDown();
      deleteLine();
      cursor = cur;
      return;
    }

    Cursor cur = cursor.normalized();
    String left = l.substring(0, cur.column);
    String right = l.substring(cur.column + numberOfCharacters);
    cursor = cur;

    // handle erase entire line
    if (_lines.length > 1 && (left + right).isEmpty && l.length != 1) {
      _lines.removeAt(cur.line);
      moveCursorUp();
      moveCursorToStartOfLine();
      return;
    }

    _lines[cursor.line] = left + right;
  }

  void deleteLine({int numberOfLines = 1}) {
    for (int i = 0; i < numberOfLines; i++) {
      moveCursorToStartOfLine();
      deleteText(numberOfCharacters: _lines[cursor.line].length);
    }
    _validateCursor(false);
  }

  List<String> selectedLines() {
    List<String> res = <String>[];
    Cursor cur = cursor.normalized();
    if (cur.line == cur.anchorLine) {
      String sel = _lines[cur.line].substring(cur.column, cur.anchorColumn);
      res.add(sel);
      return res;
    }

    res.add(_lines[cur.line].substring(cur.column));
    for (int i = cur.line + 1; i < cur.anchorLine; i++) {
      res.add(_lines[i]);
    }
    res.add(_lines[cur.anchorLine].substring(0, cur.anchorColumn));
    return res;
  }

  String selectedText() {
    return selectedLines().join('\n');
  }

  void deleteSelectedText() {
    if (!cursor.hasSelection()) {
      return;
    }

    Cursor cur = cursor.normalized();
    List<String> res = selectedLines();
    if (res.length == 1) {
      if (kDebugMode) {
        print(cur.anchorColumn - cur.column);
      }
      deleteText(numberOfCharacters: cur.anchorColumn - cur.column);
      clearSelection();
      return;
    }

    String l = _lines[cur.line];
    String left = l.substring(0, cur.column);
    l = _lines[cur.anchorLine];
    String right = l.substring(cur.anchorColumn);

    cursor = cur;
    _lines[cur.line] = left + right;
    _lines[cur.anchorLine] = _lines[cur.anchorLine].substring(cur.anchorColumn);
    for (int i = 0; i < res.length - 1; i++) {
      _lines.removeAt(cur.line + 1);
    }
    _validateCursor(false);
  }

  void clearSelection() {
    cursor.anchorLine = cursor.line;
    cursor.anchorColumn = cursor.column;
  }

  void command(String cmd) {
    switch (cmd) {
      case 'ctrl+c':
        clipboardText = selectedText();
        break;
      case 'ctrl+x':
        clipboardText = selectedText();
        deleteSelectedText();
        break;
      case 'ctrl+v':
        insertText(clipboardText);
        break;
      case 'ctrl+s':
        saveFile();
        break;
    }
  }
}