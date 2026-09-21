//! The slice of the HDF5 C API the two result formats need, as owned handles.
//!
//! Every wrapper closes its `hid_t` on drop and every call that can fail
//! returns `Err(String)`; the HDF5 error stack is silenced once in [`init`], so
//! a failed call does not print a C traceback to stderr.

#![cfg(feature = "library")]

use std::ffi::{CStr, CString, c_void};
use std::sync::Once;

use hdf5_metno_sys::h5::{H5open, herr_t, hsize_t};
use hdf5_metno_sys::h5a::{H5Aclose, H5Acreate2, H5Aopen, H5Aread, H5Awrite};
use hdf5_metno_sys::h5d::{H5Dclose, H5Dcreate2, H5Dget_space, H5Dget_type, H5Dopen2, H5Dread, H5Dset_extent, H5Dwrite};
use hdf5_metno_sys::h5e::{H5E_DEFAULT, H5Eset_auto2};
use hdf5_metno_sys::h5f::{H5F_ACC_RDONLY, H5F_ACC_TRUNC, H5Fclose, H5Fcreate, H5Fopen};
use hdf5_metno_sys::h5g::{H5Gclose, H5Gcreate2, H5Gget_info, H5Gopen2, H5G_info_t};
use hdf5_metno_sys::h5i::hid_t;
use hdf5_metno_sys::h5::H5_index_t::H5_INDEX_NAME;
use hdf5_metno_sys::h5l::{H5Lexists, H5Lget_name_by_idx};
use hdf5_metno_sys::h5o::{H5O_TYPE_DATASET, H5O_TYPE_GROUP};
use hdf5_metno_sys::h5p::{
    H5P_DEFAULT, H5Pclose, H5Pcreate, H5Pset_chunk, H5Pset_deflate, H5Pset_shuffle,
};
use hdf5_metno_sys::h5r::hobj_ref_t;
use hdf5_metno_sys::h5s::{
    H5S_ALL, H5S_SELECT_SET, H5S_UNLIMITED, H5Sclose, H5Screate, H5Screate_simple,
    H5Sget_simple_extent_dims, H5Sget_simple_extent_ndims, H5Sselect_hyperslab, H5S_class_t,
};
use hdf5_metno_sys::h5t::{
    H5T_CSET_UTF8, H5T_C_S1, H5T_NATIVE_DOUBLE, H5T_NATIVE_FLOAT, H5T_NATIVE_INT32,
    H5T_NATIVE_INT8, H5T_NATIVE_UINT32, H5T_NATIVE_UINT8, H5T_STD_REF_OBJ, H5T_VARIABLE, H5Tclose,
    H5Tcopy, H5Tcreate, H5Tenum_create, H5Tenum_insert, H5Tinsert, H5Tset_cset, H5Tset_size,
    H5T_class_t,
};

/// `H5Rcreate` is the 1.8-era object-reference call. hdf5-metno-sys declares it,
/// but `H5R_OBJECT` is `H5R_OBJECT1` from 1.12 on, so name the value here.
const H5R_OBJECT: hdf5_metno_sys::h5r::H5R_type_t = hdf5_metno_sys::h5r::H5R_type_t::H5R_OBJECT1;

/// Open HDF5 and turn off the automatic error printing. Idempotent.
///
/// A thread-safe HDF5 gives every thread its own error stack, so the automatic
/// printing has to be turned off on each of them: doing it once left a reader
/// thread dumping the whole stack for every attribute an object does not carry.
pub fn init() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        unsafe { H5open() };
    });
    thread_local! {
        static QUIET: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
    }
    QUIET.with(|quiet| {
        if !quiet.replace(true) {
            unsafe { H5Eset_auto2(H5E_DEFAULT, None, std::ptr::null_mut()) };
        }
    });
}

/// The HDF5 library version this was linked against, for a benchmark report.
pub fn version() -> String {
    init();
    let (mut maj, mut min, mut rel) = (0u32, 0u32, 0u32);
    unsafe { hdf5_metno_sys::h5::H5get_libversion(&mut maj, &mut min, &mut rel) };
    format!("{maj}.{min}.{rel}")
}

/// Whether the library was built thread-safe. It is a correctness answer, not
/// a performance one: HDF5 1.14's thread safety is one global lock around the
/// whole library, so concurrent callers are serialised rather than sped up.
pub fn is_threadsafe() -> bool {
    init();
    let mut ts: hdf5_metno_sys::h5::hbool_t = 0;
    unsafe { hdf5_metno_sys::h5::H5is_library_threadsafe(&mut ts) };
    ts != 0
}

