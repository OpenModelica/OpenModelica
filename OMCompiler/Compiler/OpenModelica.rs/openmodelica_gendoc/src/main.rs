//! Generates the Modelica library documentation published at
//! <https://build.openmodelica.org/Documentation/>.
//!
//! Replaces OMCompiler/Examples/GenerateDoc.mos, which drove the scripting API
//! statement by statement and shelled out to Python for every library's icons.

use std::collections::HashMap;
use std::path::{Path, PathBuf};

use arcstr::ArcStr;

#[cfg(feature = "jemalloc")]
#[global_allocator]
static GLOBAL: tikv_jemallocator::Jemalloc = tikv_jemallocator::Jemalloc;
use openmodelica_ast::Absyn;
use rayon::prelude::*;

mod doc;
mod heap;
mod html;
mod icons;
mod index;
mod links;
mod packages;

use doc::ClassDoc;

const USAGE: &str = "\
usage: omgendoc [options] LIBRARY...

  LIBRARY              a library name, optionally NAME/VERSION

  -o, --output-dir DIR   where to write the documentation (default: .)
      --icons-dir DIR    pre-rendered icons, named <Class>.svg, as a path
                         relative to the output directory (default: Icons)
      --modelica-path P  library search path (default: $OPENMODELICALIBRARY)
      --package-index F  index.json naming each library's source repository
                         (default: index.json in the first search path entry)
      --playground URL   the simulator a runnable class opens in, with
                         {version} standing for the playground build (default:
                         playground/{version}/simulator/index.html, which is
                         same-origin and so cross-origin isolated with the
                         documentation). --no-playground leaves it out
      --playground-versions V,V
                         the builds the page offers, first one selected
                         (default: latest,demo)
      --testing-conf F   OpenModelicaLibraryTesting's configs/conf.json, which
                         says which libraries are tested against their
                         development version. The index links a report for
                         each of those; without it no report is linked
  -j, --jobs N           libraries rendered at once, and page-rendering
                         threads (default: the machine's physical cores)
      --skip CLASS       render no graphics for this class or anything under
                         it; repeatable, and a package name skips the package.
                         Instantiating some classes exhausts memory, which no
                         single process can survive, so they have to be left
                         alone. Each thread names the class it is rendering in
                         <output>/index/graphics/<Library>.<thread>.current, so
                         a run that dies says what was in flight
      --skip-diagrams CLASS  render this class' icon but not its diagram, and
                         likewise under it; repeatable. A diagram costs more
                         than an icon, since it instantiates the type of every
                         component it draws
      --no-icons         skip icon rendering (HTML only, much faster)
      --no-diagrams      render icons but not diagrams
      --chunk N          most classes per instantiation scope (default 1000)
      --max-memory GB    live memory to work within (default 24): a thread
                         past it drops its instantiation scope and takes a
                         fresh one. Not a ceiling; the cgroup is that
      --stats            report memory in use after each library
  -h, --help             this message
";

struct Options {
    output_dir: PathBuf,
    icons_dir: String,
    modelica_path: Option<String>,
    package_index: Option<PathBuf>,
    testing_conf: Option<PathBuf>,
    playground: Option<String>,
    playground_versions: Vec<String>,
    libraries: Vec<(String, Option<String>)>,
    jobs: Option<usize>,
    icons: bool,
    diagrams: bool,
    chunk: usize,
    skip: Vec<String>,
    skip_diagrams: Vec<String>,
    max_memory: u64,
    stats: bool,
}

fn parse_args() -> Result<Options, String> {
    let mut options = Options {
        output_dir: PathBuf::from("."),
        icons_dir: String::from("Icons"),
        modelica_path: None,
        package_index: None,
        testing_conf: None,
        playground: Some(String::from("playground/{version}/simulator/index.html")),
        playground_versions: vec![String::from("latest"), String::from("demo")],
        libraries: Vec::new(),
        jobs: None,
        icons: true,
        diagrams: true,
        chunk: 1000,
        skip: Vec::new(),
        skip_diagrams: Vec::new(),
        max_memory: 24,
        stats: false,
    };
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        let mut value = || args.next().ok_or_else(|| format!("{arg} needs a value"));
        match arg.as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                std::process::exit(0);
            }
            "-o" | "--output-dir" => options.output_dir = PathBuf::from(value()?),
            "--icons-dir" => options.icons_dir = value()?,
            "--no-icons" => options.icons = false,
            "--no-diagrams" => options.diagrams = false,
            "--skip" => options.skip.push(value()?.to_string()),
            "--skip-diagrams" => options.skip_diagrams.push(value()?.to_string()),
            "--chunk" => {
                options.chunk = value()?.parse().map_err(|_| "--chunk needs a number")?
            }
            "--max-memory" => {
                options.max_memory = value()?
                    .parse()
                    .map_err(|_| "--max-memory needs a number")?
            }
            "--stats" => options.stats = true,
            "--modelica-path" => options.modelica_path = Some(value()?),
            "--package-index" => options.package_index = Some(PathBuf::from(value()?)),
            "--testing-conf" => options.testing_conf = Some(PathBuf::from(value()?)),
            "--playground" => options.playground = Some(value()?),
            "--playground-versions" => {
                options.playground_versions = value()?
                    .split(',')
                    .map(str::trim)
                    .filter(|version| !version.is_empty())
                    .map(String::from)
                    .collect()
            }
            "--no-playground" => options.playground = None,
            "-j" | "--jobs" => {
                options.jobs = Some(value()?.parse().map_err(|_| "-j needs a number")?)
            }
            _ if arg.starts_with('-') => return Err(format!("unknown option {arg}")),
            _ => {
                let (name, version) = match arg.split_once('/') {
                    Some((n, v)) => (n.to_string(), Some(v.to_string())),
                    None => (arg.clone(), None),
                };
                options.libraries.push((name, version));
            }
        }
    }
    if options.libraries.is_empty() {
        return Err("no library given".to_string());
    }
    Ok(options)
}

