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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class FoldingContainer extends StatefulWidget {
  final Widget child;
  final Widget expandedTitle;
  final Widget foldedTitle;
  final Color color;

  const FoldingContainer({super.key, required this.child, required this.color,
    required this.expandedTitle, required this.foldedTitle});

  @override
  State<FoldingContainer> createState() => _FoldingContainerState();
}

class _FoldingContainerState extends State<FoldingContainer> with SingleTickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
      vsync: this
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      setState(() {});
    }
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 is hidden, 1 is visible
  double get factor => _controller.value;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _controller.animateTo(factor > 0.5 ? 0 : 1, duration: const Duration(milliseconds: 500), curve: Curves.fastEaseInToSlowEaseOut);
              });
            },
            child: Row(
              children: [
                Transform.rotate(
                  angle: lerpDouble(-pi/2, 0, factor) ?? 0,
                  child: Icon(Icons.arrow_drop_down, color: widget.color)
                ),
                factor < 0.5 ? widget.foldedTitle : widget.expandedTitle
              ],
            ),
          ),
          if (factor > 0 || !_controller.isCompleted)
            ClipRRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: clampDouble(factor, 0, 1),
                child: widget.child
              ),
            )
        ],
      ),
    );
  }
}