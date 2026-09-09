//! `wasm-bindgen` with the command line the CLI has, built from the pinned
//! `wasm-bindgen-cli-support` instead of installed separately.
//!
//! Only the options the build actually passes are accepted; an unknown one is an
//! error rather than a silently ignored flag.

use std::path::PathBuf;
use std::process::ExitCode;

use wasm_bindgen_cli_support::{Bindgen, EncodeInto};

const USAGE: &str = "\
usage: omc-wasm-bindgen <input.wasm> --out-dir DIR [options]

  -o, --out-dir DIR           where to write the generated package
      --out-name NAME         base name of the generated files
      --target TARGET         bundler (default), web, nodejs, no-modules, deno
      --no-modules-global VAR global the no-modules target defines
      --typescript            emit .d.ts files (the default)
      --no-typescript         do not emit .d.ts files
      --omit-imports          leave imports out of the generated JS
      --omit-default-module-path
                              do not derive the module path from import.meta.url
      --split-linked-modules  write linked modules as separate files
      --debug                 emit debug assertions in the generated JS
      --keep-debug            keep the DWARF sections of the module
      --keep-lld-exports      keep the exports lld generated
      --no-demangle           leave Rust symbol names mangled
      --remove-name-section   strip the name section
      --remove-producers-section
                              strip the producers section
      --encode-into MODE      never, always or test (default)
";

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("omc-wasm-bindgen: {e}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<(), String> {
    let mut args = std::env::args().skip(1);
    let mut input: Option<PathBuf> = None;
    let mut out_dir: Option<PathBuf> = None;
    let mut target = "bundler".to_owned();
    let mut no_modules_global: Option<String> = None;
    let mut b = Bindgen::new();
    // The CLI's defaults, which the library sets the other way: without a module
    // path `init()` has nowhere to fetch the .wasm from.
    b.typescript(true).omit_default_module_path(false);

    while let Some(arg) = args.next() {
        let mut value = |name: &str| args.next().ok_or_else(|| format!("{name} needs a value"));
        match arg.as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Ok(());
            }
            "-o" | "--out-dir" => out_dir = Some(PathBuf::from(value(&arg)?)),
            "--out-name" => {
                b.out_name(&value(&arg)?);
            }
            "--target" => target = value(&arg)?,
            "--no-modules-global" => no_modules_global = Some(value(&arg)?),
            "--encode-into" => {
                b.encode_into(match value(&arg)?.as_str() {
                    "never" => EncodeInto::Never,
                    "always" => EncodeInto::Always,
                    "test" => EncodeInto::Test,
                    other => return Err(format!("unknown --encode-into mode '{other}'")),
                });
            }
            "--typescript" => {
                b.typescript(true);
            }
            "--no-typescript" => {
                b.typescript(false);
            }
            "--omit-imports" => {
                b.omit_imports(true);
            }
            "--omit-default-module-path" => {
                b.omit_default_module_path(true);
            }
            "--split-linked-modules" => {
                b.split_linked_modules(true);
            }
            "--debug" => {
                b.debug(true);
            }
            "--keep-debug" => {
                b.keep_debug(true);
            }
            "--keep-lld-exports" => {
                b.keep_lld_exports(true);
            }
            "--no-demangle" => {
                b.demangle(false);
            }
            "--remove-name-section" => {
                b.remove_name_section(true);
            }
            "--remove-producers-section" => {
                b.remove_producers_section(true);
            }
            _ if arg.starts_with('-') => return Err(format!("unknown option '{arg}'\n\n{USAGE}")),
            _ if input.is_some() => return Err(format!("more than one input module: '{arg}'")),
            _ => input = Some(PathBuf::from(arg)),
        }
    }

    let input = input.ok_or_else(|| format!("no input module\n\n{USAGE}"))?;
    let out_dir = out_dir.ok_or_else(|| format!("no --out-dir\n\n{USAGE}"))?;

    match target.as_str() {
        "bundler" => b.bundler(true),
        "web" => b.web(true),
        "nodejs" => b.nodejs(true),
        "no-modules" => b.no_modules(true),
        "deno" => b.deno(true),
        other => return Err(format!("unknown --target '{other}'\n\n{USAGE}")),
    }
    .map_err(|e| e.to_string())?;
    // Only meaningful once the mode is set, so not while parsing.
    if let Some(g) = no_modules_global {
        b.no_modules_global(&g).map_err(|e| e.to_string())?;
    }

    b.input_path(&input)
        .generate(&out_dir)
        // A schema mismatch here means this crate and the bindgen'd one resolved
        // different wasm-bindgen versions, which the pins are there to prevent.
        .map_err(|e| format!("{e:?}"))
}
