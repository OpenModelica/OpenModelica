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
      --max-memory GB    hard ceiling on this process (default 24), set as
                         RLIMIT_DATA. Nothing negotiates with it: a run that
                         reaches it dies, which is the point -- the alternative
                         is the OOM killer choosing a victim on a shared machine
      --stats            report memory in use after each library
  -h, --help             this message
";

struct Options {
    output_dir: PathBuf,
    icons_dir: String,
    modelica_path: Option<String>,
    package_index: Option<PathBuf>,
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

/// Every documented library plus every library their `uses` annotations name,
/// in one program. The top scope needs the dependencies: an icon is mostly
/// inherited, and the base class usually lives in another library — without
/// MSL present, anything that `extends Modelica.Icons.Package` renders nothing.
fn universe(
    programs: &[Absyn::Program],
    documented: &[ClassDoc],
    path: &str,
    dependencies: &mut HashMap<String, Absyn::Program>,
    stats: bool,
) -> Absyn::Program {
    let mut wanted: Vec<(String, String)> = Vec::new();
    for class in documented.iter().filter(|c| c.path.len() == 1) {
        wanted.extend(class.uses.iter().cloned());
    }
    let own: std::collections::HashSet<&str> = documented
        .iter()
        .filter(|c| c.path.len() == 1)
        .map(|c| c.name())
        .collect();

    let mut classes: Vec<metamodelica::Ref<Absyn::Class>> = programs
        .iter()
        .flat_map(|p| p.classes.iter().cloned())
        .collect();
    let mut seen: std::collections::HashSet<String> = own.iter().map(|s| s.to_string()).collect();
    let mut loaded_names: Vec<String> = Vec::new();
    while let Some((name, version)) = wanted.pop() {
        if !seen.insert(name.clone()) {
            continue;
        }
        if !dependencies.contains_key(&name) {
            let version = (!version.is_empty()).then_some(version.as_str());
            match load_library(&name, version, path) {
                Ok(dependency) => {
                    // A dependency has dependencies of its own.
                    for class in &dependency.classes {
                        wanted.extend(doc::uses_of(class));
                    }
                    dependencies.insert(name.clone(), dependency);
                }
                Err(_) => continue,
            }
        }
        if let Some(dependency) = dependencies.get(&name) {
            classes.extend(dependency.classes.iter().cloned());
            loaded_names.push(name);
        }
    }
    if stats && !loaded_names.is_empty() {
        eprintln!("omgendoc: also loaded {}", loaded_names.join(", "));
    }
    Absyn::Program {
        classes: classes.into_iter().collect(),
        within_: Absyn::Within::TOP,
    }
}

/// How many libraries to render at once: `--jobs`, or the machine's physical
/// cores. Not every hardware thread -- this work is bound by memory traffic
/// rather than arithmetic, so a sibling thread on a core adds little speed
/// while adding another library's worth of live instantiation. Jenkins passes
/// the figure it uses for `-n`.
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
    scode: Option<&icons::SCodeProgram>,
    resolver: &links::Resolver,
    store: Option<&mut icons::Icons>,
    resolved: &mut [icons::Resolved],
) -> Vec<(Option<u128>, Option<u128>)> {
    let mut digests = vec![(None, None); classes.len()];
    let (Some(store), Some(scode)) = (store, scode) else {
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
        let name = classes[root].name();
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
/// therefore `--jobs` scopes of `--chunk` classes, all from this one library.
/// The cost per class varies enormously -- a few milliseconds in OpenIPSL
/// against a second in IDEAS -- so the chunk is a plain count and `ulimit` is
/// what stops a class that will not be bounded at all.
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
    // Sized against the process ceiling rather than fixed: what a class costs
    // to instantiate varies by two orders of magnitude between libraries -- a
    // fraction of a megabyte in OpenIPSL, a couple of hundred in AixLib -- so
    // no one count of classes per scope suits both. Bytes in use is the figure
    // that falls when a scope is dropped, and it is shared by every thread, so
    // they all give way at once.
    // A quarter of the ceiling, not half: `RLIMIT_DATA` counts memory that is
    // mapped, which includes what has been freed but not returned, and that
    // runs about 1.8x bytes in use. Budgeting at half the ceiling therefore
    // spends nearly all of it.
    let budget = options.max_memory * 1_000_000_000 / 4;
    // The chunk is a ceiling on a scope, not the unit of work: at the default
    // of 1000 a library of 1898 classes would make two tasks and keep two
    // threads busy. Cut it so there are several pieces per thread, which also
    // evens out libraries whose expensive classes sit together.
    let jobs = graphics_jobs(options);
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
                    *held = icons::Scope::build(scode);
                }
                let Some(scope) = held.as_ref() else {
                    eprintln!("omgendoc: could not build a top scope; no graphics");
                    return done;
                };
                let mut since_check = 0;
                while next < chunk.len() {
                    let index = chunk[next];
                    let class = &classes[index];
                    let name = class.qualified_name();
                    next += 1;
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
                    since_check += 1;
                    // Resident size is an upper bound on bytes in use and costs
                    // a `read`, so it settles the common case; `mallinfo2`
                    // walks every free chunk in every arena and is only asked
                    // when the cheap bound says the answer might be yes.
                    // Every ten classes, not every twenty-five: a class costs
                    // AixLib a couple of hundred megabytes, so a coarser
                    // interval lets a scope run gigabytes past the budget
                    // before anything looks at it.
                    if since_check >= 10 {
                        since_check = 0;
                        if resident() > budget && heap_in_use() > budget {
                            break;
                        }
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

/// A class is skipped if it is named, or if a named package encloses it.
fn skipped(name: &str, skip: &[String]) -> bool {
    skip.iter().any(|s| {
        name == s
            || (name.len() > s.len()
                && name.starts_with(s.as_str())
                && name[s.len()..].starts_with('.'))
    })
}

fn package_index(options: &Options, modelica_path: &str) -> PathBuf {
    if let Some(path) = &options.package_index {
        return path.clone();
    }
    let first = modelica_path.split(':').next().unwrap_or("");
    Path::new(first).join("index.json")
}

fn load_library(
    name: &str,
    version: Option<&str>,
    path: &str,
) -> Result<Absyn::Program, &'static str> {
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

// glibc: bytes handed out by malloc, returning free pages to the OS, and the
// kernel's own ceiling on this process.
unsafe extern "C" {
    fn malloc_trim(pad: usize) -> i32;
    fn mallinfo2() -> MallInfo2;
    fn setrlimit(resource: i32, limit: *const RLimit) -> i32;
}

#[repr(C)]
struct RLimit {
    cur: u64,
    max: u64,
}

/// A hard ceiling on this process, so a class that cannot be instantiated
/// within any sane amount of memory takes the run down rather than the machine.
/// RLIMIT_DATA, not RLIMIT_AS: since Linux 4.7 it covers brk and private
/// anonymous mappings, which is what is actually occupied, where address space
/// counts reservations that were never touched.
fn limit_memory(gigabytes: u64) {
    const RLIMIT_DATA: i32 = 2;
    let bytes = gigabytes * 1_000_000_000;
    let limit = RLimit { cur: bytes, max: bytes };
    if unsafe { setrlimit(RLIMIT_DATA, &limit) } != 0 {
        eprintln!("omgendoc: could not set a {gigabytes} GB memory limit");
    }
}

#[repr(C)]
struct MallInfo2 {
    arena: usize,
    ordblks: usize,
    smblks: usize,
    hblks: usize,
    hblkhd: usize,
    usmblks: usize,
    fsmblks: usize,
    uordblks: usize,
    fordblks: usize,
    keepcost: usize,
}

/// Bytes malloc has handed out and not been given back, which is the only
/// figure that falls when a scope is dropped. Resident size does not: glibc
/// keeps a large fragmented heap mapped, and `malloc_trim` can only return
/// whole free pages, so RSS records a high-water mark and stays there. Budget
/// against RSS and a healthy process that is reusing its heap looks like a
/// runaway one.
fn heap_in_use() -> u64 {
    let info = unsafe { mallinfo2() };
    (info.uordblks + info.hblkhd) as u64
}

fn resident() -> u64 {
    let Ok(text) = std::fs::read_to_string("/proc/self/statm") else {
        return 0;
    };
    let resident: u64 = text
        .split_whitespace()
        .nth(1)
        .and_then(|v| v.parse().ok())
        .unwrap_or(0);
    resident * 4096
}

fn report(label: &str) {
    unsafe { malloc_trim(0) };
    eprintln!(
        "omgendoc: {label}: {:.2} GB in use, {:.2} GB resident",
        heap_in_use() as f64 / 1e9,
        resident() as f64 / 1e9
    );
}

/// Every class' icon and diagram. A scope is built over the shared SCode, used
/// until either `chunk` classes have gone through it or it has spent the
/// budget, then dropped and rebuilt — what a scope expands is released when it
/// goes. Each scope's digests reach `record` as soon as they exist, so a run
/// killed part way through has still reported what it managed.
///
/// Chunking is what bounds memory, because the cost per class varies hugely:
/// about 5 MB in MSL against some 800 MB in a deeply inherited library like
/// IDEAS or AixLib, where a single scope holding 25 classes reaches 19 GB. The
/// budget rather than `chunk` is what actually decides, since no one count
/// suits both.
///
/// The heap does not shrink back between scopes — glibc keeps it mapped and
/// reuses it — so a library settles at its high-water mark and stays there:
/// IDEAS holds 26 GB whether it has done 75 classes or 250. That is why the
/// budget is spent against `mallinfo2`, not resident size.
/// Point each `extends`, each short class definition's base and each
/// component's type at the class it names, using what the frontend resolved
/// during the graphics pass. Matched on the name rather than on position, so
/// the two orderings need not agree. A name outside the documented set -- a
/// builtin, or a library that was not loaded -- stays unlinked.
fn link_names(classes: &mut [ClassDoc], resolved: Vec<icons::Resolved>) {
    let index: HashMap<String, usize> = classes
        .iter()
        .enumerate()
        .map(|(i, c)| (c.qualified_name(), i))
        .collect();
    for (class, names) in classes.iter_mut().zip(resolved) {
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
        let find = |table: &HashMap<&str, &str>, key: &str| {
            table.get(key).and_then(|full| index.get(*full)).copied()
        };
        if let Some(derived) = class.derived.as_mut() {
            derived.base_class = find(&bases, &derived.base);
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
    limit_memory(options.max_memory);
    if let Some(jobs) = options.jobs {
        let _ = rayon::ThreadPoolBuilder::new()
            .num_threads(jobs)
            .build_global();
    }
    init_compiler().map_err(|e| e.to_string())?;
    std::fs::create_dir_all(&options.output_dir).map_err(|e| e.to_string())?;

    let path = modelica_path(&options);
    let mut classes: Vec<ClassDoc> = Vec::new();
    let mut libraries: Vec<usize> = Vec::new();
    let icon_digests: Vec<(Option<u128>, Option<u128>)>;
    // Libraries loaded only so the documented ones can be instantiated: a class
    // that `extends Modelica.Icons.Package` has no icon at all unless MSL is in
    // the same top scope. Kept for the whole run, since nearly everything uses
    // the same handful.
    let mut dependencies: HashMap<String, Absyn::Program> = HashMap::new();
    let mut store = options
        .icons
        .then(|| icons::Icons::new(&options.output_dir, &options.icons_dir))
        .transpose()
        .map_err(|e| e.to_string())?;
    // Parse every library first, so the SCode they are all instantiated against
    // can be translated once. Translating the shared dependencies again for
    // each library — nearly all of them use MSL — cost 35 GB over the 55.
    let mut programs: Vec<Absyn::Program> = Vec::new();
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
                load_library(name, version.as_deref(), &path)
                    .map(|program| (doc::collect(&program), program))
            })
            .collect::<Vec<_>>()
    };
    let loaded = match &loading {
        Ok(pool) => pool.install(load_all),
        Err(_) => load_all(),
    };
    drop(loading);

    for ((name, _), result) in options.libraries.iter().zip(loaded) {
        match result {
            Ok((mut loaded, program)) => {
                let offset = classes.len();
                for class in &mut loaded {
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
                programs.push(program);
            }
            Err(e) => eprintln!("omgendoc: {name}: {e}"),
        }
    }
    if classes.is_empty() {
        return Err("no library loaded".to_string());
    }
    if options.stats {
        report("all libraries parsed");
    }
    links::resolve_aliases(classes.iter().map(|c| c.qualified_name()));

    // The SCode universe, built once and shared by every rendering thread: one
    // translation of MSL for the whole run rather than one per library.
    let started = std::time::Instant::now();
    let scode = {
        let all = universe(&programs, &classes, &path, &mut dependencies, options.stats);
        if options.stats {
            report(&format!(
                "dependencies loaded in {:.1} s",
                started.elapsed().as_secs_f64()
            ));
        }
        let translating = std::time::Instant::now();
        let scode = icons::Scope::universe(&all);
        if options.stats {
            report(&format!(
                "SCode translated in {:.1} s",
                translating.elapsed().as_secs_f64()
            ));
        }
        scode
    };
    drop(programs);
    drop(dependencies);

    let mut resolver = links::Resolver::default();
    for class in &classes {
        resolver.add_class(&class.qualified_name(), &class.source_file);
    }
    let mut resolved: Vec<icons::Resolved> =
        (0..classes.len()).map(|_| icons::Resolved::default()).collect();
    icon_digests = render_graphics(
        &options,
        &classes,
        &libraries,
        scode.as_ref(),
        &resolver,
        store.as_mut(),
        &mut resolved,
    );
    drop(scode);
    if options.stats {
        report("graphics rendered");
    }

    link_names(&mut classes, resolved);

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

    let requested: HashMap<&str, &str> = options
        .libraries
        .iter()
        .filter_map(|(n, v)| v.as_deref().map(|v| (n.as_str(), v)))
        .collect();
    let sources = packages::Sources::read(&package_index(&options, &path));
    let entries: Vec<html::LibraryEntry<'_>> = libraries
        .iter()
        .map(|&i| {
            let name = classes[i].name();
            let version = requested
                .get(name)
                .copied()
                .unwrap_or(classes[i].version.as_str());
            html::LibraryEntry {
                doc: &classes[i],
                icon: class_graphics[i].icon.clone(),
                source: sources.url(name, version),
            }
        })
        .collect();
    std::fs::write(
        options.output_dir.join("index.html"),
        html::render_index(&entries, &footer),
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
            let name = classes[root].name();
            let mut quoted = String::new();
            index::escape(name, &mut quoted);
            let file = links::plain_stem(name);
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
