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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart';
import 'package:msp430_emulator/ffi_bindings/shmem.dart';
import 'package:msp430_emulator/state/shmem.dart';
import 'package:provider/provider.dart';

import 'language_def/msp430_lang.dart';
import 'navigation/bottom_tabs.dart';
import 'utils/flags.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/FiraCode/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts/FiraCode'], license);

    yield LicenseEntryWithLineBreaks(
        ['msp430_emulator/editor'],
        await rootBundle.loadString('extra_licenses/SHARED_MIT')
    );
    yield LicenseEntryWithLineBreaks(
        ['msp430_emulator'],
        await rootBundle.loadString('LICENSE')
    );
  });

  if (!Flags.langDebug) {
    highlight.registerLanguage('msp430', msp430Lang());
  }
  //MainSideComputer computer = MainSideComputer();
  //print(File(".").absolute.path);
  Shmem shmem = Shmem();
  runApp(MyApp(shmem: shmem));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.shmem}) {
    shmemProvider = ShmemProvider(shmem);
    registersProvider = RegistersProvider(shmem);
    memoryProvider = MemoryProvider(shmem);
    
    _launchEmulator();
  }
  
  void _launchEmulator() async {
    // launch emulator
    if (kDebugMode || kProfileMode) {
      print("my pid: $pid");
    }
    if (true) {
      await Process.run("${(kDebugMode || kProfileMode) ? "target/release/" : ""}msp430_rust", ["run-forked", "$pid"]);
      shmemProvider.reload();
    }
  }

  final Shmem shmem;
  late final ShmemProvider shmemProvider;
  late final RegistersProvider registersProvider;
  late final MemoryProvider memoryProvider;

  final GlobalKey<State<BottomTabs>> _bottomTabsKey = GlobalKey();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSP430 Emulator',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A180C),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: shmemProvider),
          ChangeNotifierProvider.value(value: registersProvider),
          ChangeNotifierProvider.value(value: memoryProvider),
        ],
        child: BottomTabs(key: _bottomTabsKey, index: 1),
      ),//const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
