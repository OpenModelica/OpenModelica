//! Icons rendered from the NF model instance — the same path FMI 3.0 export
//! uses, so modifiers and redeclares are resolved rather than approximated.

use std::collections::{HashMap, HashSet};
use std::hash::{Hash, Hasher};
use std::path::{Path, PathBuf};

use openmodelica_ast::Absyn;

/// Content-addressed icon files. Most of a library's classes inherit their icon
/// unchanged, so the same SVG comes back thousands of times; naming each file
/// after its content writes it once and lets every page point at it.
///
/// The name is the shortest prefix of the digest that is unique across the run,
/// so the URLs stay short — which matters when 84 000 pages each carry a few.
/// The length is only known once every icon has been seen, so files are written
/// under the full digest and renamed by [`Icons::finish`].
pub struct Icons {
    dir: PathBuf,
    url_prefix: String,
    written: HashSet<u128>,
}

impl Icons {
    pub fn new(output_dir: &Path, url_prefix: &str) -> std::io::Result<Icons> {
        let dir = output_dir.join(url_prefix);
        std::fs::create_dir_all(&dir)?;
        Ok(Icons {
            dir,
            url_prefix: url_prefix.to_string(),
            written: HashSet::new(),
        })
    }

    /// Record `svg`, writing the file the first time that content appears.
    pub fn store(&mut self, svg: &str) -> u128 {
        let digest = digest(svg);
        if self.claim(digest) {
            write_svg(&self.dir, digest, svg);
        }
        digest
    }

    /// Whether this content is new, and so whether the caller has to write it.
    /// Split out so a threaded caller can hash and write outside the lock and
    /// hold it only for this: hashing an icon and writing a file are the bulk
    /// of the work, and every thread would otherwise queue behind them.
    pub fn claim(&mut self, digest: u128) -> bool {
        self.written.insert(digest)
    }

    pub fn dir(&self) -> &Path {
        &self.dir
    }

    /// Note a digest, so it is shortened and renamed with the rest.
    pub fn record(&mut self, digest: u128) {
        self.written.insert(digest);
    }

    pub fn len(&self) -> usize {
        self.written.len()
    }

    /// Shorten every file name to the shortest prefix length that keeps them
    /// all distinct, and return the URL for each digest.
    pub fn finish(self) -> HashMap<u128, String> {
        let digests: Vec<u128> = self.written.into_iter().collect();
        let mut length = 6;
        while length < 32 {
            let shortened: HashSet<u128> = digests.iter().map(|d| d >> (4 * (32 - length))).collect();
            if shortened.len() == digests.len() {
                break;
            }
            length += 1;
        }
        let mut urls = HashMap::with_capacity(digests.len());
        for digest in digests {
            let short = format!("{:0width$x}", digest >> (4 * (32 - length)), width = length);
            let from = self.dir.join(format!("{digest:032x}.svg"));
            let to = self.dir.join(format!("{short}.svg"));
            if from != to && let Err(e) = std::fs::rename(&from, &to) {
                eprintln!("omgendoc: {}: {e}", from.display());
            }
            urls.insert(digest, format!("{}/{short}.svg", self.url_prefix));
        }
        urls
    }
}

/// 128 bits, so 84 000 icons collide with probability ~1e-29.
/// Write one icon under its full digest; `Icons::finish` shortens the names.
pub fn write_svg(dir: &Path, digest: u128, svg: &str) {
    if let Err(e) = std::fs::write(dir.join(format!("{digest:032x}.svg")), svg) {
        eprintln!("omgendoc: {}: {e}", dir.display());
    }
}

pub fn digest(content: &str) -> u128 {
    let half = |salt: u8| {
        let mut hasher = std::collections::hash_map::DefaultHasher::new();
        salt.hash(&mut hasher);
        content.hash(&mut hasher);
        hasher.finish() as u128
    };
    (half(1) << 64) | half(2)
}

/// The top scope a library's classes are instantiated in. Held for the whole
/// library and dropped with it.
pub struct Scope {
    top: metamodelica::Ref<openmodelica_nf_frontend::NFInstNode::InstNode::InstNode>,
}

