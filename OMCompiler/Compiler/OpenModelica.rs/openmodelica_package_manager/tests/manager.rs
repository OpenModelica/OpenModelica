#![cfg(all(feature = "curl", not(target_arch = "wasm32")))]

use std::path::{Path, PathBuf};

use openmodelica_package_manager::call;
use serde_json::{Value, json};

struct Setup {
    root: PathBuf,
    home: PathBuf,
}

fn s(p: &Path) -> String {
    p.to_str().unwrap().to_owned()
}

fn url(p: &Path) -> String {
    format!("file://{}", s(p))
}

impl Setup {
    fn new(name: &str) -> Setup {
        let root = std::env::temp_dir().join(format!("pkgmanager-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&root);
        let home = root.join("home");
        std::fs::create_dir_all(home.join(".openmodelica/libraries")).unwrap();
        Setup { root, home }
    }

    fn libraries(&self) -> PathBuf {
        self.home.join(".openmodelica/libraries")
    }

    /// A zip with `files` below a GitHub-like top directory.
    fn zip(&self, name: &str, files: &[(&str, &str)]) -> PathBuf {
        let src = self.root.join("src").join(name);
        for (path, text) in files {
            let file = src.join("Repo-0123").join(path);
            std::fs::create_dir_all(file.parent().unwrap()).unwrap();
            std::fs::write(file, text).unwrap();
        }
        let zip = self.root.join(format!("{name}.zip"));
        let top = s(&src.join("Repo-0123"));
        openmodelica_zip::zip_paths(&s(&zip), &[(&top, "Repo-0123")], &[]).unwrap();
        zip
    }

    fn write_index(&self, index: &Value) {
        std::fs::write(self.libraries().join("index.json"), index.to_string()).unwrap();
    }

    fn call(&self, op: &str, args: Value) -> Value {
        let mut request = json!({
            "op": op,
            "home": s(&self.home),
            "installationDir": s(&self.root.join("install")),
            "modelicaPath": s(&self.libraries()),
            "groupDelimiter": ":",
            "maxParallel": 2,
            "indexUrl": url(&self.root.join("remote-index.json")),
        });
        for (k, v) in args.as_object().unwrap() {
            request[k] = v.clone();
        }
        serde_json::from_str(&call(&request.to_string())).unwrap()
    }
}

impl Drop for Setup {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.root);
    }
}

/// `resolve` as omc runs it: answers `needMetadata` with `metadata` until there
/// is a solution. Returns it and the files asked for.
fn resolve(setup: &Setup, args: Value, metadata: impl Fn(&str) -> Value) -> (Value, Vec<String>) {
    ask(setup, "resolve", args, metadata)
}

/// `op`, answering `needMetadata` with `metadata`.
fn ask(setup: &Setup, op: &str, args: Value, metadata: impl Fn(&str) -> Value) -> (Value, Vec<String>) {
    let mut asked = Vec::new();
    let mut args = args;
    loop {
        let r = setup.call(op, args.clone());
        let Some(need) = r["needMetadata"].as_array() else {
            return (r, asked);
        };
        let answers: Vec<Value> = need
            .iter()
            .map(|f| {
                let file = f.as_str().unwrap();
                asked.push(file.to_owned());
                json!({"file": file, "metadata": metadata(file)})
            })
            .collect();
        assert!(asked.len() < 100, "{asked:?}");
        args["metadata"] = json!(answers);
    }
}

fn names(response: &Value) -> Vec<&str> {
    response["messages"]
        .as_array()
        .unwrap()
        .iter()
        .map(|m| m["name"].as_str().unwrap())
        .collect()
}

fn install(setup: &Setup, pkg: &str, version: &str, exact: bool) -> Value {
    setup.call(
        "installPackage",
        json!({"pkg": pkg, "version": version, "exactMatch": exact}),
    )
}

