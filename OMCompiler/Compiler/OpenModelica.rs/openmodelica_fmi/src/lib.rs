//! Reading FMUs — FMI 1.0, 2.0 and 3.0, plus the fmi-ls-wasm layered standard.
//!
//! [`Fmu`] is an FMU archive (or an already-extracted directory): its
//! [`ModelDescription`], its files, and the binaries it offers per platform.
//! Nothing here executes an FMU; `openmodelica_fmi_driver` does that. The crate
//! is host-free — the browser omc reads an FMU exactly as the native one does.

pub mod description;
pub mod figures;
#[cfg(feature = "component")]
pub mod lswasm;
mod parse;
mod platform;

pub use description::*;
pub use figures::{Axis, Curve, Figure, Plot, Visualization};
pub use parse::model_description;
pub use platform::{Platform, host_platform};

use std::borrow::Cow;
use std::collections::BTreeMap;
use std::io::Read;
use std::path::{Path, PathBuf};

#[derive(Debug)]
pub enum Error {
    Zip(String),
    Io(String),
    Xml(String),
    /// The archive has no `modelDescription.xml`.
    NoModelDescription,
    UnsupportedVersion(String),
    /// An fmi-ls-wasm binary that is not a component, or not one of the FMI
    /// worlds.
    Component(String),
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Zip(m) => write!(f, "not a readable FMU archive: {m}"),
            Error::Io(m) => write!(f, "{m}"),
            Error::Xml(m) => write!(f, "modelDescription.xml: {m}"),
            Error::NoModelDescription => write!(f, "the FMU has no modelDescription.xml"),
            Error::UnsupportedVersion(v) => write!(f, "unsupported FMI version {v}"),
            Error::Component(m) => write!(f, "{m}"),
        }
    }
}

impl std::error::Error for Error {}

pub type Result<T> = std::result::Result<T, Error>;

/// Which binary an importer would rather have when the FMU ships several.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum Preference {
    /// A shared library for this host, else the wasm component. Native code is
    /// faster than anything a wasm runtime can do with a component.
    #[default]
    Native,
    /// The wasm component, even where a native binary exists — sandboxed, and
    /// the only choice in the browser.
    Wasm,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum BinaryKind {
    /// A shared library implementing the FMI C API.
    Native,
    /// `binaries/wasm32-wasip2/*.wasm`, an fmi-ls-wasm component; `resources/*.wasm`
    /// where it imports the OpenModelica extension.
    Wasm,
}

#[derive(Clone, Debug)]
pub struct Binary {
    pub kind: BinaryKind,
    /// The platform directory (`x86_64-linux`, `linux64`, `wasm32-wasip2`).
    pub platform_dir: String,
    /// The entry name inside the FMU (`binaries/linux64/Foo.so`).
    pub path: String,
    /// A native binary this host can `dlopen`.
    pub is_host: bool,
}

enum Storage {
    Memory(BTreeMap<String, Vec<u8>>),
    Dir(PathBuf),
}

pub struct Fmu {
    pub model_description: ModelDescription,
    /// Where the FMU came from, for error messages and for the resource URI an
    /// FMU is instantiated with.
    pub origin: Option<PathBuf>,
    storage: Storage,
    names: Vec<String>,
}

impl Fmu {
    pub fn from_bytes(bytes: &[u8]) -> Result<Fmu> {
        let mut zip = zip::ZipArchive::new(std::io::Cursor::new(bytes))
            .map_err(|e| Error::Zip(e.to_string()))?;
        let mut files = BTreeMap::new();
        for i in 0..zip.len() {
            let mut f = zip.by_index(i).map_err(|e| Error::Zip(e.to_string()))?;
            if f.is_dir() {
                continue;
            }
            // Normalise the separator: an FMU written on Windows may use `\`.
            let name = f.name().replace('\\', "/");
            let mut data = Vec::with_capacity(f.size() as usize);
            f.read_to_end(&mut data).map_err(|e| Error::Zip(e.to_string()))?;
            files.insert(name, data);
        }
        let names = files.keys().cloned().collect();
        Self::finish(Storage::Memory(files), names, None)
    }

    pub fn from_path(path: &Path) -> Result<Fmu> {
        if path.is_dir() {
            return Self::from_dir(path);
        }
        let bytes = std::fs::read(path).map_err(|e| Error::Io(format!("{}: {e}", path.display())))?;
        let mut fmu = Self::from_bytes(&bytes)?;
        fmu.origin = Some(path.to_path_buf());
        Ok(fmu)
    }

    /// An already-extracted FMU; its files are read on demand.
    pub fn from_dir(dir: &Path) -> Result<Fmu> {
        let mut names = Vec::new();
        collect(dir, dir, &mut names)?;
        names.sort();
        Self::finish(Storage::Dir(dir.to_path_buf()), names, Some(dir.to_path_buf()))
    }

    fn finish(storage: Storage, names: Vec<String>, origin: Option<PathBuf>) -> Result<Fmu> {
        let mut fmu = Fmu { model_description: ModelDescription::default(), origin, storage, names };
        let xml = fmu.read("modelDescription.xml").ok_or(Error::NoModelDescription)?;
        let text = String::from_utf8_lossy(&xml).into_owned();
        fmu.model_description = parse::model_description(&text)?;
        Ok(fmu)
    }

