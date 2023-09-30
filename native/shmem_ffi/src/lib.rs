use libc::c_char;
use shared_memory::{Shmem, ShmemConf};
use std::ffi::CStr;
use std::str;

#[repr(C)]
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

    #[allow(dead_code)]
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
pub extern "C" fn ffi_create() -> *mut Option<SharedMemorySystem> {
    let shmem_path = std::env::temp_dir().join("msp430_shmem_id");
    let shmem_flink: &str = shmem_path.to_str().expect("Failed to get shared memory path");
    // Create or open the shared memory mapping
    let shmem = ShmemConf::new().flink(shmem_flink).open();
    let mem_box = match shmem {
        Ok(shmem_real) => Box::new(Some(SharedMemorySystem::new(shmem_real))),
        Err(_) => Box::new(None),
    };
    return Box::into_raw(mem_box);
    //let mem: *mut SharedMemorySystem = &mut SharedMemorySystem::new(shmem) as *mut SharedMemorySystem;
    //return mem;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_read(mem: *mut Option<SharedMemorySystem>, idx: u32) -> u8 {
    let mem_ref = &*mem;
    let ret = match mem_ref {
        Some(smem) => smem.read_byte(idx as usize),
        None => 0,
    };
    Box::into_raw(Box::new(mem_ref)); // prevent GC
    return ret;
    //return (*mem).read_byte(idx as usize);
    //return <*const _>::as_ref(mem).unwrap().read_byte(idx as usize);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_write(mem: *mut Option<SharedMemorySystem>, idx: u32, value: u8) {
    let mem_ref = &mut*mem;
    match mem_ref {
        Some(ref mut smem) => smem.write_byte(idx as usize, value),
        None => {},
    };
    Box::into_raw(Box::new(mem_ref)); // prevent GC
    //(*mem).write_byte(idx as usize, value);
    //<*mut _>::as_mut(mem).unwrap().write_byte(idx as usize, value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_is_real(mem: *mut Option<SharedMemorySystem>) -> bool {
    let mem_ref = &*mem;
    let ret = match mem_ref {
        Some(_) => true,
        None => false,
    };
    Box::into_raw(Box::new(mem_ref)); // prevent GC
    return ret;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_cleanup(mem: *mut Option<SharedMemorySystem>) {
    drop(Box::from_raw(mem));
    //std::ptr::drop_in_place(mem);
}
