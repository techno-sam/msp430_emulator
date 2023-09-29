import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:msp430_emulator/ffi_bindings/shmem.dart';
//import 'package:editor/editor/editor.dart' as editor;

class TestScreen1 extends StatelessWidget {
  const TestScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder(color: Colors.red);
  }
}

class TestScreen2 extends StatelessWidget {
  const TestScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    int sum = Shmem().add(2, 3);
    return Center(
      child: Text("'$sum' should be 5", style: TextStyle(color: Colors.red)),
    );
  }
}

class TestScreen3 extends StatelessWidget {
  const TestScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    //return editor.Editor();
    return const Placeholder(color: Colors.blue);
  }
}