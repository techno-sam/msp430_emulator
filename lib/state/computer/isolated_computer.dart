import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:binary/binary.dart';
import 'package:flutter/material.dart';
import 'package:msp430_dart/msp430_dart.dart';
import 'package:msp430_emulator/utils/extensions.dart';
import 'package:msp430_emulator/widgets/memory_view.dart';

const int magicRegisterId = -1;
class MemorySection {
  int get start => _start;
  late final int _start;

  /// exclusive
  int get end => _end;
  late final int _end;

  int get size => _size;
  late final int _size;
  
  final int id;

  late final List<int> _data; // list of bytes (or words, for registers)

  Map<Object, void Function()> onChanged = {}; // used on main side

  void runOnChanged() {
    for (void Function() changeFunc in onChanged.values) {
      changeFunc();
    }
  }

  bool requiresResend = true; // used on computer side

  MemorySection(this.id, int start, int end) {
    _start = start;
    _end = end;
    _size = end - start;

    assert (start >= 0 && start <= 0xffff);
    assert (end >= 0 && end <= 0xffff);
    assert (_size >= 0);

    _data = List<int>.filled(size, 0);
  }

  int getIndexed(int idx) {
    return _data[idx];
  }

  int getWordIndexed(int idx) {
    if (idx % 2 != 0) {
      idx--;
    }

    return (_data[idx] << 8) + _data[idx+1];
  }

  int getAbsolute(int location) {
    return _data[location - start];
  }
}

enum M2CId {
  addTrackedData,
  removeTrackedData,
  loadProgram,
  runProgram,
  stopProgram,
  stepProgram
}

enum C2MId {
  updateMemory
}

class MainSideComputer extends ChangeNotifier {
  late final ReceivePort _receivePort;
  late final SendPort _sendPort;
  late final Isolate _isolate;
  late final StreamQueue<dynamic> _messages;
  bool _initialized = false;

  //int _highestMemoryId = 1;
  final Map<int, MemorySection> _trackedMemory = {};
  final MemorySection trackedRegisters = MemorySection(magicRegisterId, 0, 16); // 16 registers, each is a word

  MainSideComputer() {
    _receivePort = ReceivePort("mainReceiver");
    _setup();
  }

  void _setup() async {
    _isolate = await Isolate.spawn(runIsolated, _receivePort.sendPort);

    _messages = StreamQueue<dynamic>(_receivePort);

    _sendPort = await _messages.next;

    _initialized = true;

    _send([
      M2CId.addTrackedData.index,
      trackedRegisters.id,
      trackedRegisters.start,
      trackedRegisters.end
    ]);

    await _receiveLoop();
  }