/// The parts of the omc startup a parse needs: the global roots, the error
/// buffer and the command-line flags.
/// Every global root is thread-local, so a rendering thread starts with a
/// compiler that has not been initialised -- `AbsynToSCode` reaches the
/// instance cache through a `BackendInterface` table whose default entries
/// panic when called. Each thread therefore does this for itself.
fn init_compiler() -> Result<(), &'static str> {
    openmodelica_util::System::initGarbageCollector();
    openmodelica_util::Global::initialize();
    openmodelica_error::ErrorExt::registerModelicaFormatError();
    openmodelica_error::ErrorExt::initAssertionFunctions();
    openmodelica_util::FlagsUtil::new(metamodelica::nil())?;
    // AbsynToSCode reaches the instance cache through the BackendInterface
    // table, which the compiler fills from the backend and a frontend-only
    // host has to fill itself.
    openmodelica_frontend_dump::BackendInterface::initializeWithoutBackend();
    Ok(())
}

fn modelica_path(options: &Options) -> String {
    if let Some(path) = &options.modelica_path {
        return path.clone();
    }
    if let Ok(path) = std::env::var("OPENMODELICALIBRARY") {
        return path;
    }
    openmodelica_util::Settings::getModelicaPath(false)
        .map(|s| s.to_string())
        .unwrap_or_default()
}

/// Every library the documented ones name in `uses`, transitively, as SCode.
/// The top scope needs them: an icon is mostly inherited, and the base class
/// usually lives in another library — without MSL present, anything that
/// `extends Modelica.Icons.Package` renders nothing.
///
/// A wave at a time, because a library's own `uses` is not known until it is
/// parsed; nothing within a wave depends on anything else in it.
fn dependencies(documented: &[ClassDoc], path: &str, stats: bool) -> Vec<icons::SCodeProgram> {
    fn enqueue(
        uses: &[(String, String)],
        seen: &mut std::collections::HashSet<String>,
        frontier: &mut Vec<(String, String)>,
    ) {
        for (name, version) in uses {
            if seen.insert(name.clone()) {
                frontier.push((name.clone(), version.clone()));
            }
        }
    }

    let roots = || documented.iter().filter(|c| c.path.len() == 1);
    let mut seen: std::collections::HashSet<String> =
        roots().map(|c| c.name().to_string()).collect();
    let mut frontier: Vec<(String, String)> = Vec::new();
    for class in roots() {
        enqueue(&class.uses, &mut seen, &mut frontier);
    }

    let mut parts = Vec::new();
    let mut loaded_names: Vec<String> = Vec::new();
    while !frontier.is_empty() {
        let wave: Vec<Option<(String, Vec<(String, String)>, icons::SCodeProgram)>> = frontier
            .par_iter()
            .map(|(name, version)| {
                let version = (!version.is_empty()).then_some(version.as_str());
                let program = load_library(name, version, path).ok()?;
                let uses = program.classes.iter().flat_map(doc::uses_of).collect();
                Some((name.clone(), uses, icons::translate(name, &program)))
            })
            .collect();
        frontier.clear();
        for (name, uses, scode) in wave.into_iter().flatten() {
            enqueue(&uses, &mut seen, &mut frontier);
            loaded_names.push(name);
            parts.push(scode);
        }
    }
    if stats && !loaded_names.is_empty() {
        eprintln!("omgendoc: also loaded {}", loaded_names.join(", "));
    }
    parts
}

/// Headroom for what one thread can be holding mid-class: the budget is only
/// consulted between classes, and instantiating one class in a deeply
/// inherited library allocates gigabytes before it returns.
const PER_JOB_MEMORY: u64 = 2_000_000_000;

/// How many threads render at once: `--jobs`, or the machine's physical cores.
/// Not every hardware thread -- this work is bound by memory traffic rather
/// than arithmetic, so a sibling thread on a core adds little speed while
/// adding another class' worth of live instantiation. Jenkins passes the
/// figure it uses for `-n`.
fn graphics_jobs(options: &Options) -> usize {
    options
        .jobs
        .map(|jobs| jobs.max(1))
        .unwrap_or_else(physical_cores)
}

fn physical_cores() -> usize {
    let mut cores = std::collections::HashSet::new();
    if let Ok(entries) = std::fs::read_dir("/sys/devices/system/cpu") {
        for entry in entries.flatten() {
            let topology = entry.path().join("topology");
            let read = |file: &str| std::fs::read_to_string(topology.join(file)).ok();
            if let (Some(package), Some(core)) = (read("physical_package_id"), read("core_id")) {
                cores.insert((package, core));
            }
        }
    }
    if cores.is_empty() {
        return std::thread::available_parallelism().map_or(1, |n| n.get());
    }
    cores.len()
}