fn index(setup: &Setup, a_sha: &str) -> Value {
    let zip = setup.zip(
        "repo",
        &[
            ("A/package.mo", "package A end A;"),
            ("B.mo", "package B end B;"),
            ("sub/C.mo", "package C end C;"),
            ("sub/Resources/data.txt", "data"),
        ],
    );
    let mut index = json!({"libs": {
        "A": {"versions": {
            "1.0.0": {"zipfile": url(&zip), "path": "A", "sha": a_sha, "uses": {"B": "2.0.0"},
                      "convertFromVersion": ["0.9.0"]},
            "2.0.0": {"zipfile": url(&zip), "path": "A", "sha": "a2", "convertFromVersion": ["1.0.0", "0.9.0"]}}},
        "B": {"versions": {"2.0.0": {"zipfile": url(&zip), "path": "B.mo", "sha": "b"}}},
        "C": {"versions": {"1.0.0": {"zipfile": url(&zip), "path": "sub/C.mo", "sha": "c",
                                      "singleFileStructureCopyAllFiles": true}}}}});
    for lib in index["libs"].as_object_mut().unwrap().values_mut() {
        for (version, entry) in lib["versions"].as_object_mut().unwrap() {
            entry["version"] = json!(version);
        }
    }
    index
}

#[test]
fn installs_with_uses_and_upgrades() {
    let setup = Setup::new("install");
    setup.write_index(&index(&setup, "a1"));
    let lib = setup.libraries();

    let r = install(&setup, "A", "1.0.0", true);
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(names(&r), ["NOTIFY_PKG_INSTALL_DONE", "NOTIFY_PKG_INSTALL_DONE"]);
    assert_eq!(
        std::fs::read_to_string(lib.join("A 1.0.0/package.mo")).unwrap(),
        "package A end A;"
    );
    assert_eq!(
        std::fs::read_to_string(lib.join("B 2.0.0/package.mo")).unwrap(),
        "package B end B;"
    );
    let meta: Value =
        serde_json::from_str(&std::fs::read_to_string(lib.join("A 1.0.0/openmodelica.metadata.json")).unwrap())
            .unwrap();
    assert_eq!(meta["sha"], "a1");
    assert!(setup.home.join(".openmodelica/cache/repo.zip").exists());

    let r = install(&setup, "A", "1.0.0", true);
    assert_eq!(names(&r), ["NOTIFY_PKG_ALREADY_INSTALLED"]);
    assert_eq!(r["messages"][0]["tokens"], json!(["A", "1.0.0"]));

    setup.write_index(&index(&setup, "a1-rebuilt"));
    let r = install(&setup, "A", "1.0.0", true);
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(names(&r), ["NOTIFY_PKG_UPGRADE_DONE"]);
    assert_eq!(r["messages"][0]["tokens"], json!(["a1-rebuilt", "a1"]));

    let r = install(&setup, "C", "1.0.0", true);
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(
        std::fs::read_to_string(lib.join("C 1.0.0/package.mo")).unwrap(),
        "package C end C;"
    );
    assert!(lib.join("C 1.0.0/Resources/data.txt").exists());

    let r = setup.call("installedLibraries", json!({}));
    assert_eq!(r["libraries"], json!(["A", "B", "C"]));
    let r = install(&setup, "A", "2.0.0", true);
    assert_eq!(r["ok"], true, "{r}");
    let r = setup.call("installedVersions", json!({"name": "A"}));
    assert_eq!(r["versions"], json!(["2.0.0", "1.0.0"]));
    let r = setup.call("installedVersions", json!({"name": "Nothing"}));
    assert_eq!(r["ok"], false);
    let r = setup.call("upgrade", json!({"newest": true}));
    assert_eq!(r["ok"], true, "{r}");
    assert!(
        names(&r)
            .iter()
            .all(|n| *n == "NOTIFY_PKG_ALREADY_INSTALLED" || *n == "NOTIFY_PKG_NO_INSTALL"),
        "{r}"
    );
}