fn check(id: hid_t, what: &str) -> Result<hid_t, String> {
    if id < 0 { Err(format!("HDF5: {what} failed")) } else { Ok(id) }
}

fn ok(status: herr_t, what: &str) -> Result<(), String> {
    if status < 0 { Err(format!("HDF5: {what} failed")) } else { Ok(()) }
}

fn cstr(s: &str) -> CString {
    CString::new(s.replace('\0', " ")).expect("no interior NUL")
}

macro_rules! handle {
    ($name:ident, $close:path) => {
        pub struct $name(hid_t);
        impl $name {
            pub fn id(&self) -> hid_t {
                self.0
            }
            pub fn from_raw(id: hid_t) -> $name {
                $name(id)
            }
        }
        impl Drop for $name {
            fn drop(&mut self) {
                if self.0 >= 0 {
                    unsafe { $close(self.0) };
                }
            }
        }
    };
}

handle!(File, H5Fclose);
handle!(Group, H5Gclose);
handle!(Dataset, H5Dclose);
handle!(Space, H5Sclose);
handle!(Type, H5Tclose);
handle!(Plist, H5Pclose);
handle!(Attr, H5Aclose);

/// Anything a dataset or attribute can be created under.
pub trait Loc {
    fn loc(&self) -> hid_t;
}

impl Loc for File {
    fn loc(&self) -> hid_t {
        self.0
    }
}

impl Loc for Group {
    fn loc(&self) -> hid_t {
        self.0
    }
}

impl File {
    pub fn create(path: &str) -> Result<File, String> {
        init();
        let p = cstr(path);
        let id = unsafe { H5Fcreate(p.as_ptr(), H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT) };
        check(id, "H5Fcreate").map(File)
    }

    pub fn open_ro(path: &str) -> Result<File, String> {
        init();
        let p = cstr(path);
        let id = unsafe { H5Fopen(p.as_ptr(), H5F_ACC_RDONLY, H5P_DEFAULT) };
        check(id, "H5Fopen").map(File)
    }
}

impl Group {
    pub fn create(loc: &dyn Loc, name: &str) -> Result<Group, String> {
        let n = cstr(name);
        let id = unsafe { H5Gcreate2(loc.loc(), n.as_ptr(), H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT) };
        check(id, "H5Gcreate2").map(Group)
    }

    pub fn open(loc: &dyn Loc, name: &str) -> Result<Group, String> {
        let n = cstr(name);
        let id = unsafe { H5Gopen2(loc.loc(), n.as_ptr(), H5P_DEFAULT) };
        check(id, "H5Gopen2").map(Group)
    }

    /// Direct children, with the kind of each.
    pub fn links(&self) -> Result<Vec<(String, LinkKind)>, String> {
        let mut info = H5G_info_t::default();
        ok(unsafe { H5Gget_info(self.0, &mut info) }, "H5Gget_info")?;
        let mut out = Vec::with_capacity(info.nlinks as usize);
        for i in 0..info.nlinks {
            let name = self.link_name(i)?;
            let kind = self.link_kind(&name)?;
            out.push((name, kind));
        }
        Ok(out)
    }

    fn link_name(&self, i: hsize_t) -> Result<String, String> {
        let get = |buf: *mut i8, size: usize| unsafe {
            H5Lget_name_by_idx(
                self.0,
                c".".as_ptr(),
                H5_INDEX_NAME,
                hdf5_metno_sys::h5::H5_iter_order_t::H5_ITER_INC,
                i,
                buf,
                size,
                H5P_DEFAULT,
            )
        };
        let len = get(std::ptr::null_mut(), 0);
        if len < 0 {
            return Err("HDF5: H5Lget_name_by_idx failed".into());
        }
        let mut buf = vec![0i8; len as usize + 1];
        if get(buf.as_mut_ptr(), buf.len()) < 0 {
            return Err("HDF5: H5Lget_name_by_idx failed".into());
        }
        Ok(unsafe { CStr::from_ptr(buf.as_ptr()) }.to_string_lossy().into_owned())
    }