/// Every library's graphics, in this process, one library at a time.
///
/// Libraries are done in sequence so only one library's instantiation is ever
/// live; the threads work on chunks of *that* library. The SCode universe is
/// shared by all of them: Absyn and SCode cannot reach a traced allocation, so
/// they are held through `Arc` and are `Send + Sync`, while what instantiation
/// expands is `Gc` and never leaves the thread that made it.
fn render_graphics(
    options: &Options,
    classes: &[ClassDoc],
    libraries: &[usize],
    universes: &HashMap<ArcStr, icons::SCodeProgram>,
    resolver: &links::Resolver,
    store: Option<&mut icons::Icons>,
    resolved: &mut [icons::Resolved],
) -> Vec<(Option<u128>, Option<u128>)> {
    let mut digests = vec![(None, None); classes.len()];
    let Some(store) = store else {
        return digests;
    };
    let markers = options.output_dir.join("index/graphics");
    if let Err(e) = std::fs::create_dir_all(&markers) {
        eprintln!("omgendoc: {}: {e}", markers.display());
        return digests;
    }

    let icon_dir = store.dir().to_path_buf();
    let store = std::sync::Mutex::new(store);
    let pool = rayon::ThreadPoolBuilder::new()
        .num_threads(graphics_jobs(options))
        .start_handler(|_| {
            if let Err(e) = init_compiler() {
                eprintln!("omgendoc: {e}");
            }
        })
        .build();

    for (done, &root) in libraries.iter().enumerate() {
        let name = classes[root].index_name();
        let name = name.as_str();
        let Some(scode) = universes.get(&classes[root].tag) else {
            continue;
        };
        // Filtered here rather than inside the loop, so a skipped class costs
        // nothing at all: a library that is skipped whole then has no members,
        // and no thread builds a top scope over the universe only to discard
        // every class it was given.
        let members: Vec<usize> = subtree(classes, root)
            .into_iter()
            .filter(|&i| !skipped(&classes[i].qualified_name(), &options.skip))
            .collect();
        if members.is_empty() {
            eprintln!(
                "omgendoc: [{}/{}] {name}: skipped",
                done + 1,
                libraries.len()
            );
            continue;
        }
        let marker = markers.join(links::plain_stem(name));
        // Said before the library is rendered, not after: nothing else is
        // written until every library is finished, so without this a long one
        // looks exactly like a hung one for as long as it takes. AixLib is half
        // an hour of honest work.
        eprintln!(
            "omgendoc: [{}/{}] {name}: {} classes",
            done + 1,
            libraries.len(),
            members.len()
        );
        let started = std::time::Instant::now();
        let render = || {
            render_library(
                options, classes, &members, scode, resolver, &store, &icon_dir, &marker,
            )
        };
        let rendered = match &pool {
            Ok(pool) => pool.install(render),
            Err(_) => render(),
        };
        // `nfTopScope` and the caches beside it are thread-local global roots
        // holding what this library expanded until the *next* instantiation on
        // that thread replaces them, so dropping the scope is not enough.
        let clear = |_: rayon::BroadcastContext<'_>| {
            openmodelica_nf_api::NFInstanceAPI::clearTopScopeCache()
        };
        match &pool {
            Ok(pool) => {
                pool.broadcast(clear);
            }
            Err(_) => openmodelica_nf_api::NFInstanceAPI::clearTopScopeCache(),
        }
        heap::release();
        let mut graphics = 0;
        for (index, found, names) in rendered {
            graphics += usize::from(found.0.is_some()) + usize::from(found.1.is_some());
            digests[index] = found;
            resolved[index] = names;
        }
        for thread in 0..graphics_jobs(options) {
            let _ = std::fs::remove_file(markers.join(format!(
                "{}.{thread}.current",
                links::plain_stem(name)
            )));
        }
        eprintln!(
            "omgendoc: [{}/{}] {name}: {graphics} graphics in {:.1} s",
            done + 1,
            libraries.len(),
            started.elapsed().as_secs_f64()
        );
        if options.stats {
            report(&format!("{name} rendered"));
        }
    }
    digests
}

