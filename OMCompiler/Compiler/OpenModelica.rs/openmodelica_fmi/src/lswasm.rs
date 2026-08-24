//! The fmi-ls-wasm layered standard: the manifest, and what is inside the
//! component at `binaries/wasm32-wasip2/<modelIdentifier>.wasm`.
//!
//! [`inspect`] answers the questions a host has to answer before it can run
//! one: which FMI interfaces the component implements, what it expects the host
//! to provide, and — for a host that links the FMU to its driver instead of
//! going through the component boundary — which core modules it carries and
//! what each of those imports and exports.

use crate::description::InterfaceKind;
use crate::{Error, Result};
use std::ops::Range;

pub const MANIFEST_PATH: &str = "extra/org.modelica.fmi-ls-wasm/manifest.xml";
pub const LS_NAME: &str = "org.modelica.fmi-ls-wasm";
/// The WIT package the worlds live in.
pub const WIT_PACKAGE: &str = "fmi:fmi3";

#[derive(Clone, Debug)]
pub struct Manifest {
    pub name: String,
    pub version: String,
    pub description: Option<String>,
}

impl Manifest {
    pub fn parse(xml: &str) -> Result<Manifest> {
        let doc = roxmltree::Document::parse(xml).map_err(|e| Error::Xml(e.to_string()))?;
        let root = doc.root_element();
        let a = |n| root.attribute(n).map(str::to_string);
        Ok(Manifest {
            name: a("fmi-ls-name").unwrap_or_default(),
            version: a("fmi-ls-version").unwrap_or_default(),
            description: a("fmi-ls-description"),
        })
    }

    pub fn is_wasm(&self) -> bool {
        self.name == LS_NAME
    }
}

/// How the FMU's guest reaches WASI, which decides what a host must supply.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Wasi {
    /// No WASI import at all.
    None,
    /// A wasip1 guest plus the reactor adapter — the adapter module is one of
    /// the core modules, and the guest's imports are already satisfied inside
    /// the component.
    Preview1Adapter,
    /// A wasip2 guest importing `wasi:*` interfaces from the host.
    Preview2,
}

#[derive(Clone, Debug)]
pub struct Import {
    pub module: String,
    pub name: String,
    /// A function, as opposed to a memory/global/table import.
    pub is_func: bool,
}

#[derive(Clone, Debug)]
pub struct CoreModule {
    /// Position in the component, which is also the order they are instantiated
    /// in.
    pub index: usize,
    /// Byte range of the module inside the component.
    pub range: Range<usize>,
    pub imports: Vec<Import>,
    pub exports: Vec<String>,
    /// `memory`, when the module exports one — the FMU's address space.
    pub memory: Option<String>,
    /// `cabi_realloc`, the allocator the canonical ABI (and anything linked
    /// against this module) allocates through.
    pub realloc: Option<String>,
    /// `_initialize` (a reactor) or `__wasm_call_ctors`, to run before the
    /// first call.
    pub initializer: Option<String>,
    /// The wasip1 reactor adapter rather than the FMU itself.
    pub is_wasi_adapter: bool,
}

impl CoreModule {
    /// The exports that carry an FMI function, i.e. the canonical-ABI lowering
    /// of one of the `fmi:fmi3/*` interfaces.
    pub fn fmi_exports(&self) -> impl Iterator<Item = &str> {
        self.exports.iter().map(String::as_str).filter(|e| e.starts_with("fmi:fmi3/"))
    }

    /// The imports the module expects an FMI host to satisfy (the callbacks).
    pub fn fmi_imports(&self) -> impl Iterator<Item = &Import> {
        self.imports.iter().filter(|i| i.module.starts_with("fmi:fmi3/"))
    }
}

/// What [`inspect`] found in an fmi-ls-wasm component.
#[derive(Clone, Debug)]
pub struct Component {
    /// The FMI interfaces the component exports, in the order ME, CS, SE.
    pub interfaces: Vec<InterfaceKind>,
    /// WIT names of the interfaces it exports, e.g.
    /// `fmi:fmi3/co-simulation@3.0.0`.
    pub exports: Vec<String>,
    /// WIT names of the interfaces the host must provide.
    pub imports: Vec<String>,
    pub wasi: Wasi,
    /// The core modules, in component order. A component built from a wasip1
    /// guest carries the adapter as one of them.
    pub core_modules: Vec<CoreModule>,
}

impl Component {
    /// The core module holding the FMU itself: the one exporting FMI functions.
    pub fn fmu_module(&self) -> Option<&CoreModule> {
        self.core_modules.iter().find(|m| m.fmi_exports().next().is_some())
    }

    pub fn implements(&self, kind: InterfaceKind) -> bool {
        self.interfaces.contains(&kind)
    }
}