    fn link_kind(&self, name: &str) -> Result<LinkKind, String> {
        use hdf5_metno_sys::h5o::{H5O_info2_t, H5Oget_info_by_name3, H5O_INFO_BASIC};
        let n = cstr(name);
        let mut info: H5O_info2_t = unsafe { std::mem::zeroed() };
        ok(
            unsafe { H5Oget_info_by_name3(self.0, n.as_ptr(), &mut info, H5O_INFO_BASIC, H5P_DEFAULT) },
            "H5Oget_info_by_name3",
        )?;
        Ok(match info.type_ {
            H5O_TYPE_GROUP => LinkKind::Group,
            H5O_TYPE_DATASET => LinkKind::Dataset,
            _ => LinkKind::Other,
        })
    }

    pub fn exists(loc: &dyn Loc, name: &str) -> bool {
        let n = cstr(name);
        unsafe { H5Lexists(loc.loc(), n.as_ptr(), H5P_DEFAULT) > 0 }
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum LinkKind {
    Group,
    Dataset,
    Other,
}

/// How a dataset stores its elements: contiguous, or chunked with an optional
/// shuffle + deflate filter pipeline.
#[derive(Clone, Copy)]
pub struct Layout {
    /// `None` = contiguous (and then the dataset cannot grow).
    pub chunk: Option<[u64; 2]>,
    pub deflate: Option<u8>,
    pub shuffle: bool,
}

impl Layout {
    pub const CONTIGUOUS: Layout = Layout { chunk: None, deflate: None, shuffle: false };

    fn plist(&self, rank: usize) -> Result<Plist, String> {
        let Some(chunk) = self.chunk else { return Ok(Plist(H5P_DEFAULT)) };
        let id = check(unsafe { H5Pcreate(*hdf5_metno_sys::h5p::H5P_CLS_DATASET_CREATE) }, "H5Pcreate")?;
        let plist = Plist(id);
        let dims: Vec<hsize_t> = chunk[..rank].iter().map(|d| *d as hsize_t).collect();
        ok(unsafe { H5Pset_chunk(id, rank as i32, dims.as_ptr()) }, "H5Pset_chunk")?;
        if self.shuffle {
            ok(unsafe { H5Pset_shuffle(id) }, "H5Pset_shuffle")?;
        }
        if let Some(level) = self.deflate {
            ok(unsafe { H5Pset_deflate(id, level as u32) }, "H5Pset_deflate")?;
        }
        Ok(plist)
    }
}

impl Space {
    pub fn simple(dims: &[u64], max: Option<&[u64]>) -> Result<Space, String> {
        let d: Vec<hsize_t> = dims.iter().map(|x| *x as hsize_t).collect();
        let m: Option<Vec<hsize_t>> = max.map(|m| {
            m.iter().map(|x| if *x == u64::MAX { H5S_UNLIMITED } else { *x as hsize_t }).collect()
        });
        let id = unsafe {
            H5Screate_simple(d.len() as i32, d.as_ptr(), m.as_ref().map_or(std::ptr::null(), |v| v.as_ptr()))
        };
        check(id, "H5Screate_simple").map(Space)
    }

    pub fn scalar() -> Result<Space, String> {
        check(unsafe { H5Screate(H5S_class_t::H5S_SCALAR) }, "H5Screate").map(Space)
    }

    pub fn dims(&self) -> Result<Vec<u64>, String> {
        let rank = unsafe { H5Sget_simple_extent_ndims(self.0) };
        if rank < 0 {
            return Err("HDF5: H5Sget_simple_extent_ndims failed".into());
        }
        let mut dims = vec![0 as hsize_t; rank as usize];
        if rank > 0 {
            ok(
                unsafe { H5Sget_simple_extent_dims(self.0, dims.as_mut_ptr(), std::ptr::null_mut()) }
                    .min(0),
                "H5Sget_simple_extent_dims",
            )?;
        }
        Ok(dims)
    }

    fn select(&self, start: &[u64], count: &[u64]) -> Result<(), String> {
        let s: Vec<hsize_t> = start.iter().map(|x| *x as hsize_t).collect();
        let c: Vec<hsize_t> = count.iter().map(|x| *x as hsize_t).collect();
        ok(
            unsafe {
                H5Sselect_hyperslab(
                    self.0,
                    H5S_SELECT_SET,
                    s.as_ptr(),
                    std::ptr::null(),
                    c.as_ptr(),
                    std::ptr::null(),
                )
            },
            "H5Sselect_hyperslab",
        )
    }
}

impl Type {
    pub fn f64() -> Type {
        Type(unsafe { H5Tcopy(*H5T_NATIVE_DOUBLE) })
    }
    pub fn f32() -> Type {
        Type(unsafe { H5Tcopy(*H5T_NATIVE_FLOAT) })
    }
    pub fn i32() -> Type {
        Type(unsafe { H5Tcopy(*H5T_NATIVE_INT32) })
    }
    pub fn i8() -> Type {
        Type(unsafe { H5Tcopy(*H5T_NATIVE_INT8) })
    }
    pub fn u32() -> Type {
        Type(unsafe { H5Tcopy(*H5T_NATIVE_UINT32) })
    }

    /// A `uint8`-backed enumeration, which is how MTSF stores `causality`,
    /// `variability` and its booleans.
    pub fn enum_u8(members: &[(&str, u8)]) -> Result<Type, String> {
        let base = Type(unsafe { H5Tcopy(*H5T_NATIVE_UINT8) });
        let id = check(unsafe { H5Tenum_create(base.0) }, "H5Tenum_create")?;
        let t = Type(id);
        for (name, value) in members {
            let n = cstr(name);
            ok(
                unsafe { H5Tenum_insert(id, n.as_ptr(), (&raw const *value).cast::<c_void>()) },
                "H5Tenum_insert",
            )?;
        }
        Ok(t)
    }
    pub fn obj_ref() -> Type {
        Type(unsafe { H5Tcopy(*H5T_STD_REF_OBJ) })
    }

    /// A variable-length UTF-8 string, the type h5py writes for `vlen=str`.
    pub fn vlen_str() -> Result<Type, String> {
        let id = check(unsafe { H5Tcopy(*H5T_C_S1) }, "H5Tcopy")?;
        let t = Type(id);
        ok(unsafe { H5Tset_size(id, H5T_VARIABLE) }, "H5Tset_size")?;
        ok(unsafe { H5Tset_cset(id, H5T_CSET_UTF8) }, "H5Tset_cset")?;
        Ok(t)
    }

    pub fn fixed_str(len: usize) -> Result<Type, String> {
        let id = check(unsafe { H5Tcopy(*H5T_C_S1) }, "H5Tcopy")?;
        let t = Type(id);
        ok(unsafe { H5Tset_size(id, len.max(1)) }, "H5Tset_size")?;
        ok(unsafe { H5Tset_cset(id, H5T_CSET_UTF8) }, "H5Tset_cset")?;
        Ok(t)
    }

    pub fn compound(size: usize, fields: &[(&str, usize, &Type)]) -> Result<Type, String> {
        let id = check(unsafe { H5Tcreate(H5T_class_t::H5T_COMPOUND, size) }, "H5Tcreate")?;
        let t = Type(id);
        for (name, offset, ty) in fields {
            let n = cstr(name);
            ok(unsafe { H5Tinsert(id, n.as_ptr(), *offset, ty.0) }, "H5Tinsert")?;
        }
        Ok(t)
    }

    pub fn of_dataset(ds: &Dataset) -> Result<Type, String> {
        check(unsafe { H5Dget_type(ds.0) }, "H5Dget_type").map(Type)
    }

    pub fn class(&self) -> H5T_class_t {
        unsafe { hdf5_metno_sys::h5t::H5Tget_class(self.0) }
    }
}

impl Dataset {
    #[allow(clippy::too_many_arguments)]
    pub fn create(
        loc: &dyn Loc,
        name: &str,
        ty: &Type,
        dims: &[u64],
        max: Option<&[u64]>,
        layout: Layout,
    ) -> Result<Dataset, String> {
        let space = Space::simple(dims, max)?;
        let plist = layout.plist(dims.len())?;
        let n = cstr(name);
        let id = unsafe {
            H5Dcreate2(loc.loc(), n.as_ptr(), ty.0, space.id(), H5P_DEFAULT, plist.id(), H5P_DEFAULT)
        };
        check(id, "H5Dcreate2").map(Dataset)
    }

    pub fn open(loc: &dyn Loc, name: &str) -> Result<Dataset, String> {
        let n = cstr(name);
        let id = unsafe { H5Dopen2(loc.loc(), n.as_ptr(), H5P_DEFAULT) };
        check(id, "H5Dopen2").map(Dataset)
    }

    pub fn space(&self) -> Result<Space, String> {
        check(unsafe { H5Dget_space(self.0) }, "H5Dget_space").map(Space)
    }

    pub fn set_extent(&self, dims: &[u64]) -> Result<(), String> {
        let d: Vec<hsize_t> = dims.iter().map(|x| *x as hsize_t).collect();
        ok(unsafe { H5Dset_extent(self.0, d.as_ptr()) }, "H5Dset_extent")
    }

    pub fn write_all<T>(&self, mem_ty: &Type, buf: &[T]) -> Result<(), String> {
        ok(
            unsafe {
                H5Dwrite(self.0, mem_ty.0, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf.as_ptr().cast::<c_void>())
            },
            "H5Dwrite",
        )
    }

    pub fn write_slab<T>(&self, mem_ty: &Type, start: &[u64], count: &[u64], buf: &[T]) -> Result<(), String> {
        let file_space = self.space()?;
        file_space.select(start, count)?;
        let mem_space = Space::simple(count, None)?;
        ok(
            unsafe {
                H5Dwrite(
                    self.0,
                    mem_ty.0,
                    mem_space.id(),
                    file_space.id(),
                    H5P_DEFAULT,
                    buf.as_ptr().cast::<c_void>(),
                )
            },
            "H5Dwrite",
        )
    }

    pub fn read_all<T>(&self, mem_ty: &Type, buf: &mut [T]) -> Result<(), String> {
        ok(
            unsafe {
                H5Dread(
                    self.0,
                    mem_ty.0,
                    H5S_ALL,
                    H5S_ALL,
                    H5P_DEFAULT,
                    buf.as_mut_ptr().cast::<c_void>(),
                )
            },
            "H5Dread",
        )
    }

    pub fn read_slab<T>(&self, mem_ty: &Type, start: &[u64], count: &[u64], buf: &mut [T]) -> Result<(), String> {
        let file_space = self.space()?;
        file_space.select(start, count)?;
        let mem_space = Space::simple(count, None)?;
        ok(
            unsafe {
                H5Dread(
                    self.0,
                    mem_ty.0,
                    mem_space.id(),
                    file_space.id(),
                    H5P_DEFAULT,
                    buf.as_mut_ptr().cast::<c_void>(),
                )
            },
            "H5Dread",
        )
    }

    /// The object reference MTSF's variable table stores.
    pub fn reference(&self, file: &File, path: &str) -> Result<hobj_ref_t, String> {
        let p = cstr(path);
        let mut r: hobj_ref_t = 0;
        ok(
            unsafe {
                hdf5_metno_sys::h5r::H5Rcreate(
                    (&raw mut r).cast::<c_void>(),
                    file.id(),
                    p.as_ptr(),
                    H5R_OBJECT,
                    -1,
                )
            },
            "H5Rcreate",
        )?;
        Ok(r)
    }
}

/// HDF5 has no "set" call for an attribute, so writing one twice fails; every
/// caller here writes each attribute once.
pub trait Attrs {
    fn obj(&self) -> hid_t;

    fn attr_str(&self, name: &str, value: &str) -> Result<(), String> {
        // A fixed-length string type has no zero size, so an empty value still
        // needs a byte to read from.
        let bytes = value.as_bytes();
        let ty = Type::fixed_str(bytes.len())?;
        let space = Space::scalar()?;
        let n = cstr(name);
        let id = check(
            unsafe { H5Acreate2(self.obj(), n.as_ptr(), ty.id(), space.id(), H5P_DEFAULT, H5P_DEFAULT) },
            "H5Acreate2",
        )?;
        let attr = Attr(id);
        let buf = if bytes.is_empty() { &[0u8][..] } else { bytes };
        ok(unsafe { H5Awrite(attr.0, ty.id(), buf.as_ptr().cast::<c_void>()) }, "H5Awrite")
    }

    fn attr_f64(&self, name: &str, value: f64) -> Result<(), String> {
        let ty = Type::f64();
        let space = Space::scalar()?;
        let n = cstr(name);
        let id = check(
            unsafe { H5Acreate2(self.obj(), n.as_ptr(), ty.id(), space.id(), H5P_DEFAULT, H5P_DEFAULT) },
            "H5Acreate2",
        )?;
        let attr = Attr(id);
        ok(unsafe { H5Awrite(attr.0, ty.id(), (&raw const value).cast::<c_void>()) }, "H5Awrite")
    }

    fn attr_i32(&self, name: &str, value: i32) -> Result<(), String> {
        let ty = Type::i32();
        let space = Space::scalar()?;
        let n = cstr(name);
        let id = check(
            unsafe { H5Acreate2(self.obj(), n.as_ptr(), ty.id(), space.id(), H5P_DEFAULT, H5P_DEFAULT) },
            "H5Acreate2",
        )?;
        let attr = Attr(id);
        ok(unsafe { H5Awrite(attr.0, ty.id(), (&raw const value).cast::<c_void>()) }, "H5Awrite")
    }

    fn attr_array<T>(&self, name: &str, ty: &Type, values: &[T]) -> Result<(), String> {
        let space = Space::simple(&[values.len() as u64], None)?;
        let n = cstr(name);
        let id = check(
            unsafe { H5Acreate2(self.obj(), n.as_ptr(), ty.id(), space.id(), H5P_DEFAULT, H5P_DEFAULT) },
            "H5Acreate2",
        )?;
        let attr = Attr(id);
        ok(unsafe { H5Awrite(attr.0, ty.id(), values.as_ptr().cast::<c_void>()) }, "H5Awrite")
    }

    /// Opening an attribute an object does not have is the normal case here -
    /// `RELATIVE_QUANTITY` is written only when true - so ask first rather than
    /// push a failure onto the error stack per variable.
    fn open_attr(&self, name: &str) -> Option<Attr> {
        let n = cstr(name);
        if unsafe { hdf5_metno_sys::h5a::H5Aexists(self.obj(), n.as_ptr()) } <= 0 {
            return None;
        }
        let id = unsafe { H5Aopen(self.obj(), n.as_ptr(), H5P_DEFAULT) };
        if id < 0 { None } else { Some(Attr(id)) }
    }

    fn read_attr_str(&self, name: &str) -> Option<String> {
        let attr = self.open_attr(name)?;
        let ty = Type(unsafe { hdf5_metno_sys::h5a::H5Aget_type(attr.0) });
        let size = unsafe { hdf5_metno_sys::h5t::H5Tget_size(ty.id()) };
        if size == H5T_VARIABLE {
            let mut ptr: *mut i8 = std::ptr::null_mut();
            if unsafe { H5Aread(attr.0, ty.id(), (&raw mut ptr).cast::<c_void>()) } < 0 || ptr.is_null() {
                return None;
            }
            let s = unsafe { CStr::from_ptr(ptr) }.to_string_lossy().into_owned();
            unsafe { hdf5_metno_sys::h5::H5free_memory(ptr.cast::<c_void>()) };
            return Some(s);
        }
        let mut buf = vec![0u8; size + 1];
        if unsafe { H5Aread(attr.0, ty.id(), buf.as_mut_ptr().cast::<c_void>()) } < 0 {
            return None;
        }
        let end = buf.iter().position(|b| *b == 0).unwrap_or(size);
        Some(String::from_utf8_lossy(&buf[..end]).into_owned())
    }

    fn read_attr_f64(&self, name: &str) -> Option<f64> {
        let attr = self.open_attr(name)?;
        let mut v = 0.0f64;
        let ty = Type::f64();
        if unsafe { H5Aread(attr.0, ty.id(), (&raw mut v).cast::<c_void>()) } < 0 {
            return None;
        }
        Some(v)
    }

    fn read_attr_i32(&self, name: &str) -> Option<i32> {
        let attr = self.open_attr(name)?;
        let mut v = 0i32;
        let ty = Type::i32();
        if unsafe { H5Aread(attr.0, ty.id(), (&raw mut v).cast::<c_void>()) } < 0 {
            return None;
        }
        Some(v)
    }
}

impl Attrs for Dataset {
    fn obj(&self) -> hid_t {
        self.0
    }
}

impl Attrs for Group {
    fn obj(&self) -> hid_t {
        self.0
    }
}

impl Attrs for File {
    fn obj(&self) -> hid_t {
        self.0
    }
}

pub fn deref(file: &File, r: hobj_ref_t) -> Result<Dataset, String> {
    let id = unsafe {
        hdf5_metno_sys::h5r::H5Rdereference2(
            file.id(),
            H5P_DEFAULT,
            H5R_OBJECT,
            (&raw const r).cast::<c_void>(),
        )
    };
    check(id, "H5Rdereference2").map(Dataset::from_raw)
}

/// Free what HDF5 allocated for the vlen fields of `ty`.
pub fn reclaim_vlen<T>(ty: &Type, space: &Space, buf: &mut [T]) {
    unsafe {
        hdf5_metno_sys::h5t::H5Treclaim(
            ty.id(),
            space.id(),
            H5P_DEFAULT,
            buf.as_mut_ptr().cast::<c_void>(),
        )
    };
}