/// One library's icons and diagrams, as `(class index, digests)`.
///
/// The library is cut into chunks and the chunks go out to the pool; each
/// thread builds its own top scope over the shared SCode, renders its chunk and
/// drops the scope, which is what releases the instantiation. Live memory is
/// therefore `--jobs` scopes of at most `--chunk` classes, all from this one
/// library.
fn render_library(
    options: &Options,
    classes: &[ClassDoc],
    members: &[usize],
    scode: &icons::SCodeProgram,
    resolver: &links::Resolver,
    store: &std::sync::Mutex<&mut icons::Icons>,
    icon_dir: &Path,
    marker: &Path,
) -> Vec<(usize, (Option<u128>, Option<u128>), icons::Resolved)> {
    let jobs = graphics_jobs(options);
    // Sized against `--max-memory` rather than fixed: what a class costs to
    // instantiate varies by two orders of magnitude between libraries -- a
    // fraction of a megabyte in OpenIPSL, a couple of hundred in AixLib -- so
    // no one count of classes per scope suits both. The figure is process
    // wide, so every thread gives way at once.
    let allowed = options.max_memory * 1_000_000_000;
    let budget = allowed
        .saturating_sub(jobs as u64 * PER_JOB_MEMORY)
        .max(allowed / 2);
    // The chunk is a ceiling on a scope, not the unit of work: at the default
    // of 1000 a library of 1898 classes would make two tasks and keep two
    // threads busy. Cut it so there are several pieces per thread, which also
    // evens out libraries whose expensive classes sit together.
    let pieces = members.len().div_ceil(jobs.saturating_mul(4).max(1)).max(1);
    members
        .par_chunks(options.chunk.max(1).min(pieces))
        // `map_init` rather than `map`: a thread keeps its top scope across
        // chunks instead of building one per chunk. Building it means
        // `makeTopNode` over the whole universe, and doing that once per chunk
        // was most of what the threads were busy with.
        .map_init(
            || None::<icons::Scope>,
            |held: &mut Option<icons::Scope>, chunk: &[usize]| {
            let mut done = Vec::new();
            let mut next = 0;
            while next < chunk.len() {
                if held.is_none() {
                    // A scope rayon discarded with its init state took no
                    // `clearTopScopeCache` with it, and the cells of a scope
                    // outlive the tree until something empties the set.
                    openmodelica_nf_api::NFInstanceAPI::clearTopScopeCache();
                    *held = icons::Scope::build(scode);
                }
                let Some(scope) = held.as_ref() else {
                    eprintln!("omgendoc: could not build a top scope; no graphics");
                    return done;
                };
                while next < chunk.len() {
                    let index = chunk[next];
                    let class = &classes[index];
                    let name = class.qualified_name();
                    next += 1;
                    // Not even a lookup: reaching `HeaterCooler_u.Medium`
                    // means expanding the model enclosing it, which expands
                    // the medium. `link_names` resolves the base by name.
                    if class
                        .derived
                        .as_ref()
                        .is_some_and(|derived| !derived.own_graphics)
                    {
                        done.push((index, (None, None), icons::Resolved::default()));
                        continue;
                    }
                    if let Some(path) = icons::path_of(&name) {
                        // Named before it is rendered, not after: instantiating
                        // some classes exhausts memory and takes the process
                        // with it, and these files are then the only record of
                        // what was in flight. One per thread, since each has a
                        // class in hand and any of them could be the one.
                        let _ = std::fs::write(
                            marker.with_extension(format!(
                                "{}.current",
                                rayon::current_thread_index().unwrap_or(0)
                            )),
                            &name,
                        );
                        // The frontend's own lookup for what this class'
                        // type references denote, taken while a scope exists
                        // rather than approximated from the AST afterwards.
                        let names = scope.resolved_names(&path);
                        let icon = scope.icon_svg(&path, class.name());
                        let diagram = (options.diagrams
                            && !skipped(&name, &options.skip_diagrams))
                            .then(|| scope.diagram_svg(&path, class.name()))
                            .flatten();
                        if icon.is_some() || diagram.is_some() {
                            // A Bitmap names its image with a `modelica://`
                            // URI, which a browser cannot follow; and a linked
                            // file would not help, since an SVG in an `<img>`
                            // never fetches one. Embed it -- before taking the
                            // lock, since it scans the whole document and every
                            // thread would otherwise queue behind it.
                            let prepare = |svg: Option<String>| {
                                svg.map(|svg| {
                                    let svg = resolver.inline_uris(&svg);
                                    (icons::digest(&svg), svg)
                                })
                            };
                            let (icon, diagram) = (prepare(icon), prepare(diagram));
                            // Only the "is this new" check is serialised; the
                            // file is written outside the lock by whoever
                            // claimed it.
                            let mut fresh = Vec::new();
                            {
                                let mut store = store.lock().unwrap_or_else(|e| e.into_inner());
                                for (digest, _) in [icon.as_ref(), diagram.as_ref()].into_iter().flatten() {
                                    fresh.push(store.claim(*digest));
                                }
                            }
                            let mut fresh = fresh.into_iter();
                            let mut keep = |entry: Option<(u128, String)>| {
                                entry.map(|(digest, svg)| {
                                    if fresh.next().unwrap_or(false) {
                                        icons::write_svg(icon_dir, digest, &svg);
                                    }
                                    digest
                                })
                            };
                            done.push((index, (keep(icon), keep(diagram)), names));
                        } else {
                            done.push((index, (None, None), names));
                        }
                    }
                    // After every class, not every tenth: one AixLib class
                    // can cost a couple of hundred megabytes, and between
                    // classes is the only place the budget can be consulted.
                    if heap::over(budget) {
                        break;
                    }
                }
                if next < chunk.len() {
                    // Left the loop early, so the budget is spent: drop the
                    // scope and take a fresh one for the rest of this chunk.
                    // `clearTopScopeCache` drops mkTop's cache and the roots
                    // that own what the scope expanded, without which the next
                    // one starts where this ended.
                    *held = None;
                    openmodelica_nf_api::NFInstanceAPI::clearTopScopeCache();
                }
            }
            done
        },
        )
        .reduce(Vec::new, |mut a, mut b| {
            a.append(&mut b);
            a
        })
}

/// An `experiment` annotation on a base class marks its descendants too: a
/// library declares it once, on the partial example.
fn inherit_experiment(classes: &mut [ClassDoc]) {
    for index in 0..classes.len() {
        if classes[index].experiment {
            continue;
        }
        let mut at = index;
        // Bounded rather than a visited set: a real chain is a link or two.
        'chain: for _ in 0..16 {
            for extends in &classes[at].extends {
                let Some(base) = extends.base.filter(|&b| b != index) else {
                    continue;
                };
                if classes[base].experiment {
                    classes[index].experiment = true;
                    break 'chain;
                }
                at = base;
                continue 'chain;
            }
            break;
        }
    }
}

