#!/bin/bash
#
#     MSP430 emulator and assembler
#     Copyright (C) 2023-2024  Sam Wagenaar
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

echo "Building Rust..."
cargo build --release
echo "Fetching rust emulator"
dart download_rust_emu.dart
echo "Building Flutter..."
flutter build windows --release -v
echo "Done"