    pub fn read(&self, name: &str) -> Option<Cow<'_, [u8]>> {
        match &self.storage {
            Storage::Memory(files) => files.get(name).map(|v| Cow::Borrowed(v.as_slice())),
            Storage::Dir(dir) => std::fs::read(dir.join(name)).ok().map(Cow::Owned),
        }
    }

    /// Every file in the FMU, as slash-separated paths relative to its root.
    pub fn names(&self) -> &[String] {
        &self.names
    }

    /// The `modelIdentifier` of `kind`, which is the stem of its binary.
    pub fn model_identifier(&self, kind: InterfaceKind) -> Option<&str> {
        Some(self.model_description.interface(kind)?.model_identifier.as_str())
    }

    /// The binaries the FMU ships for `kind`, host-native ones first.
    pub fn binaries(&self, kind: InterfaceKind) -> Vec<Binary> {
        let Some(id) = self.model_identifier(kind) else { return Vec::new() };
        let host = host_platform();
        let mut out: Vec<Binary> = self
            .names
            .iter()
            .filter_map(|path| {
                let rest = path.strip_prefix("binaries/")?;
                let (dir, file) = rest.split_once('/')?;
                let stem = file.rsplit_once('.').map(|(s, _)| s).unwrap_or(file);
                // A wasm FMU names its component after the modelIdentifier too,
                // so the stem check applies to both kinds.
                if stem != id {
                    return None;
                }
                let kind = if dir == platform::WASM_DIR { BinaryKind::Wasm } else { BinaryKind::Native };
                if kind == BinaryKind::Native && !file.ends_with(platform::dir_suffix(dir)) {
                    return None;
                }
                Some(Binary {
                    kind,
                    platform_dir: dir.to_string(),
                    path: path.clone(),
                    is_host: kind == BinaryKind::Native && host.is_some_and(|h| h.matches_dir(dir)),
                })
            })
            .collect();
        // A component importing `om:ext/native` is kept out of `binaries/`, being no
        // fmi-ls-wasm binary. It is still the FMU's wasm binary to us.
        let extended = format!("resources/{id}.wasm");
        if !out.iter().any(|b| b.kind == BinaryKind::Wasm) && self.names.iter().any(|n| *n == extended) {
            out.push(Binary {
                kind: BinaryKind::Wasm,
                platform_dir: platform::WASM_DIR.to_string(),
                path: extended,
                is_host: false,
            });
        }
        out.sort_by_key(|b| (!b.is_host, b.kind == BinaryKind::Wasm));
        out
    }

    /// The binary to load, honouring `prefer`. A native binary is only offered
    /// when it is this host's.
    pub fn select_binary(&self, kind: InterfaceKind, prefer: Preference) -> Option<Binary> {
        let bins = self.binaries(kind);
        let native = bins.iter().find(|b| b.is_host);
        let wasm = bins.iter().find(|b| b.kind == BinaryKind::Wasm);
        match prefer {
            Preference::Native => native.or(wasm),
            Preference::Wasm => wasm.or(native),
        }
        .cloned()
    }

    /// The `resources/` entries, which is what an FMU sees of its own archive.
    pub fn resources(&self) -> impl Iterator<Item = &str> {
        self.names.iter().map(String::as_str).filter(|n| n.starts_with("resources/"))
    }

    /// Write `resources/` out to `dir`, for a native FMU that is handed a
    /// resource path at instantiation. Returns the path to pass it.
    pub fn extract_resources(&self, dir: &Path) -> Result<PathBuf> {
        let root = dir.join("resources");
        std::fs::create_dir_all(&root).map_err(|e| Error::Io(e.to_string()))?;
        for name in self.resources().map(str::to_string).collect::<Vec<_>>() {
            let Some(data) = self.read(&name) else { continue };
            let out = dir.join(&name);
            if let Some(parent) = out.parent() {
                std::fs::create_dir_all(parent).map_err(|e| Error::Io(e.to_string()))?;
            }
            std::fs::write(&out, &data).map_err(|e| Error::Io(e.to_string()))?;
        }
        Ok(root)
    }

    /// The fmi-ls-wasm manifest, when the FMU declares the layered standard.
    #[cfg(feature = "component")]
    pub fn ls_wasm_manifest(&self) -> Option<lswasm::Manifest> {
        let xml = self.read(lswasm::MANIFEST_PATH)?;
        lswasm::Manifest::parse(&String::from_utf8_lossy(&xml)).ok()
    }
}

fn collect(root: &Path, dir: &Path, out: &mut Vec<String>) -> Result<()> {
    let entries = std::fs::read_dir(dir).map_err(|e| Error::Io(format!("{}: {e}", dir.display())))?;
    for e in entries.flatten() {
        let path = e.path();
        if path.is_dir() {
            collect(root, &path, out)?;
        } else if let Ok(rel) = path.strip_prefix(root) {
            out.push(rel.to_string_lossy().replace('\\', "/"));
        }
    }
    Ok(())
}