/// Take the graphics of the first class along the chain of aliases that has
/// any, the alias itself never having been instantiated.
fn inherit_graphics(classes: &[ClassDoc], digests: &mut [(Option<u128>, Option<u128>)]) {
    for index in 0..classes.len() {
        if !classes[index]
            .derived
            .as_ref()
            .is_some_and(|derived| !derived.own_graphics)
        {
            continue;
        }
        // Bounded rather than a visited set: a real chain is a link or two.
        let mut at = index;
        for _ in 0..16 {
            let Some(base) = classes[at].derived.as_ref().and_then(|d| d.base_class) else {
                break;
            };
            if base == index {
                break;
            }
            at = base;
            if digests[at] != (None, None) {
                digests[index] = digests[at];
                break;
            }
        }
    }
}

/// A class is skipped if it is named, or if a named package encloses it.
fn skipped(name: &str, skip: &[String]) -> bool {
    skip.iter().any(|s| {
        name == s
            || (name.len() > s.len()
                && name.starts_with(s.as_str())
                && name[s.len()..].starts_with('.'))
    })
}

/// The other documented versions of this class' library, and the page the
/// class has in each -- the library's own page where the class is absent.
fn version_links(
    classes: &[ClassDoc],
    class: usize,
    copies: &HashMap<&str, Vec<usize>>,
    pages: &HashMap<String, usize>,
) -> Vec<html::VersionLink> {
    let doc = &classes[class];
    let library = doc.path[0].as_str();
    let Some(roots) = copies.get(library) else {
        return Vec::new();
    };
    roots
        .iter()
        .map(|&root| {
            let tag = &classes[root].tag;
            let mut name = match tag.is_empty() {
                true => library.to_string(),
                false => format!("{library}@{tag}"),
            };
            for segment in &doc.path[1..] {
                name.push('.');
                name.push_str(segment);
            }
            let target = pages.get(&name).copied().unwrap_or(root);
            html::VersionLink {
                label: classes[root]
                    .installed_version()
                    .unwrap_or(classes[root].version.as_str())
                    .to_string(),
                href: html::page_link(&classes[target]),
                current: *tag == doc.tag,
            }
        })
        .collect()
}

fn package_index(options: &Options, modelica_path: &str) -> PathBuf {
    if let Some(path) = &options.package_index {
        return path.clone();
    }
    let first = modelica_path.split(':').next().unwrap_or("");
    Path::new(first).join("index.json")
}

fn is_builtin(name: &str) -> bool {
    name == "OpenModelica"
}

/// `OpenModelica` is not on the load path: the compiler defines it in the
/// builtin files it parses at startup. Keep that class and drop the rest of
/// the initial environment, which is the predefined types.
fn load_builtin(name: &str) -> Result<Absyn::Program, &'static str> {
    let program =
        openmodelica_nf_api::NFInstanceAPI::builtinAbsyn().map_err(|_| "no builtin classes")?;
    let classes: metamodelica::List<metamodelica::Ref<Absyn::Class>> = program
        .classes
        .iter()
        .filter(|class| class.name.as_str() == name)
        .cloned()
        .collect();
    if classes.is_empty() {
        return Err("not a builtin class");
    }
    Ok(Absyn::Program {
        classes,
        within_: program.within_.clone(),
    })
}

fn load_library(
    name: &str,
    version: Option<&str>,
    path: &str,
) -> Result<Absyn::Program, &'static str> {
    if is_builtin(name) {
        return load_builtin(name);
    }
    let priority: metamodelica::List<ArcStr> = match version {
        Some(v) => std::iter::once(ArcStr::from(v)).collect(),
        None => metamodelica::nil(),
    };
    openmodelica_loader::ClassLoader::loadClass(
        metamodelica::Ref::new(Absyn::Path::IDENT {
            name: ArcStr::from(name),
        }),
        priority,
        ArcStr::from(path),
        None,
        false,
        false,
    )
}

/// What the process holds, after handing back what can be handed back.
fn report(label: &str) {
    heap::release();
    let (allocated, active, mapped, retained) = heap::stats();
    let gb = |bytes: u64| bytes as f64 / 1e9;
    eprintln!(
        "omgendoc: {label}: {:.2} GB allocated, {:.2} GB active, {:.2} GB mapped, \
         {:.2} GB retained, {:.2} GB resident",
        gb(allocated),
        gb(active),
        gb(mapped),
        gb(retained),
        gb(heap::resident()),
    );
}

