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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:msp430_dart/msp430_dart.dart';
import 'package:msp430_emulator/utils/extensions.dart';

import '../ffi_bindings/shmem.dart';

enum _ShmemCommand {
  none,
  stop,
  run,
  step,
  loadFile,
  setMem,
  interrupt,
}

// ignore: constant_identifier_names
const int CMD = 0x10020;

class ShmemProvider extends ChangeNotifier {
  final Shmem shmem;

  ShmemProvider(this.shmem);

  Future<void> get ready async {
    while (shmem.read(CMD) != 0) {
      await Future.delayed(const Duration(microseconds: 5));
    }
  }

  void _cmd(_ShmemCommand cmd, [void Function()? preWrite]) {
    if (cmd == _ShmemCommand.none) return;
    int existing = shmem.read(CMD);
    if (existing == 0) {
      preWrite?.call();
      if (kDebugMode) {
        print("Writing '0x${cmd.index.hexString4}' to 0x${CMD.hexString4}");
      }
      shmem.write(CMD, cmd.index);
    } else if (kDebugMode) {
      print("Existing command: $existing");
    }
  }

  void interrupt(int vector) {
    _cmd(_ShmemCommand.interrupt, () {
      shmem.write(CMD+1, (vector & 0xff00) >> 8);
      shmem.write(CMD+2, vector & 0x00ff);
    });
  }

  void setMem(int addr, int val) {
    _cmd(_ShmemCommand.setMem, () {
      shmem.write(CMD+1, (addr & 0xff00) >> 8);
      shmem.write(CMD+2, addr & 0x00ff);
      shmem.write(CMD+3, (val & 0xff00) >> 8);
      shmem.write(CMD+4, val & 0x00ff);
    });
  }

  void loadProgram(String s) {
    _cmd(_ShmemCommand.loadFile, () {
      shmem.writeStr(CMD+1, s);
    });
  }

  void runProgram() {
    _cmd(_ShmemCommand.run);
  }

  void stopProgram() {
    _cmd(_ShmemCommand.stop);
  }

  void stepProgram(int count) {
    _cmd(_ShmemCommand.step, () {
      shmem.write(CMD+1, (count & 0xff00) >> 8);
      shmem.write(CMD+2, count & 0x00ff);
    });
  }

  void reload() {
    shmem.reload();
    notifyListeners();
  }
}

class RegistersProvider extends ChangeNotifier {
  final Shmem shmem;
  final List<int> _vals = List.filled(16, 0);

  RegistersProvider(this.shmem) {
    Timer.periodic(const Duration(milliseconds: 64), _update);
  }

  void _update(Timer timer) async {
    for (int i = 0; i < 16; i++) {
      _vals[i] = (shmem.read(0x10000 + i*2) << 8) + shmem.read(0x10000 + i*2 + 1);
    }
    //print("updating");
    notifyListeners();
  }

  int getValue(int regNum) {
    return _vals[regNum];
  }

  bool _getStatusBit(int idx) {
    return getValue(2) >> idx != 0;
  }

  bool get srV => _getStatusBit(8);
  bool get srN => _getStatusBit(2);
  bool get srZ => _getStatusBit(1);
  bool get srC => _getStatusBit(0);

  bool get srCPUOFF => _getStatusBit(4);
  bool get srGIE => _getStatusBit(3);
}

class MemoryProvider extends ChangeNotifier {
  final Shmem shmem;
  final List<int> _data = List.filled(0x10000, 0);
  Iterable<Pair<int, String>>? _disassembled;
  int _disassemblyCount = -1;

  Iterable<Pair<int, String>>? get disassembled => _disassembled;

  MemoryProvider(this.shmem) {
    Timer.periodic(const Duration(milliseconds: 64), _update);
  }

  void _update(Timer timer) async {
    for (int i = 0; i < 0x10000; i++) {
      _data[i] = shmem.read(i);
      //if (i % 0xff == 0) {
      //  await Future.delayed(Duration.zero);
      //}
    }
    _disassemblyCount += 1;
    if (_disassemblyCount % 78 == 0) { // once every ~5 seconds
      _disassemble();
    }
    notifyListeners();
  }

  int get(int location) {
    return _data[location];
  }
  
  int getWord(int location) {
    if (location % 2 != 0) {
      location--;
    }

    return (_data[location] << 8) + _data[location+1];
  }

  void _disassemble() {
    int start = getWord(0xfffe);
    int current = start;
    List<int> words = [];
    int zeroCount = 0;

    while (zeroCount < 10) {
      words.add(getWord(current));
      current += 2;
      if (words.last == 0) {
        zeroCount += 1;
      } else {
        zeroCount = 0;
      }
    }

    while (words.isNotEmpty && words.last == 0) {
      words.removeLast();
    }

    if (words.isNotEmpty) {
      //print("disassembling, words: $words");
      Disassembler dis = Disassembler(words + [0, 0], start, {});
      _disassembled = dis.run();
      //print(_disassembled!.join("\n"));
    } else {
      _disassembled = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    shmem.dispose();
  }
}