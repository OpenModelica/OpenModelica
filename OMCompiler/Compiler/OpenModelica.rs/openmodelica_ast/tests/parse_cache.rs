use arcstr::ArcStr;
use openmodelica_ast::ParserExt;
use std::path::{Path, PathBuf};
use std::time::Duration;

fn entries(cache: &Path) -> Vec<PathBuf> {
    std::fs::read_dir(cache)
        .into_iter()
        .flatten()
        .flatten()
        .flat_map(|schema| std::fs::read_dir(schema.path()).into_iter().flatten().flatten())
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|e| e == "ast"))
        .collect()
}

fn wait_for(mut done: impl FnMut() -> bool) -> bool {
    (0..200).any(|_| {
        done() || {
            std::thread::sleep(Duration::from_millis(25));
            false
        }
    })
}

#[test]
fn hit_and_corrupt_entry() {
    let dir = std::env::temp_dir().join(format!("omc-parse-cache-{}", std::process::id()));
    let cache = dir.join("cache");
    std::fs::create_dir_all(&dir).unwrap();
    // The only test in this binary, so no parse has fixed the cache directory yet.
    unsafe { std::env::set_var("OPENMODELICA_PARSE_CACHE", &cache) };
    let src = dir.join("M.mo");
    std::fs::write(&src, "model M Real x(start = 1); equation der(x) = -x; end M;\n").unwrap();
    let path = ArcStr::from(src.to_str().unwrap());
    let parse = || {
        let p = ParserExt::parse(
            path.clone(),
            path.clone(),
            3,
            ArcStr::from("UTF-8"),
            1000,
            false,
            false,
            ArcStr::from(""),
            None,
        );
        format!("{:?}", p.unwrap())
    };

    let parsed = parse();
    assert!(wait_for(|| entries(&cache).len() == 1), "no entry written");
    let entry = entries(&cache).remove(0);
    let size = std::fs::metadata(&entry).unwrap().len();
    assert_eq!(parse(), parsed);

    std::fs::write(&entry, b"not an entry").unwrap();
    assert_eq!(parse(), parsed);
    assert!(
        wait_for(|| std::fs::metadata(&entry).is_ok_and(|m| m.len() == size)),
        "entry not rewritten"
    );
    let _ = std::fs::remove_dir_all(&dir);
}