/// Point each `extends`, each short class definition's base and each
/// component's type at the class it names, using what the frontend resolved
/// during the graphics pass. Matched on the name rather than on position, so
/// the two orderings need not agree. A name outside the documented set -- a
/// builtin, or a library that was not loaded -- stays unlinked.
fn link_names(classes: &mut [ClassDoc], resolved: Vec<icons::Resolved>) {
    // Keyed by the version too: two copies of a library declare the same
    // qualified names, and a class links within its own copy.
    let index: HashMap<(ArcStr, String), usize> = classes
        .iter()
        .enumerate()
        .map(|(i, c)| ((c.tag.clone(), c.qualified_name()), i))
        .collect();
    for (class, names) in classes.iter_mut().zip(resolved) {
        let tag = class.tag.clone();
        let bases: HashMap<&str, &str> = names
            .bases
            .iter()
            .map(|(written, full)| (written.as_str(), full.as_str()))
            .collect();
        let types: HashMap<&str, &str> = names
            .components
            .iter()
            .map(|(name, full)| (name.as_str(), full.as_str()))
            .collect();
        let lookup = |name: &str| {
            index
                .get(&(tag.clone(), name.to_string()))
                .or_else(|| index.get(&(ArcStr::new(), name.to_string())))
                .copied()
        };
        let find = |table: &HashMap<&str, &str>, key: &str| {
            table.get(key).and_then(|full| lookup(full))
        };
        if let Some(derived) = class.derived.as_mut() {
            derived.base_class = find(&bases, &derived.base).or_else(|| {
                // An alias was not instantiated, so the frontend resolved
                // nothing for it: look the base up outwards through the
                // enclosing scopes. Imports and inherited scopes are not
                // followed -- this decides a link, not a semantic question.
                let scope = &class.path[..class.path.len() - 1];
                (0..=scope.len()).rev().find_map(|depth| {
                    let mut candidate = scope[..depth].join(".");
                    if !candidate.is_empty() {
                        candidate.push('.');
                    }
                    candidate.push_str(&derived.base);
                    lookup(&candidate)
                })
            });
        }
        for extends in class.extends.iter_mut() {
            extends.base = find(&bases, &extends.path);
        }
        for component in class.components.iter_mut() {
            component.type_class = find(&types, &component.name);
        }
    }
}

fn write_resources(output_dir: &Path, resources: &HashMap<String, PathBuf>) {
    for (target, source) in resources {
        let destination = output_dir.join(target);
        if destination.exists() {
            continue;
        }
        if let Some(parent) = destination.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        if let Err(e) = std::fs::copy(source, &destination) {
            eprintln!("omgendoc: {}: {e}", source.display());
        }
    }
}

