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

// ignore_for_file: camel_case_types

import 'dart:developer';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

import 'package:flutter/foundation.dart';

typedef shared_memory = NativeType;
typedef shmem_ptr = Pointer<shared_memory>;

/* Rust/C */

// ffi_create
typedef create_shared_memory_func = shmem_ptr Function();
// ffi_read
typedef read_shared_memory_func = Uint8 Function(shmem_ptr ptr, Uint32 idx);
// ffi_write
typedef write_shared_memory_func = Void Function(shmem_ptr ptr, Uint32 idx, Uint8 value);
// ffi_is_real
typedef is_real_func = Bool Function(shmem_ptr ptr);
// ffi_cleanup
typedef cleanup_shared_memory_func = Void Function(shmem_ptr ptr);

/* Dart */

typedef CreateSharedMemory = shmem_ptr Function();
typedef ReadSharedMemory = int Function(shmem_ptr ptr, int idx);
typedef WriteSharedMemory = void Function(shmem_ptr ptr, int idx, int value);
typedef IsReal = bool Function(shmem_ptr ptr);
typedef CleanupSharedMemory = void Function(shmem_ptr ptr);

DynamicLibrary load({String basePath = ''}) {
  if (Platform.isLinux) {
    return DynamicLibrary.open('${basePath}libshmem_ffi.so');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('${basePath}libshmem_ffi.dylib');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('${basePath}shmem_ffi.dll');
  } else {
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  }
}

class NotSupportedPlatform extends Error {
  NotSupportedPlatform(String s);
}

class Shmem implements Finalizable {
  static final NativeFinalizer _finalizer = NativeFinalizer(_cleanupFnc);
  static late DynamicLibrary _lib;
  static late Pointer<NativeFunction<Void Function(shmem_ptr)>> _cleanupFnc;
  static bool _init = false;
  late shmem_ptr _ptr;
  bool _destroyed = false;

  static void _initLib() {
    if (!_init) {
      // for debugging and tests
      if (kDebugMode &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        _lib = load(basePath: 'target/debug/');
      } else {
        _lib = load();
      }
      _cleanupFnc = _lib.lookup('ffi_cleanup');
      _init = true;
    }
  }
  
  factory Shmem() {
    Shmem shmem = Shmem._();
    _finalizer.attach(shmem, shmem._ptr.cast(), detach: shmem);
    return shmem;
  }

  Shmem._() {
    log("Constructed shared memory");
    _initLib();

    final createPointer = _lib.lookup<NativeFunction<create_shared_memory_func>>('ffi_create');
    _ptr = createPointer.asFunction<CreateSharedMemory>()();
  }

  void reload() {
    destroy(reload: true);
    final createPointer = _lib.lookup<NativeFunction<create_shared_memory_func>>('ffi_create');
    _ptr = createPointer.asFunction<CreateSharedMemory>()();
    _destroyed = false;
  }

  ReadSharedMemory? _read;
  int read(int idx) {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _read ??= _lib.lookupFunction<read_shared_memory_func, ReadSharedMemory>
        ('ffi_read', isLeaf: true);
    return _read!(_ptr, idx & 0xffffffff);
  }

  void writeStr(int idx, String value) {
    for (int chr in value.codeUnits) {
      write(idx, chr);
      idx++;
    }
    write(idx, 0);
  }

  WriteSharedMemory? _write;
  void write(int idx, int value) {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _write ??= _lib.lookupFunction<write_shared_memory_func, WriteSharedMemory>
      ('ffi_write', isLeaf: true);
    return _write!(_ptr, idx & 0xffffffff, value & 0xff);
  }

  IsReal? _isReal;
  bool isReal() {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _isReal ??= _lib.lookupFunction<is_real_func, IsReal>
      ('ffi_is_real', isLeaf: true);
    return _isReal!(_ptr);
  }

  void destroy({bool reload = false}) {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _destroyed = true;

    // set cached methods to null
    _read = null;
    _write = null;
    _isReal = null;

    _lib.lookupFunction<cleanup_shared_memory_func, CleanupSharedMemory>
      ('ffi_cleanup', isLeaf: true)(_ptr);
    if (!reload) {
      print("Freeing shmem ptr");
      calloc.free(_ptr);
      _finalizer.detach(this);
    }
  }

  void dispose() {
    destroy();
  }
}

class ShmemSham implements Shmem {
  @override
  bool _destroyed  = false;

  @override
  IsReal? _isReal;

  @override
  late shmem_ptr _ptr; // just never init

  @override
  ReadSharedMemory? _read;

  @override
  WriteSharedMemory? _write;

  @override
  void destroy({bool reload = false}) {}

  @override
  void dispose() {}

  @override
  bool isReal() {
    return false;
  }

  @override
  int read(int idx) {
    return 0;
  }

  @override
  void reload() {}

  @override
  void write(int idx, int value) {}

  @override
  void writeStr(int idx, String value) {}
}