pub type SCodeProgram =
    metamodelica::List<metamodelica::Ref<openmodelica_frontend_types::SCode::Element>>;

impl Scope {
    /// The SCode every scope is built from, translated once.
    pub fn universe(program: &Absyn::Program) -> Option<SCodeProgram> {
        openmodelica_nf_api::NFInstanceAPI::universeSCode(program.clone()).ok()
    }

    /// A fresh scope over that SCode. One per library: what a scope expands is
    /// released when it is dropped.
    pub fn build(scode: &SCodeProgram) -> Option<Scope> {
        let top = openmodelica_nf_api::NFInstanceAPI::topFromSCode(scode.clone()).ok()?;
        Some(Scope { top })
    }

    pub fn icon_svg(&self, class: &metamodelica::Ref<Absyn::Path>, name: &str) -> Option<String> {
        let start = std::time::Instant::now();
        let json =
            openmodelica_nf_api::NFInstanceAPI::iconJSONFromTop(self.top.clone(), class.clone())
                .ok();
        let drawing = record(&INSTANCE_NANOS, start);
        let svg = openmodelica_omgraphics::OMGraphics::icon_svg_from_json(&json?, name);
        record(&DRAWING_NANOS, drawing);
        svg
    }

    /// What this class' type references denote, fully qualified: `(as written,
    /// resolved)` for its base classes, and `(component name, resolved)` for
    /// its components' types.
    pub fn resolved_names(&self, class: &metamodelica::Ref<Absyn::Path>) -> Resolved {
        let (bases, components) = match openmodelica_nf_api::NFInstanceAPI::resolveNamesFromTop(
            self.top.clone(),
            class.clone(),
        ) {
            Ok(pair) => pair,
            Err(_) => return Resolved::default(),
        };
        let pairs = |list: metamodelica::List<(arcstr::ArcStr, arcstr::ArcStr)>| {
            list.iter()
                .map(|(a, b)| (a.to_string(), b.to_string()))
                .collect()
        };
        Resolved { bases: pairs(bases), components: pairs(components) }
    }

    pub fn diagram_svg(
        &self,
        class: &metamodelica::Ref<Absyn::Path>,
        name: &str,
    ) -> Option<String> {
        let start = std::time::Instant::now();
        let json =
            openmodelica_nf_api::NFInstanceAPI::diagramJSONFromTop(self.top.clone(), class.clone())
                .ok();
        let drawing = record(&INSTANCE_NANOS, start);
        let svg = openmodelica_omgraphics::OMGraphics::diagram_svg_from_json(&json?, name);
        record(&DRAWING_NANOS, drawing);
        svg
    }
}

/// How the graphics time divides between producing the model instance's JSON
/// and drawing an SVG from it, so it is clear which half to work on.
static INSTANCE_NANOS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
static DRAWING_NANOS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

fn record(into: &std::sync::atomic::AtomicU64, since: std::time::Instant) -> std::time::Instant {
    let now = std::time::Instant::now();
    into.fetch_add(
        (now - since).as_nanos() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    now
}

/// Seconds spent in the instance API and in OMGraphics.
pub fn timing() -> (f64, f64) {
    let seconds = |c: &std::sync::atomic::AtomicU64| {
        c.load(std::sync::atomic::Ordering::Relaxed) as f64 / 1e9
    };
    (seconds(&INSTANCE_NANOS), seconds(&DRAWING_NANOS))
}

/// What one class' type references resolve to.
#[derive(Default)]
pub struct Resolved {
    /// `(base class as written, fully qualified)`.
    pub bases: Vec<(String, String)>,
    /// `(component name, fully qualified type)`.
    pub components: Vec<(String, String)>,
}

/// `A.B.C` as an Absyn path.
pub fn path_of(qualified_name: &str) -> Option<metamodelica::Ref<Absyn::Path>> {
    let mut segments = qualified_name.split('.').rev();
    let mut path = metamodelica::Ref::new(Absyn::Path::IDENT {
        name: arcstr::ArcStr::from(segments.next()?),
    });
    for segment in segments {
        path = metamodelica::Ref::new(Absyn::Path::QUALIFIED {
            name: arcstr::ArcStr::from(segment),
            path,
        });
    }
    Some(path)
}