fn run() -> Result<(), String> {
    let options = parse_args()?;
    let _ = rayon::ThreadPoolBuilder::new()
        .num_threads(graphics_jobs(&options))
        .build_global();
    init_compiler().map_err(|e| e.to_string())?;
    std::fs::create_dir_all(&options.output_dir).map_err(|e| e.to_string())?;

    let path = modelica_path(&options);
    let mut classes: Vec<ClassDoc> = Vec::new();
    let mut libraries: Vec<usize> = Vec::new();
    let mut icon_digests: Vec<(Option<u128>, Option<u128>)>;
    let mut store = options
        .icons
        .then(|| icons::Icons::new(&options.output_dir, &options.icons_dir))
        .transpose()
        .map_err(|e| e.to_string())?;
    // `(version tag, library, SCode)`: the tag decides which universe the
    // library's graphics are drawn against.
    let mut parts: Vec<(ArcStr, String, icons::SCodeProgram)> = Vec::new();
    // Libraries are independent, so parse them at the same time. ClassLoader
    // already parses the files *within* one in parallel; this fills the cores
    // between libraries and for the many libraries too small to fill them on
    // their own. `par_iter().collect()` keeps the order, so what lands in the
    // arena does not depend on which thread finished first.
    let loading = rayon::ThreadPoolBuilder::new()
        .num_threads(graphics_jobs(&options))
        .start_handler(|_| {
            if let Err(e) = init_compiler() {
                eprintln!("omgendoc: {e}");
            }
        })
        .build();
    let load_all = || {
        options
            .libraries
            .par_iter()
            // `doc::collect` walks the whole program to build the ClassDoc
            // arena and is pure, so it belongs on the loading thread too --
            // left in the splice below it was ten seconds of one core while
            // eleven waited.
            .map(|(name, version)| {
                load_library(name, version.as_deref(), &path).map(|program| {
                    let docs = doc::collect(&program);
                    // Already in every universe; a second copy of a
                    // top-level class leaves the top scope unbuildable.
                    let scode = match is_builtin(name) {
                        true => metamodelica::nil(),
                        false => icons::translate(name, &program),
                    };
                    (docs, scode)
                })
            })
            .collect::<Vec<_>>()
    };
    let loaded = match &loading {
        Ok(pool) => pool.install(load_all),
        Err(_) => load_all(),
    };

    // A library named twice is documented twice. The first copy keeps the
    // plain page names; the rest are tagged `Modelica@master.Blocks.html`.
    let mut already: std::collections::HashSet<(&str, String)> = std::collections::HashSet::new();
    for ((name, version), result) in options.libraries.iter().zip(loaded) {
        match result {
            Ok((mut loaded, scode)) => {
                let offset = classes.len();
                let loaded_version = loaded
                    .iter()
                    .find(|c| c.path.len() == 1)
                    .and_then(|c| c.installed_version())
                    .unwrap_or_default()
                    .to_string();
                // `Foo/1.0.0` resolves to whatever installed version provides
                // it, which may be the one already documented.
                if !already.insert((name.as_str(), loaded_version.clone())) {
                    eprintln!("omgendoc: {name}: {loaded_version} is already documented");
                    continue;
                }
                let first = !already.iter().any(|(n, v)| *n == name && *v != loaded_version);
                let tag = if first {
                    ArcStr::new()
                } else {
                    ArcStr::from(match (loaded_version.as_str(), version) {
                        ("", Some(v)) => v.clone(),
                        ("", None) => classes.len().to_string(),
                        (v, _) => v.to_string(),
                    })
                };
                for class in &mut loaded {
                    class.tag = tag.clone();
                    for child in &mut class.children {
                        *child += offset;
                    }
                    if let Some(parent) = &mut class.parent {
                        *parent += offset;
                    }
                }
                libraries.extend(
                    loaded
                        .iter()
                        .enumerate()
                        .filter(|(_, c)| c.path.len() == 1)
                        .map(|(i, _)| i + offset),
                );
                classes.extend(loaded);
                parts.push((tag, name.clone(), scode));
            }
            Err(e) => eprintln!("omgendoc: {name}: {e}"),
        }
    }
    if classes.is_empty() {
        return Err("no library loaded".to_string());
    }
    if options.stats {
        report("all libraries parsed and translated");
    }
    links::resolve_aliases(classes.iter().map(|c| c.index_name()));

    let started = std::time::Instant::now();
    let find_dependencies = || dependencies(&classes, &path, options.stats);
    let dependency_parts: Vec<icons::SCodeProgram> = match &loading {
        Ok(pool) => pool.install(find_dependencies),
        Err(_) => find_dependencies(),
    };
    drop(loading);
    if options.stats {
        report(&format!(
            "dependencies loaded in {:.1} s",
            started.elapsed().as_secs_f64()
        ));
    }

    let joining = std::time::Instant::now();
    // One universe per tag: two versions declare the same top-level name, so
    // a class is instantiated against its own. A tagged library replaces its
    // untagged namesake throughout -- the master set is drawn against master.
    let tags: Vec<ArcStr> = {
        let mut tags: Vec<ArcStr> = vec![ArcStr::new()];
        for (tag, _, _) in &parts {
            if !tag.is_empty() && !tags.contains(tag) {
                tags.push(tag.clone());
            }
        }
        tags
    };
    let universes: HashMap<ArcStr, icons::SCodeProgram> = tags
        .iter()
        .filter_map(|tag| {
            let replaced: Vec<&str> = parts
                .iter()
                .filter(|(t, _, _)| t == tag)
                .map(|(_, library, _)| library.as_str())
                .collect();
            let chosen: Vec<icons::SCodeProgram> = dependency_parts
                .iter()
                .cloned()
                .chain(parts.iter().filter_map(|(t, library, scode)| {
                    let keep = t == tag || (t.is_empty() && !replaced.contains(&library.as_str()));
                    keep.then(|| scode.clone())
                }))
                .collect();
            icons::Scope::universe(&chosen).map(|universe| (tag.clone(), universe))
        })
        .collect();
    drop(parts);
    drop(dependency_parts);
    if options.stats {
        report(&format!(
            "universe joined in {:.1} s",
            joining.elapsed().as_secs_f64()
        ));
    }

    let mut resolver = links::Resolver::default();
    for class in &classes {
        resolver.add_class(&class.tag, &class.qualified_name(), &class.source_file);
    }
    let mut resolved: Vec<icons::Resolved> =
        (0..classes.len()).map(|_| icons::Resolved::default()).collect();
    icon_digests = render_graphics(
        &options,
        &classes,
        &libraries,
        &universes,
        &resolver,
        store.as_mut(),
        &mut resolved,
    );
    drop(universes);
    if options.stats {
        report("graphics rendered");
    }

    link_names(&mut classes, resolved);
    inherit_experiment(&mut classes);
    inherit_graphics(&classes, &mut icon_digests);

    let footer = footer();
    let icon_count = store.as_ref().map_or(0, icons::Icons::len);
    let urls = store.map(icons::Icons::finish).unwrap_or_default();
    let url_of = |d: Option<u128>| d.and_then(|d| urls.get(&d).cloned());
    let icon_urls: Vec<Option<String>> = icon_digests.iter().map(|d| url_of(d.0)).collect();
    let class_graphics: Vec<html::Graphics> = icon_digests
        .iter()
        .map(|d| html::Graphics {
            icon: url_of(d.0),
            diagram: url_of(d.1),
        })
        .collect();

    let mut copies: HashMap<&str, Vec<usize>> = HashMap::new();
    for &root in &libraries {
        copies.entry(classes[root].name()).or_default().push(root);
    }
    copies.retain(|_, roots| roots.len() > 1);
    let pages_by_name: HashMap<String, usize> = match copies.is_empty() {
        true => HashMap::new(),
        false => classes.iter().enumerate().map(|(i, c)| (c.index_name(), i)).collect(),
    };

    let playground = html::Playground {
        url: options.playground.clone().unwrap_or_default(),
        versions: options.playground_versions.clone(),
    };
    let pages: Vec<html::Page> = classes
        .par_iter()
        .enumerate()
        .map(|(i, class)| {
            let children: Vec<&ClassDoc> = class.children.iter().map(|&c| &classes[c]).collect();
            let child_icons: Vec<Option<String>> = class
                .children
                .iter()
                .map(|&c| class_graphics[c].icon.clone())
                .collect();
            html::render_class(
                &classes,
                i,
                &children,
                &class_graphics[i],
                &child_icons,
                &version_links(&classes, i, &copies, &pages_by_name),
                &playground,
                &resolver,
                &footer,
            )
        })
        .collect();

    let mut resources: HashMap<String, PathBuf> = HashMap::new();
    for page in &pages {
        for resource in &page.resources {
            resources.insert(resource.target.clone(), resource.source.clone());
        }
    }

    pages.par_iter().for_each(|page| {
        let file = options.output_dir.join(&page.file);
        if let Err(e) = std::fs::write(&file, &page.html) {
            eprintln!("omgendoc: {}: {e}", file.display());
        }
    });

    let sources = packages::Sources::read(&package_index(&options, &path));
    let tested = match &options.testing_conf {
        Some(file) => packages::Tested::read(file),
        None => packages::Tested::default(),
    };
    let entries: Vec<html::LibraryEntry<'_>> = libraries
        .iter()
        .map(|&i| {
            let name = classes[i].name();
            let version = classes[i].installed_version().unwrap_or(classes[i].version.as_str());
            html::LibraryEntry {
                doc: &classes[i],
                icon: class_graphics[i].icon.clone(),
                version: version.to_string(),
                source: sources.url(name, version),
                support: sources.support(name, version).unwrap_or_default().to_string(),
                tested: tested.url(name, version),
            }
        })
        .collect();
    std::fs::write(
        options.output_dir.join("index.html"),
        html::render_index(&entries, &playground, &footer),
    )
    .map_err(|e| e.to_string())?;
    std::fs::write(
        options.output_dir.join("style.css"),
        include_str!("style.css"),
    )
    .map_err(|e| e.to_string())?;
    write_assets(&options.output_dir, &classes, &libraries, &icon_urls)?;
    write_resources(&options.output_dir, &resources);

    eprintln!(
        // "graphics files", not "graphics": the per-library lines count every
        // icon and diagram rendered, this counts the files they were stored
        // in, which is far fewer because most classes inherit their icon
        // unchanged and the store is content addressed.
        "omgendoc: {} classes, {} libraries, {} resource files, {} graphics files",
        pages.len(),
        entries.len(),
        resources.len(),
        icon_count
    );
    Ok(())
}

