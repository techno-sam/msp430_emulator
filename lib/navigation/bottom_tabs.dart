/*
 *     MSP430 emulator and assembler
 *     Copyright (C) 2023  Sam Wagenaar
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
import 'package:msp430_emulator/screens/execute_screen.dart';
import 'package:msp430_emulator/screens/homescreen.dart';
import 'package:msp430_emulator/screens/tabbed_editor_screen.dart';
import 'package:msp430_emulator/utils/extensions.dart';

import '../screens/test_screens.dart';

class BottomTabs extends StatefulWidget {
  final int index;
  const BottomTabs({
    super.key,
    required this.index,
  });

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _controller = AnimationController(
    vsync: this
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      _onCompleteAnimation();
    }
  });

  late final Animation<Offset> _leftAnimation = Tween<Offset>(
    begin: const Offset(-2.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.linear
  ));

  late final Animation<Offset> _centerAnimation = Tween<Offset>(
    begin: const Offset(-1.0, 0.0),
    end: const Offset(1.0, 0.0),
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear
  ));

  late final Animation<Offset> _rightAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(2.0, 0.0),
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear
  ));

  late final List<Animation<Offset>> _transitions = [
    _leftAnimation,
    _centerAnimation,
    _rightAnimation
  ];

  final PageStorageBucket _bucket = PageStorageBucket();

  final GlobalKey<State<TabbedEditorScreen>> _editKey = GlobalKey<State<TabbedEditorScreen>>();

  late final List<Widget> _widgetOptions = <Widget>[
    TabbedEditorScreen(key: _editKey),//CodeEditScreen(key: _editKey, path: "/home/sam/AppDev/msp430_emulator/test/widget_test.dart"),//TabbedEditorScreen(key: PageStorageKey("tabbedEditor")),//key: _screenKey1, path: '/home/sam/AppDev/msp430_emulator/test/widget_test.dart'),
    const HomeScreen(),
    const ExecuteScreen(),
  ];

  @override
  void initState() {
    _selectedIndex = widget.index;
    _controller.value = 0.5;
    super.initState();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      double target = (2-index)/2.0;
      double diff = (_controller.value - target).abs();
      _controller.animateTo(target, duration: Duration(milliseconds: (diff * 600).round()), curve: Curves.decelerate);
      for (int i = 0; i < _inSlidePath.length; i++) {
        _inSlidePath[i] = i == _selectedIndex;
        double idxCenter = (2-i)/2.0;

        double boundary = 0.4;

        double minEdge = min(_controller.value, target) - boundary;
        double maxEdge = max(_controller.value, target) + boundary;

        _inSlidePath[i] = idxCenter >= minEdge && idxCenter <= maxEdge;
      }
    });
  }

  void _onCompleteAnimation() {
    // trigger rebuild after animation so we don't need to draw all three pages
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<bool> _inSlidePath = [false, false, false];

  @override
  Widget build(BuildContext context) {
    Widget body = _controller.isAnimating ? Stack(
      children: [
        for (int i = 0; i < _widgetOptions.length; i++)
          if (_inSlidePath[i])
            SlideTransition(
              position: _transitions[i],
              child: _widgetOptions[i],
            ),
      ],
    ) : _widgetOptions[_selectedIndex];
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: PageStorage(
            bucket: _bucket,
            child: body,//_widgetOptions[_selectedIndex]
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.code_rounded),
                label: 'Edit Code',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.construction_rounded),
                label: 'Run',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: ColorExtension.blackGreen,
            selectedIconTheme: const IconThemeData(
              size: 34,
              color: ColorExtension.selectedGreen,
            ),
            unselectedIconTheme: const IconThemeData(
              size: 28,
              color: ColorExtension.unselectedGreen,
            ),
          ),
        ));
  }
}