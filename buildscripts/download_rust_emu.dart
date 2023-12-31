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

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class PlatformData {
  final String searchName;
  final Uri buildPath;
  final Uri debugBuildPath;
  final String zipName;

  PlatformData({required this.searchName, required this.buildPath,
    required this.debugBuildPath, required this.zipName});

}

final Map<String, PlatformData> platformConfigs = {
  "linux": PlatformData(
      searchName: "linux-gnu",
      buildPath: Uri.file("../target/release/"),
      debugBuildPath: Uri.file("../target/release/"),
      zipName: "msp430_rust.tar.gz"),
  "windows": PlatformData(
      searchName: "windows-gnu",
      buildPath: Uri.file("../target/release/"),
      debugBuildPath: Uri.file("../target/release/"),
      zipName: "msp430_rust.exe.zip"),
  "macos": PlatformData(
      searchName: "apple-darwin",
      buildPath: Uri.file("../target/release/"),
      debugBuildPath: Uri.file("../target/release/"),
      zipName: "msp430_rust.tar.gz"),
};

void main(List<String> args) async {
  bool debug = args.isNotEmpty && args[0] == "debug";
  PlatformData data = platformConfigs[Platform.operatingSystem]!;
  print("Fetching assets metadata");
  var response = await http.get(Uri.parse("https://api.github.com/repos/techno-sam/msp430_rust/releases/latest"));
  if (response.statusCode == 200) {
    print("Request succeeded");
    Map<String, dynamic> decoded = jsonDecode(response.body);
    List<dynamic> assets = decoded["assets"];
    for (Map<String, dynamic> asset in assets) {
      String name = asset["name"];
      if (!name.contains(data.searchName)) continue;
      print("Downloading $name");
      String downloadUrl = asset["browser_download_url"];
      var downloadResponse = await http.get(Uri.parse(downloadUrl));
      if (downloadResponse.statusCode == 200) {
        print("Download succeeded");
        var buildPath = debug ? data.debugBuildPath : data.buildPath;
        await Directory.fromUri(buildPath).create(recursive: true);
        File file = File.fromUri(buildPath.resolve(data.zipName));
        await file.writeAsBytes(downloadResponse.bodyBytes);
        print("Wrote to ${file.absolute.path}");
        if (Platform.isLinux) {
          await Process.run("tar", ["-xvf", "./${data.zipName}"], workingDirectory: buildPath.path);
          await Process.run("cp", ["-v", "./${name.replaceAll(".tar.gz", "")}/msp430_rust", "./"], workingDirectory: buildPath.path);
        } else if (Platform.isWindows) {
          await Process.run("tar", ["-xvf", "./${data.zipName}"], workingDirectory: buildPath.path);
          await Process.run("cp", ["-v", "./${name.replaceAll(".zip", "")}/msp430_rust.exe", "./"], workingDirectory: buildPath.path);
        }
      } else {
        print("Download failed with code ${downloadResponse.statusCode}, ${downloadResponse.reasonPhrase}");
      }
    }
  } else {
    print("Failed with code ${response.statusCode}, ${response.reasonPhrase}");
  }
}