/// The sidebar script and the index files it loads. They are `.js` rather than
/// `.json` so the offline tarball works from `file://`, where `fetch` is
/// blocked but a `<script>` tag is not.
fn write_assets(
    output_dir: &Path,
    classes: &[ClassDoc],
    libraries: &[usize],
    icons: &[Option<String>],
) -> Result<(), String> {
    let assets = output_dir.join("assets");
    let tree_dir = output_dir.join("index/tree");
    let text_dir = output_dir.join("index/text");
    for dir in [&assets, &tree_dir, &text_dir] {
        std::fs::create_dir_all(dir).map_err(|e| e.to_string())?;
    }
    std::fs::write(assets.join("gendoc.js"), include_str!("assets/gendoc.js"))
        .map_err(|e| e.to_string())?;

    let members: Vec<Vec<usize>> = libraries.iter().map(|&r| subtree(classes, r)).collect();
    let counts: Vec<usize> = members.iter().map(Vec::len).collect();
    std::fs::write(
        output_dir.join("index/libraries.js"),
        format!(
            "omdoc.libraries({});\n",
            index::libraries(classes, libraries, &counts, icons)
        ),
    )
    .map_err(|e| e.to_string())?;

    // A plain global, so a page has it whatever order its scripts run in.
    let mut aliases = String::from("window.omdocAliases={");
    let mut entries: Vec<(&String, &String)> = links::aliases().iter().collect();
    entries.sort();
    for (i, (name, stem)) in entries.iter().enumerate() {
        if i > 0 {
            aliases.push(',');
        }
        index::escape(name, &mut aliases);
        aliases.push(':');
        index::escape(stem, &mut aliases);
    }
    aliases.push_str("};\n");
    std::fs::write(output_dir.join("index/aliases.js"), aliases).map_err(|e| e.to_string())?;

    libraries
        .par_iter()
        .zip(&members)
        .for_each(|(&root, members)| {
            let name = classes[root].index_name();
            let mut quoted = String::new();
            index::escape(&name, &mut quoted);
            let file = links::plain_stem(&name);
            let write = |dir: &Path, kind: &str, body: String| {
                let path = dir.join(format!("{file}.js"));
                let content = format!("omdoc.{kind}({quoted},{body});\n");
                if let Err(e) = std::fs::write(&path, content) {
                    eprintln!("omgendoc: {}: {e}", path.display());
                }
            };
            write(&tree_dir, "tree", index::tree(classes, members, icons));
            write(&text_dir, "text", index::text(classes, members));
        });
    Ok(())
}

fn subtree(classes: &[ClassDoc], root: usize) -> Vec<usize> {
    let mut out = Vec::new();
    let mut stack = vec![root];
    while let Some(class) = stack.pop() {
        out.push(class);
        stack.extend(classes[class].children.iter().rev());
    }
    out
}

fn footer() -> String {
    format!(
        "<footer class=\"om-footer\">Generated by \
         <a href=\"https://openmodelica.org\">OpenModelica</a> {}.</footer>\n",
        html::escape(openmodelica_revision::REVISION)
    )
}

fn main() {
    if let Err(e) = run() {
        eprintln!("omgendoc: {e}");
        eprint!("{USAGE}");
        std::process::exit(1);
    }
}
