import 'dart:core';
import 'package:flutter/material.dart';

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
    /*int sum = Shmem().add(2, 3);
    return Center(
      child: Text("'$sum' should be 5", style: TextStyle(color: Colors.red)),
    );*/
    return const Placeholder(color: Colors.green);
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