#[test]
fn reports_what_cannot_be_installed() {
    let setup = Setup::new("missing");
    setup.write_index(&index(&setup, "a1"));
    let r = install(&setup, "A", "3.0.0", false);
    assert_eq!(r["ok"], false);
    assert_eq!(names(&r), ["ERROR_PKG_NOT_FOUND_VERSION"]);
    assert_eq!(r["messages"][0]["tokens"][2], "2.0.0\n1.0.0");

    let mut newer = index(&setup, "a1");
    let a = newer["libs"]["A"]["versions"].as_object_mut().unwrap();
    let mut entry = a.remove("1.0.0").unwrap();
    entry["provides"] = json!(["1.0.0"]);
    a.insert("1.0.1".to_owned(), entry);
    setup.write_index(&newer);
    let r = install(&setup, "A", "1.0.0", true);
    assert_eq!(names(&r), ["ERROR_PKG_NOT_EXACT_MATCH"]);
    assert_eq!(r["messages"][0]["tokens"], json!(["A", "1.0.0", "1.0.1"]));

    let mut broken = index(&setup, "a1");
    broken["libs"]["B"]["versions"]["2.0.0"]["zipfile"] = json!(url(&setup.root.join("nothing.zip")));
    setup.write_index(&broken);
    let r = install(&setup, "B", "2.0.0", true);
    assert_eq!(r["ok"], false);
    assert_eq!(names(&r), ["runtimeError"]);
    assert!(!setup.libraries().join("B 2.0.0").exists());

    let r = setup.call("versions", json!({"name": "A", "version": "1.0.0"}));
    assert_eq!(r["versions"], json!(["1.0.0"]));
    let r = setup.call(
        "installPackage",
        json!({"pkg": "A", "version": "1.0.0", "modelicaPath": "/elsewhere"}),
    );
    assert_eq!(
        names(&r),
        ["ERROR_PKG_INDEX_NOT_ON_PATH", "ERROR_PKG_NOT_FOUND_VERSION"]
    );
}

#[test]
fn conversions() {
    let setup = Setup::new("convert");
    setup.write_index(&index(&setup, "a1"));
    let r = setup.call("convertFrom", json!({"name": "A", "version": "0.9.0"}));
    assert_eq!(r["versions"], json!(["2.0.0", "1.0.0"]));
    let r = setup.call("convertTo", json!({"name": "A", "version": "2.0.0"}));
    assert_eq!(r["versions"], json!(["1.0.0", "0.9.0"]));
    let r = setup.call("convertTo", json!({"name": "Z", "version": "2.0.0"}));
    assert_eq!(r["versions"], json!([]));
}

#[test]
fn downloads_the_index_and_reports_a_broken_one() {
    let setup = Setup::new("index");
    std::fs::write(setup.root.join("remote-index.json"), index(&setup, "a1").to_string()).unwrap();
    let r = setup.call("versions", json!({"name": "B", "version": "", "printError": true}));
    assert_eq!(names(&r), ["NOTIFY_PKG_INDEX_DOWNLOAD"]);
    assert_eq!(r["versions"], json!(["2.0.0"]));
    std::fs::write(setup.libraries().join("index.json"), "{").unwrap();
    let r = setup.call("installPackage", json!({"pkg": "B", "version": "2.0.0"}));
    assert!(names(&r).contains(&"ERROR_PKG_INDEX_NOT_PARSED"), "{r}");
    let r = setup.call(
        "resolve",
        json!({"requirements": [{"name": "B", "versions": ["2.0.0"], "origin": "t"}]}),
    );
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(names(&r), Vec::<&str>::new());
    let r = setup.call(
        "resolve",
        json!({"requirements": [{"name": "B", "versions": ["2.0.0"], "origin": "t"}], "install": true}),
    );
    assert_eq!(names(&r), ["ERROR_PKG_INDEX_NOT_PARSED"]);
}

