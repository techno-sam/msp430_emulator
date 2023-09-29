use libc::c_char;
use shared_memory::{Shmem, ShmemConf, ShmemError};
use std::ffi::CStr;
use std::str;

pub struct SharedMemorySystem {
    _shmem: Shmem,
    raw_ptr: *mut u8
}
impl SharedMemorySystem {
    fn new(mut shmem: Shmem) -> SharedMemorySystem {
        shmem.set_owner(false);
        return SharedMemorySystem {
            raw_ptr: shmem.as_ptr(),
            _shmem: shmem
        };
    }

    fn write_byte(&mut self, idx: usize, value: u8) {
        if idx >= 0x10400 {
            panic!("Index error in write byte, {} is more than 65 kb", idx);
        }
        unsafe {
            std::ptr::write_volatile(self.raw_ptr.add(idx), value);
        }
    }

    fn read_byte(&self, idx: usize) -> u8 {
        if idx >= 0x10400 {
            panic!("Index error in read byte, {} is more than 65 kb", idx);
        }
        unsafe {
            return std::ptr::read_volatile(self.raw_ptr.add(idx));
        }
    }

    fn read_string(&self, idx: usize) -> String {
        if idx >= 0x10400 {
            panic!("Index error in read byte, {} is more than 65 kb", idx);
        }
        let c_buf: *const c_char = unsafe { self.raw_ptr.add(idx) } as *const c_char;
        let c_str: &CStr = unsafe { CStr::from_ptr(c_buf) };
        return c_str.to_str().unwrap().to_owned();
    }
}

#[no_mangle]
pub extern "C" fn add(a: i64, b: i64) -> i64 {
    return a + b;
}

#[no_mangle]
pub extern "C" fn ffi_create() -> *mut SharedMemorySystem {
    let shmem_path = std::env::temp_dir().join("msp430_shmem_id");
    let shmem_flink: &str = shmem_path.to_str().expect("Failed to get shared memory path");
    // Create or open the shared memory mapping
    let shmem = match ShmemConf::new().size(0x10400).flink(shmem_flink).create() {
        Ok(m) => m,
        Err(ShmemError::LinkExists) => {
            eprintln!("Shared memory already exists, make sure msp430_rust is not already running");
            ShmemConf::new().flink(shmem_flink).open().unwrap()
        },
        Err(e) => {
            panic!(
                "Unable to create or open shmem flink {} : {}",
                shmem_flink, e
            );
        }
    };
    let mem: *mut SharedMemorySystem = &mut SharedMemorySystem::new(shmem) as *mut SharedMemorySystem;
    return mem;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_read(mem: *mut SharedMemorySystem, idx: u32) -> u8 {
    return <*const _>::as_ref(mem).unwrap().read_byte(idx as usize);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_write(mem: *mut SharedMemorySystem, idx: u32, value: u8) {
    <*mut _>::as_mut(mem).unwrap().write_byte(idx as usize, value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_cleanup(mem: *mut SharedMemorySystem) {
    std::ptr::drop_in_place(mem);
}
