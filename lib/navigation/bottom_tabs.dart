import 'package:flutter/material.dart';

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
  int _previousIndex = 0;

  late final AnimationController _controller = AnimationController(
    vsync: this
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      _onCompleteAnimation();
    }
  });

  late final Animation<Offset> _moveOutToRightAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.0, 0.0),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.linear
  ));

  late final Animation<Offset> _moveInToRightAnimation = Tween<Offset>(
    begin: const Offset(-1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear
  ));

  late final Animation<Offset> _moveOutToLeftAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1.0, 0.0),
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear
  ));

  late final Animation<Offset> _moveInToLeftAnimation = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear
  ));

  List<Widget> _widgetOptions = <Widget>[
    TestScreen1(),
    TestScreen2(),
    TestScreen3(),
  ];

  @override
  void initState() {
    _selectedIndex = widget.index;
    _previousIndex = widget.index;
    super.initState();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _controller.value = 0.0;
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.decelerate);
    });
  }

  void _onCompleteAnimation() {
    setState(() {
      _previousIndex = _selectedIndex;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_previousIndex == _selectedIndex) {
      body = _widgetOptions[_selectedIndex];
    } else {
      bool right = _previousIndex > _selectedIndex;
      body = Stack(
        children: [
          SlideTransition(
            position: right
                ? _moveOutToRightAnimation
                : _moveOutToLeftAnimation,
            child: _widgetOptions[_previousIndex],
          ),
          SlideTransition(
            position: right ? _moveInToRightAnimation : _moveInToLeftAnimation,
            child: _widgetOptions[_selectedIndex],
          )
        ],
      );
    }
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: body,
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.code_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.construction_rounded),
                label: 'Home',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: const Color(0xFF0A180C),
            selectedIconTheme: const IconThemeData(
              size: 34,
              color: Color(0xFF6DFD8C),
            ),
            unselectedIconTheme: const IconThemeData(
              size: 28,
              color: Color(0xFFD1EAD5),
            ),
          ),
        ));
  }
}