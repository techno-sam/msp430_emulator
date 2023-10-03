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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msp430_emulator/utils/extensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              "MSP430 Emulator and Assembler",
              style: GoogleFonts.firaCode(
                textStyle: theme.textTheme.displaySmall,
                color: ColorExtension.selectedGreen
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0),
          child: Divider(color: ColorExtension.deepSlateBlue),
        ),
        const BodySection(
          title: "About",
          body: "Lorem ipsum dolor sit amet",
        ),
        BodySection(
          title: "License",
          body: "MSP430 Emulator is licensed under the GPLv3.0 license, and the code may be browsed at https://github.com/techno-sam/msp430_emulator",
          postfix: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute<void>(
                builder: (context) {
                  return const LicensePage();
                }
              ));
            },
            child: const Text("View license information"),
          ),
        ),
      ],
    );
  }
}

class BodySection extends StatelessWidget {
  const BodySection({
    super.key,
    required this.title,
    required this.body,
    this.postfix
  });

  final String title;
  final String body;
  final Widget? postfix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.firaCode(
                textStyle: theme.textTheme.headlineSmall,
                color: ColorExtension.selectedGreen
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            body,
            style: GoogleFonts.firaCode(
                textStyle: theme.textTheme.bodyMedium,
                color: ColorExtension.selectedGreen
            ),
          ),
        ] + (postfix == null ? [] : [const SizedBox(height: 8), postfix!]),
      ),
    );
  }
}