import 'package:flutter/material.dart';
import 'package:msp430_emulator/state/computer/isolated_computer.dart';

class MemorySectionProvider extends ChangeNotifier {
  final MemorySection memorySection;
  final Object _changeKey = Object();

  MemorySectionProvider({required this.memorySection}) {
    memorySection.onChanged[_changeKey] = notifyListeners;
  }

  @override
  void dispose() {
    memorySection.onChanged.remove(_changeKey);
    super.dispose();
  }

  bool _getStatusBit(int idx) {
    return memorySection.getIndexed(2) >> idx != 0;
  }

  bool get srN => _getStatusBit(2);
  bool get srZ => _getStatusBit(1);
  bool get srC => _getStatusBit(0);
  bool get srV => _getStatusBit(8);
}