#[test]
fn installs_cached_libraries_into_an_empty_home() {
    let setup = Setup::new("cached");
    let cache = setup.root.join("install/share/omlibrary/cache");
    std::fs::create_dir_all(&cache).unwrap();
    let idx = index(&setup, "a1");
    std::fs::copy(setup.root.join("repo.zip"), cache.join("repo.zip")).unwrap();
    std::fs::write(cache.join("index.json"), idx.to_string()).unwrap();
    std::fs::write(setup.root.join("remote-index.json"), idx.to_string()).unwrap();
    let r = setup.call("installCached", json!({}));
    let n = names(&r);
    assert_eq!(n.first(), Some(&"NOTIFY_INITIALIZING_USER_LIBRARIES"), "{r}");
    assert_eq!(n.last(), Some(&"NOTIFY_PKG_INDEX_DOWNLOAD"), "{r}");
    for lib in ["A 1.0.0", "A 2.0.0", "B 2.0.0", "C 1.0.0"] {
        assert!(setup.libraries().join(lib).join("package.mo").exists(), "{lib}: {r}");
    }
    assert!(!setup.home.join(".openmodelica/cache/repo.zip").exists());
    let r = setup.call("installCached", json!({}));
    assert_eq!(names(&r), Vec::<&str>::new());
}

#[test]
fn unpacks_prebuilt_wasm_modules() {
    let setup = Setup::new("wasm");
    let own = setup.zip("own", &[("libA.wasm", "a")]);
    let system = setup.zip("system", &[("libS.wasm", "s")]);
    let mut idx = index(&setup, "a1");
    idx["libs"]["B"]["versions"]["2.0.0"]["wasm"] =
        json!({"1": {"generation": 3, "zipfile": url(&own), "systemLibraries": ["S", "Missing"]}});
    idx["systemLibraries"] = json!({"S": {"wasm": {"1": {"zipfile": url(&system)}}}});
    let mut without = idx.clone();
    without["libs"]["B"]["versions"]["2.0.0"]
        .as_object_mut()
        .unwrap()
        .remove("wasm");
    setup.write_index(&without);
    let r = setup.call(
        "installPackage",
        json!({"pkg": "B", "version": "2.0.0", "exactMatch": true, "wasmAbi": 1}),
    );
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(r["wasmDirs"], json!([]));

    setup.write_index(&idx);
    let dir = setup.libraries().join("B 2.0.0");
    let r = setup.call(
        "missingWasmOfLoaded",
        json!({"files": [s(&dir.join("package.mo")), "/not/installed/package.mo"], "wasmAbi": 1}),
    );
    assert_eq!(r["wasmDirs"], json!([s(&dir)]), "{r}");
    assert_eq!(names(&r), ["compilerWarning"]);
    let wasm = dir.join("Resources/Library/wasm32-wasip1/omc-3");
    assert_eq!(std::fs::read_to_string(wasm.join("libA.wasm")).unwrap(), "a");
    assert_eq!(std::fs::read_to_string(wasm.join("S/libS.wasm")).unwrap(), "s");
    assert_eq!(std::fs::read_to_string(wasm.join(".omc-zipfile")).unwrap(), "own.zip");
    assert!(!dir.join("Resources/Library/wasm32-wasip1.lock").exists());

    let r = setup.call(
        "missingWasmOfLoaded",
        json!({"files": [s(&dir.join("package.mo"))], "wasmAbi": 1}),
    );
    assert_eq!(r["wasmDirs"], json!([]));

    let r = setup.call(
        "installPackage",
        json!({"pkg": "A", "version": "1.0.0", "exactMatch": true, "wasmAbi": 1}),
    );
    assert_eq!(r["ok"], true, "{r}");
    assert_eq!(r["wasmDirs"], json!([]));
}