/// Read an fmi-ls-wasm component: its world, and the core modules inside it.
pub fn inspect(component: &[u8]) -> Result<Component> {
    let core_modules = core_modules(component)?;
    let (exports, imports) = world(component)?;
    let interfaces = [
        (InterfaceKind::ModelExchange, "model-exchange"),
        (InterfaceKind::CoSimulation, "co-simulation"),
        (InterfaceKind::ScheduledExecution, "scheduled-execution"),
    ]
    .into_iter()
    .filter(|(_, name)| exports.iter().any(|e| interface_is(e, name)))
    .map(|(k, _)| k)
    .collect::<Vec<_>>();
    if interfaces.is_empty() {
        return Err(Error::Component(format!(
            "the component exports no fmi:fmi3 interface (it exports {})",
            if exports.is_empty() { "nothing".to_string() } else { exports.join(", ") }
        )));
    }
    let wasi = if core_modules.iter().any(|m| m.is_wasi_adapter) {
        Wasi::Preview1Adapter
    } else if imports.iter().any(|i| i.starts_with("wasi:")) {
        Wasi::Preview2
    } else {
        Wasi::None
    };
    Ok(Component { interfaces, exports, imports, wasi, core_modules })
}

/// `fmi:fmi3/co-simulation@3.0.0` is the `co-simulation` interface.
fn interface_is(wit_name: &str, interface: &str) -> bool {
    let Some((pkg, rest)) = wit_name.split_once('/') else { return false };
    pkg == WIT_PACKAGE && rest.split('@').next() == Some(interface)
}

/// The WIT world the component's type section declares.
fn world(component: &[u8]) -> Result<(Vec<String>, Vec<String>)> {
    let decoded = wit_component::decode(component)
        .map_err(|e| Error::Component(format!("not a WebAssembly component: {e}")))?;
    let wit_component::DecodedWasm::Component(resolve, world) = decoded else {
        return Err(Error::Component("the binary is a WIT package, not a component".into()));
    };
    let name = |key: &wit_parser::WorldKey| match key {
        wit_parser::WorldKey::Name(n) => n.clone(),
        wit_parser::WorldKey::Interface(id) => {
            resolve.id_of(*id).unwrap_or_else(|| format!("{id:?}"))
        }
    };
    let w = &resolve.worlds[world];
    Ok((w.exports.keys().map(name).collect(), w.imports.keys().map(name).collect()))
}

/// The core modules a component embeds, with the imports and exports of each.
fn core_modules(component: &[u8]) -> Result<Vec<CoreModule>> {
    use wasmparser::{Chunk, Parser, Payload};

    let mut ranges = Vec::new();
    let mut stack: Vec<Parser> = Vec::new();
    let mut cur = Parser::new(0);
    let mut offset = 0;
    // A nested module or component is walked with its own parser; only the byte
    // range of each core module is kept, to be parsed on its own below.
    loop {
        let Chunk::Parsed { payload, consumed } = cur
            .parse(&component[offset..], true)
            .map_err(|e| Error::Component(format!("malformed component: {e}")))?
        else {
            break;
        };
        offset += consumed;
        match payload {
            Payload::ModuleSection { parser, unchecked_range } => {
                ranges.push(unchecked_range);
                stack.push(cur);
                cur = parser;
            }
            Payload::ComponentSection { parser, .. } => {
                stack.push(cur);
                cur = parser;
            }
            Payload::End(_) => match stack.pop() {
                Some(p) => cur = p,
                None => break,
            },
            _ => {}
        }
    }
    let mut out = Vec::new();
    for range in ranges {
        let bytes = component
            .get(range.clone())
            .ok_or_else(|| Error::Component("truncated core module".into()))?;
        out.push(core_module(out.len(), range, bytes)?);
    }
    Ok(out)
}

fn core_module(index: usize, range: Range<usize>, bytes: &[u8]) -> Result<CoreModule> {
    use wasmparser::{Parser, Payload, TypeRef};

    let mut imports = Vec::new();
    let mut exports = Vec::new();
    for payload in Parser::new(0).parse_all(bytes) {
        match payload.map_err(|e| Error::Component(format!("malformed core module: {e}")))? {
            Payload::ImportSection(s) => {
                for i in s.into_imports() {
                    let i = i.map_err(|e| Error::Component(e.to_string()))?;
                    imports.push(Import {
                        module: i.module.to_string(),
                        name: i.name.to_string(),
                        is_func: matches!(i.ty, TypeRef::Func(_)),
                    });
                }
            }
            Payload::ExportSection(s) => {
                for e in s {
                    let e = e.map_err(|e| Error::Component(e.to_string()))?;
                    exports.push(e.name.to_string());
                }
            }
            _ => {}
        }
    }
    let has = |name: &str| exports.iter().any(|e| e == name).then(|| name.to_string());
    // The adapter is the module that *provides* wasi_snapshot_preview1 rather
    // than importing it.
    let is_wasi_adapter = exports.iter().any(|e| e.starts_with("wasi_snapshot_preview1"))
        || (imports.iter().any(|i| i.module.starts_with("wasi:"))
            && !exports.iter().any(|e| e.starts_with("fmi:fmi3/")));
    Ok(CoreModule {
        index,
        range,
        memory: has("memory"),
        realloc: has("cabi_realloc"),
        initializer: has("_initialize").or_else(|| has("__wasm_call_ctors")),
        is_wasi_adapter,
        imports,
        exports,
    })
}
