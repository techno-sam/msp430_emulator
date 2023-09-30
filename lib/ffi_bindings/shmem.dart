// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'dart:io' show Platform;

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
    return DynamicLibrary.open('${basePath}libshmem_ffi.dll');
  } else {
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  }
}

class NotSupportedPlatform extends Error {
  NotSupportedPlatform(String s);
}

class Shmem {
  static late DynamicLibrary _lib;
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
      _init = true;
    }
  }

  Shmem() {
    _initLib();

    final createPointer = _lib.lookup<NativeFunction<create_shared_memory_func>>('ffi_create');
    _ptr = createPointer.asFunction<CreateSharedMemory>()();
  }

  void reload() {
    destroy();
    final createPointer = _lib.lookup<NativeFunction<create_shared_memory_func>>('ffi_create');
    _ptr = createPointer.asFunction<CreateSharedMemory>()();
    _destroyed = false;
  }

  int read(int idx) {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    return _lib.lookupFunction<read_shared_memory_func, ReadSharedMemory>
      ('ffi_read', isLeaf: true)(_ptr, idx & 0xffffffff);
  }

  void writeStr(int idx, String value) {
    for (int chr in value.codeUnits) {
      write(idx, chr);
      idx++;
    }
    write(idx, 0);
  }

  void write(int idx, int value) {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _lib.lookupFunction<write_shared_memory_func, WriteSharedMemory>
      ('ffi_write', isLeaf: true)(_ptr, idx & 0xffffffff, value & 0xff);
  }

  bool isReal() {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    return _lib.lookupFunction<is_real_func, IsReal>
      ('ffi_is_real', isLeaf: true)(_ptr);
  }

  void destroy() {
    assert(!_destroyed, "Use-after-free, ya numbskull");
    _lib.lookupFunction<cleanup_shared_memory_func, CleanupSharedMemory>
      ('ffi_cleanup', isLeaf: true)(_ptr);
    _destroyed = true;
  }
}