#[test]
fn a_live_lock_is_respected() {
    let setup = Setup::new("lock");
    let own = setup.zip("own", &[("libA.wasm", "a")]);
    let mut idx = index(&setup, "a1");
    idx["libs"]["B"]["versions"]["2.0.0"]["wasm"] = json!({"1": {"generation": 3, "zipfile": url(&own)}});
    idx["systemLibraries"] = json!({});
    setup.write_index(&idx);
    let r = install(&setup, "B", "2.0.0", true);
    assert_eq!(r["ok"], true, "{r}");
    let dir = setup.libraries().join("B 2.0.0");
    std::fs::create_dir_all(dir.join("Resources/Library/wasm32-wasip1.lock/x")).unwrap();
    let r = setup.call(
        "missingWasmOfLoaded",
        json!({"files": [s(&dir.join("package.mo"))], "wasmAbi": 1}),
    );
    assert_eq!(r["wasmDirs"], json!([]));
    assert!(!dir.join("Resources/Library/wasm32-wasip1/omc-3").exists());
    std::fs::remove_dir_all(dir.join("Resources/Library/wasm32-wasip1.lock")).unwrap();
    let r = setup.call(
        "missingWasmOfLoaded",
        json!({"files": [s(&dir.join("package.mo"))], "wasmAbi": 1}),
    );
    assert_eq!(r["wasmDirs"], json!([s(&dir)]));
}

#[test]
fn installs_the_wasm_toolchain() {
    let setup = Setup::new("toolchain");
    let sysroot = setup.zip("sysroot", &[("lib/wasm32-wasip1/libc.so", "c")]);
    let cxx = setup.zip("cxx", &[("lib/wasm32-wasip1/libc++.so", "c++")]);
    let mut idx = index(&setup, "a1");
    setup.write_index(&idx);
    let r = setup.call("wasmToolchain", json!({"cxx": true}));
    assert_eq!(r["sysroot"], "");
    assert_eq!(names(&r), ["compilerError"]);
    idx["wasmToolchain"] = json!({"generation": 2, "zipfile": url(&sysroot), "cxx": {"zipfile": url(&cxx)}});
    setup.write_index(&idx);
    let r = setup.call("wasmToolchain", json!({"cxx": true}));
    let dir = setup.home.join(".openmodelica/wasm32-wasip1/omc-2/sysroot");
    assert_eq!(r["sysroot"], s(&dir), "{r}");
    assert!(dir.join("lib/wasm32-wasip1/libc++.so").exists());
}