  Future<void> _receiveLoop() async {
    while (true) {
      List<int> data = await _receive();
      C2MId id = C2MId.values[data[0]];
      switch (id) {
        case C2MId.updateMemory:
          //print("updating memory ${data[1]}");
          MemorySection? section = data[1] == magicRegisterId ? trackedRegisters  : _trackedMemory[data[1]];
          if (section != null) {
            for (int i = 0; i < section.size; i++) {
              section._data[i] = data[i + 2];
            }
            section.runOnChanged();
          }
          notifyListeners();
          break;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void shutdown() {
    if (_initialized) {
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  void _send(List<int> data) {
    _sendPort.send(List<int>.unmodifiable(data));
  }

  Future<List<int>> _receive() async {
    return (await _messages.next) as List<int>;
  }

  void loadProgram(Uint8List data) {
    _send([
      M2CId.loadProgram.index,
      for (int byte in data)
        byte,
    ]);
  }

  MemorySection? trackMemory(int start, int end) {
    if (!_initialized) return null;

    int id = (start / bytesPerLine).floor();

    if (_trackedMemory.containsKey(id)) {
      return _trackedMemory[id];
    }
    
    MemorySection section = MemorySection(id, start, end);
    _trackedMemory[id] = section;
    _send([
      M2CId.addTrackedData.index,
      section.id,
      section.start,
      section.end
    ]);
    return section;
  }

  void untrackMemory(int id) {
    if (!_initialized) return;
    if (_trackedMemory.containsKey(id)) {
      _trackedMemory.remove(id);
      _send([
        M2CId.removeTrackedData.index,
        id
      ]);
    }
  }

  int getRegisterValue(int registerId) {
    registerId %= 16;
    if (!_initialized) return 0;
    return trackedRegisters._data[registerId];
  }

  void runProgram() {
    _send([
      M2CId.runProgram.index
    ]);
  }

  void stopProgram() {
    _send([
      M2CId.stopProgram.index
    ]);
  }

  void stepProgram([int steps = 1]) {
    steps = max(0, steps);
    _send([
      M2CId.stepProgram.index,
      steps
    ]);
  }
}

class ComputerSideComputer {
  final Computer computer = Computer()
    ..specialInterrupts = false
    ..silent = true;
  final Map<int, MemorySection> trackedMemory = {};
  MemorySection? trackedRegisters;
}

Future<void> runIsolated(SendPort sendPort) async {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  StreamQueue<dynamic> messages = StreamQueue<dynamic>(receivePort);

  ComputerSideComputer computer = ComputerSideComputer();
  computer.computer.reset();
  computer.computer.memory.trackChanges = true;

  int runSteps = 0;
  
  Future<List<int>> receive() async {
    return (await messages.next) as List<int>;
  }

  void send(List<int> data) {
    sendPort.send(List<int>.unmodifiable(data));
  }

  (() async {
    while (true) {
      List<int> data = await receive();
      M2CId id = M2CId.values[data[0]];
      //print(id);
      switch (id) {
        case M2CId.addTrackedData:
          MemorySection section = MemorySection(data[1], data[2], data[3]);
          if (section.id == magicRegisterId) {
            computer.trackedRegisters = section;
          } else {
            computer.trackedMemory[section.id] = section;
          }
          break;
        case M2CId.removeTrackedData:
          computer.trackedMemory.remove(data[1]);
          break;
        case M2CId.loadProgram:
          print("Computer loading program");
          computer.computer.reset();
          int startAddress = (data[1] << 8) + data[2];
          print("Start address: ${startAddress.hexString4}");
          for (int i = 3; i < data.length; i++) {
            computer.computer.setByte(startAddress + i - 3, data[i]);
          }
          computer.computer.pc.setWord(startAddress);
          break;
        case M2CId.runProgram:
          runSteps = -1;
          break;
        case M2CId.stopProgram:
          runSteps = -2;
          break;
        case M2CId.stepProgram:
          if (runSteps < 0) {
            runSteps = 0;
          }
          runSteps += data[1];
          break;
      }
    }
  })();

  bool registersChanged = true;
  int knownResetCount = -1;

  for (Register register in computer.computer.registers) {
    register.onChanged = () => registersChanged = true;
  }

  while (true) {
    if (runSteps > 0 || runSteps == -1) { // -1 will run forever
      computer.computer.step();
      if (runSteps > 0) {
        runSteps--;
      }
    }

    MemorySection? trackedRegisters = computer.trackedRegisters;
    if (trackedRegisters != null && registersChanged) {
      registersChanged = false;
      List<int> data = <int>[
        C2MId.updateMemory.index,
        trackedRegisters.id,
        for (Register register in computer.computer.registers)
          register.getWordInt(),
      ];
      send(data);
    }

    computer.computer.memory.handleChanges((changedAddress) {
      int id = (changedAddress / bytesPerLine).floor();
      computer.trackedMemory[id]?.requiresResend = true;
    });

    for (MemorySection section in computer.trackedMemory.values) {
      if (knownResetCount != computer.computer.memory.resetCount || section.requiresResend) {
        section.requiresResend = false;
        List<int> data = <int>[
          C2MId.updateMemory.index,
          section.id,
          for (int memAddress = section.start; memAddress <
              section.end; memAddress++)
            computer.computer.memory.getByte(memAddress),
        ];
        send(data);
      }
    }
    knownResetCount = computer.computer.memory.resetCount;
    await Future.delayed(const Duration(microseconds: 5));
  }
}