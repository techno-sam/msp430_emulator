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

import 'dart:async';

import 'package:flutter/material.dart';

class Rebuilder extends StatefulWidget {
  final Widget child;

  const Rebuilder({super.key, required this.child});

  @override
  State<Rebuilder> createState() => _RebuilderState();
}

class _RebuilderState extends State<Rebuilder> {
  bool _tmpRemoved = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _tmpRemoved ? const SizedBox() : widget.child,
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _tmpRemoved = true;
            });
            Timer(const Duration(milliseconds: 100), () {
              setState(() {
                _tmpRemoved = false;
              });
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
        ),
      ]
    );
  }
}