#[test]
fn rejects_unknown_requests() {
    let r: Value = serde_json::from_str(&call(r#"{"op": "nothing"}"#)).unwrap();
    assert_eq!(r["ok"], false);
    let r: Value = serde_json::from_str(&call("{")).unwrap();
    assert_eq!(r["ok"], false);
}

#[test]
fn control_characters_in_requests() {
    let request = concat!(r#"{"op": "versions", "name": "A\a", "version": "1"#, "\t", r#"\v"}"#);
    let r: Value = serde_json::from_str(&call(request)).unwrap();
    assert_eq!(r["ok"], true, "{r}");
}

#[test]
fn index_file_is_read_again_when_it_changes() {
    let setup = Setup::new("reread");
    let ask = || setup.call("versions", json!({"name": "S", "version": "1.0.0", "printError": true}));
    std::fs::write(
        setup.libraries().join("index.json"),
        r#"{"libs": {"S": {"versions": {"1.0.0": {}}}}}"#,
    )
    .unwrap();
    assert_eq!(ask()["versions"], json!(["1.0.0"]));
    std::fs::write(
        setup.libraries().join("index.json"),
        r#"{"libs": {"S": {"versions": {"1.0.0": {}, "1.1.0": {"provides": ["1.0.0"]}}}}}"#,
    )
    .unwrap();
    assert_eq!(ask()["versions"], json!(["1.1.0", "1.0.0"]));
    std::fs::write(setup.libraries().join("index.json"), "{").unwrap();
    assert_eq!(names(&ask()), ["ERROR_PKG_INDEX_NOT_PARSED"]);
}

#[cfg(unix)]
#[test]
fn libraries_in_the_modelica_path() {
    let setup = Setup::new("mp");
    let (first, second) = (setup.root.join("mp1"), setup.root.join("mp2"));
    for (dir, lib) in [
        (&first, "A 1.0.0"),
        (&second, "A 1.0.0"),
        (&second, "A 2.0.0"),
        (&first, "B 1.0.0"),
    ] {
        std::fs::create_dir_all(dir.join(lib)).unwrap();
        std::fs::write(dir.join(lib).join("package.mo"), "").unwrap();
    }
    std::fs::write(
        first.join("A 1.0.0/openmodelica.metadata.json"),
        "{\"uses\": {\"B\": \"1.0.0\"}}",
    )
    .unwrap();
    std::fs::write(
        first.join("B 1.0.0/openmodelica.metadata.json"),
        "{\"uses\": {\"X\": \"1.0\t0\"}",
    )
    .unwrap();
    std::fs::write(second.join("C.mo"), "").unwrap();
    std::fs::create_dir_all(second.join("NoPackage 1.0.0")).unwrap();
    let checkout = setup.root.join("checkout");
    std::fs::create_dir_all(&checkout).unwrap();
    std::fs::write(checkout.join("package.mo"), "").unwrap();
    std::os::unix::fs::symlink(&checkout, second.join("D 3.0.0")).unwrap();
    let search_path = format!("{}:{}", s(&first), s(&second));
    let solve = |reqs: Value| {
        resolve(&setup, json!({"searchPath": search_path, "requirements": reqs}), |_| {
            Value::Null
        })
        .0
    };
    let out = solve(json!([
        {"name": "A", "versions": ["1.0.0"], "origin": "t"},
        {"name": "C", "origin": "t"},
        {"name": "D", "versions": ["default"], "origin": "t"}
    ]));
    assert_eq!(out["ok"], true, "{out}");
    assert_eq!(out["modelicaPath"], json!([s(&first), s(&second)]));
    let picked: Vec<(&str, &Value, &Value)> = out["selected"]
        .as_array()
        .unwrap()
        .iter()
        .map(|s| (s["name"].as_str().unwrap(), &s["modelicaPathIndex"], &s["file"]))
        .collect();
    assert_eq!(
        picked,
        [
            ("A", &json!(0), &json!("A 1.0.0")),
            ("B", &json!(0), &json!("B 1.0.0")),
            ("C", &json!(1), &json!("C.mo")),
            ("D", &json!(1), &json!("D 3.0.0"))
        ]
    );
    assert_eq!(names(&out), Vec::<&str>::new(), "a load does not download the index");
    let out = solve(json!([{"name": "NoPackage", "origin": "t"}]));
    assert_eq!(out["selected"], json!([]));
}

#[test]
fn metadata_from_top_level_files() {
    let setup = Setup::new("metadata");
    let mp = setup.root.join("mp");
    let metadata: Vec<(&str, Value)> = vec![
        ("MyLib 9.8.0", json!({"version": "9.8.0", "provides": ["9.7.0"]})),
        (
            "MyLib 9.9.0",
            json!({"version": "9.9.0", "provides": ["9.8.0", "9.7.0"]}),
        ),
        ("MyLib 10.0.0", json!({"version": "10.0.0"})),
        ("MyLib 10.1.0", json!({"version": "10.1.0", "provides": ["10.0.0"]})),
        ("User", json!({"version": "", "uses": {"Checkout": "2.0.0"}})),
        ("Checkout", json!({"version": "2.0.0"})),
    ];
    for (dir, _) in &metadata {
        std::fs::create_dir_all(mp.join(dir)).unwrap();
        std::fs::write(mp.join(dir).join("package.mo"), *dir).unwrap();
    }
    let answer = |file: &str| {
        let dir = file.strip_suffix("/package.mo").unwrap().rsplit('/').next().unwrap();
        metadata.iter().find(|(d, _)| *d == dir).unwrap().1.clone()
    };
    let load = |name: &str, version: &str| {
        let args =
            json!({"searchPath": s(&mp), "requirements": [{"name": name, "versions": [version], "origin": "t"}]});
        let (r, asked) = resolve(&setup, args, answer);
        let picked: Vec<String> = r["selected"]
            .as_array()
            .unwrap()
            .iter()
            .map(|s| format!("{} {}", s["name"].as_str().unwrap(), s["file"].as_str().unwrap()))
            .collect();
        (picked, asked)
    };
    let (picked, asked) = load("MyLib", "9.7.0");
    assert_eq!(picked, ["MyLib MyLib 9.9.0"]);
    assert_eq!(asked.len(), 4, "only the candidates: {asked:?}");
    assert_eq!(
        load("MyLib", "9.8.0"),
        (vec!["MyLib MyLib 9.9.0".to_owned()], vec![]),
        "cached"
    );
    assert_eq!(load("MyLib", "10.0.0").0, ["MyLib MyLib 10.1.0"]);
    assert_eq!(
        load("User", "").0,
        ["Checkout Checkout", "User User"],
        "version from the annotation"
    );
    let cached = std::fs::read_dir(setup.home.join(".openmodelica/cache/library-metadata"))
        .unwrap()
        .count();
    assert_eq!(cached, 6);
    std::fs::write(mp.join("Checkout/package.mo"), "changed").unwrap();
    assert_eq!(load("User", "").1.len(), 1, "parsed again after a change");
}

#[test]
fn library_path_ignores_uses() {
    let setup = Setup::new("libpath");
    let mp = setup.root.join("mp");
    for (dir, meta) in [
        (
            "Modelica 4.0.0",
            r#"{"uses": {"Complex": "4.0.0", "Missing": "1.0.0"}}"#,
        ),
        ("Complex 4.0.0", "{}"),
    ] {
        std::fs::create_dir_all(mp.join(dir)).unwrap();
        std::fs::write(mp.join(dir).join("package.mo"), "").unwrap();
        std::fs::write(mp.join(dir).join("openmodelica.metadata.json"), meta).unwrap();
    }
    let r = setup.call(
        "libraryPath",
        json!({"searchPath": s(&mp), "name": "Modelica", "version": "default"}),
    );
    assert_eq!(
        (r["ok"].clone(), r["file"].clone()),
        (json!(true), json!("Modelica 4.0.0")),
        "{r}"
    );
    let r = setup.call(
        "libraryPath",
        json!({"searchPath": s(&mp), "name": "Other", "version": "default"}),
    );
    assert_eq!(r["ok"], false);
}

#[test]
fn conversions_of_installed_libraries() {
    let setup = Setup::new("convertinstalled");
    let mp = setup.libraries();
    std::fs::create_dir_all(mp.join("Managed 2.0.0")).unwrap();
    std::fs::write(mp.join("Managed 2.0.0/package.mo"), "").unwrap();
    std::fs::write(
        mp.join("Managed 2.0.0/openmodelica.metadata.json"),
        r#"{"convertFromVersion": ["1.0.0"]}"#,
    )
    .unwrap();
    std::fs::create_dir_all(mp.join("Vendor")).unwrap();
    std::fs::write(mp.join("Vendor/package.mo"), "").unwrap();
    setup.write_index(&json!({"libs": {}}));
    let query = |op: &str, name: &str, version: &str| {
        let answer = |_: &str| json!({"version": "3.0.0", "converts": ["2.5.0"]});
        ask(&setup, op, json!({"name": name, "version": version}), answer).0["versions"].clone()
    };
    assert_eq!(query("convertFrom", "Managed", "1.0.0"), json!(["2.0.0"]));
    assert_eq!(query("convertTo", "Managed", "2.0.0"), json!(["1.0.0"]));
    assert_eq!(
        query("convertFrom", "Vendor", "2.5.0"),
        json!(["3.0.0"]),
        "from package.mo"
    );
    assert_eq!(query("convertTo", "Vendor", "3.0.0"), json!(["2.5.0"]));
    assert_eq!(query("convertFrom", "Vendor", "1.0.0"), json!([]));
}
