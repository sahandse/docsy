use std::ffi::{CStr, CString, c_char};
use std::panic::{catch_unwind, AssertUnwindSafe};

#[unsafe(no_mangle)]
pub extern "C" fn docsy_office_abi_version() -> u32 { 1 }

/// Caller must supply a valid NUL-terminated UTF-8 path.
/// Returned string must be released with docsy_office_free.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn docsy_word_inspect(path: *const c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| -> Result<serde_json::Value, String> {
        if path.is_null() { return Err("Missing path".into()); }
        let path = unsafe { CStr::from_ptr(path) }.to_str().map_err(|e| e.to_string())?;
        let meta = std::fs::metadata(path).map_err(|e| e.to_string())?;
        if !meta.is_file() || meta.len() > 32 * 1024 * 1024 {
            return Err("Expected a regular file of at most 32 MiB".into());
        }
        let doc = wordcraft_engine::io::open_path(std::path::Path::new(path))?;
        Ok(serde_json::json!({"words":doc.word_count(),"paragraphs":doc.paragraph_count()}))
    }));
    let value = match result {
        Ok(Ok(data)) => serde_json::json!({"ok":true,"data":data}),
        Ok(Err(error)) => serde_json::json!({"ok":false,"error":error}),
        Err(_) => serde_json::json!({"ok":false,"error":"Native engine failure"}),
    };
    CString::new(value.to_string()).map(CString::into_raw).unwrap_or(std::ptr::null_mut())
}

/// Only release a pointer returned by this library, exactly once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn docsy_office_free(ptr: *mut c_char) {
    if !ptr.is_null() { drop(unsafe { CString::from_raw(ptr) }); }
}
