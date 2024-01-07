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

import 'dart:math';

import 'package:flutter/material.dart';

class HorizontalSplitView extends StatefulWidget {
  final Widget upper;
  final Widget lower;
  final double initialRatio;

  HorizontalSplitView({super.key, required this.upper, required this.lower, this.initialRatio = 0.5}) {
    assert(0 <= initialRatio);
    assert(initialRatio <= 1);
  }

  @override
  State<HorizontalSplitView> createState() => _HorizontalSplitViewState();
}

class _HorizontalSplitViewState extends State<HorizontalSplitView> {
  final _dividerHeight = 16.0;

  double? _maxHeight;

  bool _restored = false;

  double _ratio = 0.5;
  double get ratio => max(0, min(_ratio, 1));

  double get _height1 => ratio * _maxHeight!;
  double get _height2 => (1-ratio) * _maxHeight!;

  @override
  void initState() {
    super.initState();
    _ratio = widget.initialRatio;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _ratio += details.delta.dy / _maxHeight!;
      PageStorage.maybeOf(context)?.writeState(context, _ratio);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) {
      _ratio = PageStorage.maybeOf(context)?.readState(context) ?? _ratio;
      _restored = true;
    }
    return LayoutBuilder(builder: (context, constraints) {
      _maxHeight = constraints.maxHeight - _dividerHeight;

      return SizedBox(
        height: constraints.maxHeight,
        child: Column(
          children: [
            SizedBox(
              height: _height1,
              child: widget.upper,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: _onPanUpdate,
              child: SizedBox(
                width: constraints.maxWidth,
                height: _dividerHeight,
                child: const Stack(
                  fit: StackFit.expand,
                  children: [
                    Divider(),
                    Icon(Icons.drag_handle, color: Colors.white70),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _height2,
              child: widget.lower,
            )
          ],
        )
      );
    });
  }
}