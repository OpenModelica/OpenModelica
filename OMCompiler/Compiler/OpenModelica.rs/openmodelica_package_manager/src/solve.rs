use std::cell::{Cell, RefCell};
use std::cmp::Ordering;
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::fmt::Display;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::rc::Rc;
use std::sync::Arc;

use resolvo::utils::{Pool, VersionSet};
use resolvo::{
    Candidates, Condition, ConditionId, ConditionalRequirement, Dependencies, DependencyProvider,
    HintDependenciesAvailable, Interner, KnownDependencies, NameId, SolvableId, Solver, SolverCache, StringId,
    UnsolvableOrCancelled, VersionSetId, VersionSetUnionId,
};

use crate::version::{Kind as VersionKind, Version, compare};
use crate::{Facts, Message, MessageKind, Problem, Selected, Solution};

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
enum Support {
    NoSupport,
    Unknown,
    Obsolete,
    Experimental,
    Support,
    FullSupport,
}

fn support(s: Option<&str>) -> Support {
    match s {
        Some("fullSupport") => Support::FullSupport,
        Some("support") => Support::Support,
        Some("experimental") => Support::Experimental,
        Some("obsolete") => Support::Obsolete,
        Some("noSupport") => Support::NoSupport,
        _ => Support::Unknown,
    }
}

struct Candidate {
    lib: usize,
    version: Version,
    uses: BTreeMap<String, Version>,
    provides: Vec<Version>,
    support: Support,
    installed: Option<usize>,
    available: bool,
}

struct Lib {
    name: String,
    any_version: bool,
    candidates: Vec<usize>,
    loaded: Option<usize>,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Kind {
    /// Versions that are or validly provide the requested one.
    Normal,
    /// Newer versions with the same major version, as no compatible version
    /// is available (only when loading).
    Semver,
    /// Development branches, as no compatible version is available.
    Fallback,
    /// Nothing knows the requested version: whatever else is chosen, else
    /// a branch if that can be added.
    Unknown,
    Missing,
}

struct Classified {
    kind: Kind,
    members: Vec<usize>,
}

/// A `uses` entry or a requested library.
#[derive(Clone)]
struct Edge {
    lib: Option<usize>,
    name: String,
    version: Version,
    exact: bool,
    /// Without an exact match, fail instead of taking a compatible version.
    strict: bool,
    origin: String,
}

impl Edge {
    fn relaxed(&self) -> Option<Edge> {
        (self.exact && !self.strict).then(|| Edge {
            exact: false,
            ..self.clone()
        })
    }
}

/// The claims (candidate, position in its `provides`) that hold.
type Claims = HashSet<(usize, usize)>;

thread_local! {
    /// The universe of the last facts, which callers often ask again.
    static UNIVERSE: RefCell<Option<(u64, Rc<Universe>)>> = const { RefCell::new(None) };
}

/// Identifies everything a universe is built from; None if the index has no
/// key, i.e. was not parsed from JSON text.
fn facts_key(problem: &Problem) -> Option<u64> {
    let index = match &problem.index {
        Some(index) if index.key == 0 => return None,
        Some(index) => index.key,
        None => 0,
    };
    let mut h = DefaultHasher::new();
    (index, &problem.installed, &problem.loaded, problem.install).hash(&mut h);
    Some(h.finish())
}

/// The universe for the facts of a problem, built again only if they changed.
fn universe(problem: &Problem) -> Rc<Universe> {
    let key = facts_key(problem);
    let cached = UNIVERSE.with_borrow(|c| c.as_ref().filter(|(k, _)| Some(*k) == key).map(|(_, u)| u.clone()));
    let u = cached.unwrap_or_else(|| {
        let u = Rc::new(Universe::new(problem));
        if let Some(key) = key {
            UNIVERSE.set(Some((key, u.clone())));
        }
        u
    });
    u.exact_uses.set(problem.exact_uses);
    u
}

struct Universe {
    libs: Vec<Lib>,
    by_name: HashMap<String, usize>,
    cands: Vec<Candidate>,
    install: bool,
    exact_uses: Cell<bool>,
    valid: Arc<Claims>,
    compatible: RefCell<HashMap<(usize, String), Rc<BTreeSet<usize>>>>,
}

impl Universe {
    fn new(problem: &Problem) -> Universe {
        let mut u = Universe {
            libs: Vec::new(),
            by_name: HashMap::new(),
            cands: Vec::new(),
            install: problem.install,
            exact_uses: Cell::new(problem.exact_uses),
            valid: Arc::default(),
            compatible: RefCell::default(),
        };
        if let Some(index) = &problem.index {
            for (name, lib) in &index.libs {
                let l = u.lib(name);
                u.libs[l].any_version = lib.any_version;
                for (version, facts) in &lib.versions {
                    u.add(l, version, facts.clone());
                }
            }
        }
        for (i, inst) in problem.installed.iter().enumerate() {
            let l = u.lib(&inst.name);
            let c = match u.find(l, &inst.version, true) {
                Some(c) if u.cands[c].installed.is_none() => c,
                Some(_) => continue,
                None => u.add(l, &inst.version, Facts::default()),
            };
            let cand = &mut u.cands[c];
            cand.installed = Some(i);
            if let Some(uses) = &inst.uses {
                cand.uses = uses.iter().map(|(k, v)| (k.clone(), Version::parse(v))).collect();
            }
            if let Some(provides) = &inst.provides {
                cand.provides = provides.iter().map(|p| Version::parse(p)).collect();
            }
            if inst.support.is_some() {
                cand.support = support(inst.support.as_deref());
            }
        }
        for cand in &mut u.cands {
            cand.available = cand.installed.is_some() || problem.install;
        }
        for loaded in &problem.loaded {
            let l = u.lib(&loaded.name);
            let c = u
                .find(l, &loaded.version, true)
                .or_else(|| u.find(l, &loaded.version, false))
                .unwrap_or_else(|| u.add(l, &loaded.version, Facts::default()));
            u.libs[l].loaded = Some(c);
        }
        u.valid = Arc::new(u.greatest_fixpoint());
        u
    }

    /// Starts from all claims and drops the ones that do not hold until
    /// nothing changes, as genindex in OMPackageManager does.
    fn greatest_fixpoint(&self) -> Claims {
        let mut valid: Claims = self
            .cands
            .iter()
            .enumerate()
            .filter(|(_, cand)| !cand.version.is_branch())
            .flat_map(|(c, cand)| (0..cand.provides.len()).map(move |i| (c, i)))
            .collect();
        loop {
            let broken: Vec<(usize, usize)> = valid
                .iter()
                .copied()
                .filter(|&(c, i)| !self.claim_holds(c, &self.cands[c].provides[i], &valid))
                .collect();
            if broken.is_empty() {
                return valid;
            }
            for claim in broken {
                valid.remove(&claim);
            }
        }
    }

    fn lib(&mut self, name: &str) -> usize {
        if let Some(&l) = self.by_name.get(name) {
            return l;
        }
        self.libs.push(Lib {
            name: name.to_owned(),
            any_version: false,
            candidates: Vec::new(),
            loaded: None,
        });
        self.by_name.insert(name.to_owned(), self.libs.len() - 1);
        self.libs.len() - 1
    }

    fn add(&mut self, lib: usize, version: &str, facts: Facts) -> usize {
        self.cands.push(Candidate {
            lib,
            version: Version::parse(version),
            uses: facts.uses.iter().map(|(k, v)| (k.clone(), Version::parse(v))).collect(),
            provides: facts.provides.iter().map(|p| Version::parse(p)).collect(),
            support: support(facts.support.as_deref()),
            installed: None,
            available: false,
        });
        let c = self.cands.len() - 1;
        self.libs[lib].candidates.push(c);
        c
    }

    fn find(&self, lib: usize, version: &str, exact_text: bool) -> Option<usize> {
        let v = Version::parse(version);
        self.libs[lib].candidates.iter().copied().find(|&c| {
            let cv = &self.cands[c].version;
            if exact_text { cv.text == v.text } else { cv.same(&v) }
        })
    }

    fn label(&self, c: usize) -> String {
        format!("{} {}", self.libs[self.cands[c].lib].name, self.cands[c].version)
    }

    /// Preference: support level, then releases before prereleases before
    /// branches, then the newest.
    fn prefer(&self, a: usize, b: usize) -> Ordering {
        let rank = |v: &Version| if v.is_branch() { 2 } else { v.is_prerelease() as u8 };
        let (a, b) = (&self.cands[a], &self.cands[b]);
        b.support
            .cmp(&a.support)
            .then_with(|| rank(&a.version).cmp(&rank(&b.version)))
            .then_with(|| compare(&b.version, &a.version, true))
    }

    fn compatible_with(&self, lib: usize, wanted: &Version, valid: &Claims) -> BTreeSet<usize> {
        self.libs[lib]
            .candidates
            .iter()
            .copied()
            .filter(|&c| {
                let cand = &self.cands[c];
                !cand.version.is_branch()
                    && (cand.version.matches(wanted, false)
                        || cand
                            .provides
                            .iter()
                            .enumerate()
                            .any(|(i, p)| p.matches(wanted, false) && valid.contains(&(c, i))))
            })
            .collect()
    }

    /// The versions of `lib` (not branches; available or not) that are
    /// `wanted` or validly provide it.
    fn compatible(&self, lib: usize, wanted: &Version) -> Rc<BTreeSet<usize>> {
        let key = (lib, wanted.text.clone());
        if let Some(set) = self.compatible.borrow().get(&key) {
            return set.clone();
        }
        let set = Rc::new(self.compatible_with(lib, wanted, &self.valid));
        self.compatible.borrow_mut().insert(key, set.clone());
        set
    }

    /// `c` provides `wanted` only if each library that both use is used at
    /// versions that one version of it is compatible with.
    fn claim_holds(&self, c: usize, wanted: &Version, valid: &Claims) -> bool {
        let new = &self.cands[c];
        self.libs[new.lib].candidates.iter().all(|&o| {
            let old = &self.cands[o];
            o == c
                || old.version.is_branch()
                || !old.version.matches(wanted, false)
                || old.uses.iter().all(|(dep, old_version)| {
                    let Some(new_version) = new.uses.get(dep) else {
                        return true;
                    };
                    if old_version.same(new_version) {
                        return true;
                    }
                    match self.by_name.get(dep) {
                        Some(&d) if self.libs[d].any_version => true,
                        Some(&d) => !self
                            .compatible_with(d, old_version, valid)
                            .is_disjoint(&self.compatible_with(d, new_version, valid)),
                        None => false,
                    }
                })
        })
    }

    /// Whether `c` claims to provide `wanted` but the claim does not hold.
    fn broken_claim(&self, c: usize, wanted: &Version) -> bool {
        self.cands[c]
            .provides
            .iter()
            .enumerate()
            .any(|(i, p)| p.matches(wanted, false) && !self.valid.contains(&(c, i)))
    }

    /// Newer available releases with the same major version, from the ones
    /// with the most leading version numbers in common.
    fn semver(&self, available: &[usize], wanted: &Version) -> Vec<usize> {
        let VersionKind::Numbered { nums: w, .. } = &wanted.kind else {
            return Vec::new();
        };
        let common = |c: usize| match &self.cands[c].version.kind {
            VersionKind::Numbered { nums, .. }
                if nums.first().unwrap_or(&0) == w.first().unwrap_or(&0)
                    && compare(&self.cands[c].version, wanted, false) == Ordering::Greater
                    && !self.broken_claim(c, wanted) =>
            {
                Some(
                    (0..nums.len().max(w.len()))
                        .take_while(|&i| nums.get(i).unwrap_or(&0) == w.get(i).unwrap_or(&0))
                        .count(),
                )
            }
            _ => None,
        };
        let best = available.iter().filter_map(|&c| common(c)).max();
        available
            .iter()
            .copied()
            .filter(|&c| best.is_some() && common(c) == best)
            .collect()
    }

    fn known(&self, lib: usize, wanted: &Version) -> bool {
        !self.compatible(lib, wanted).is_empty()
            || self.libs[lib]
                .candidates
                .iter()
                .any(|&c| self.cands[c].provides.iter().any(|p| p.matches(wanted, false)))
    }

    fn satisfies(&self, c: usize, e: &Edge) -> bool {
        let v = &self.cands[c].version;
        if e.exact || e.version.branch_request().is_some() {
            return v.matches(&e.version, e.exact);
        }
        v.matches(&e.version, false) || e.lib.is_some_and(|l| self.compatible(l, &e.version).contains(&c))
    }

    /// The available versions an edge may choose from, ignoring what is loaded.
    fn classify(&self, e: &Edge) -> Classified {
        let missing = Classified {
            kind: Kind::Missing,
            members: Vec::new(),
        };
        let Some(lib) = e.lib else { return missing };
        let mut available: Vec<usize> = self.libs[lib]
            .candidates
            .iter()
            .copied()
            .filter(|&c| self.cands[c].available)
            .collect();
        available.sort_by(|&a, &b| self.prefer(a, b));
        let normal: Vec<usize> = available.iter().copied().filter(|&c| self.satisfies(c, e)).collect();
        if !normal.is_empty() {
            return Classified {
                kind: Kind::Normal,
                members: normal,
            };
        }
        if let Some(relaxed) = e.relaxed() {
            return self.classify(&relaxed);
        }
        if available.is_empty() || e.exact || e.version.branch_request().is_some() {
            return missing;
        }
        if !self.install {
            let semver = self.semver(&available, &e.version);
            if !semver.is_empty() {
                return Classified {
                    kind: Kind::Semver,
                    members: semver,
                };
            }
        }
        let branches: Vec<usize> = available
            .iter()
            .copied()
            .filter(|&c| self.cands[c].version.is_branch())
            .collect();
        if self.known(lib, &e.version) {
            if branches.is_empty() {
                missing
            } else {
                Classified {
                    kind: Kind::Fallback,
                    members: branches,
                }
            }
        } else if branches.is_empty() {
            missing
        } else {
            Classified {
                kind: Kind::Unknown,
                members: branches,
            }
        }
    }

    fn branches(&self, lib: usize) -> Vec<usize> {
        let mut branches: Vec<usize> = self.libs[lib]
            .candidates
            .iter()
            .copied()
            .filter(|&c| self.cands[c].available && self.cands[c].version.is_branch())
            .collect();
        branches.sort_by(|&a, &b| self.prefer(a, b));
        branches
    }

    fn edges_of(&self, c: usize) -> Vec<Edge> {
        let own = &self.libs[self.cands[c].lib].name;
        self.cands[c]
            .uses
            .iter()
            .filter(|(name, _)| *name != own)
            .map(|(name, version)| Edge {
                lib: self.by_name.get(name).copied(),
                name: name.clone(),
                version: version.clone(),
                exact: self.exact_uses.get(),
                strict: false,
                origin: self.label(c),
            })
            .collect()
    }
}

#[derive(Clone, PartialEq, Eq, Hash)]
struct Members {
    set: Vec<usize>,
    label: String,
}

impl VersionSet for Members {
    type V = u32;
}

struct Provider<'u> {
    u: &'u Universe,
    pool: Pool<Members, String>,
    names: Vec<NameId>,
    lib_of_name: HashMap<NameId, usize>,
    solvables: HashMap<usize, SolvableId>,
}

impl<'u> Provider<'u> {
    fn new(u: &'u Universe) -> Self {
        let pool = Pool::new();
        let mut names = Vec::new();
        let mut lib_of_name = HashMap::new();
        let mut solvables = HashMap::new();
        for (l, lib) in u.libs.iter().enumerate() {
            let name = pool.intern_package_name(lib.name.clone());
            names.push(name);
            lib_of_name.insert(name, l);
            for &c in &lib.candidates {
                if u.cands[c].available || lib.loaded == Some(c) {
                    solvables.insert(c, pool.intern_solvable(name, c as u32));
                }
            }
        }
        Provider {
            u,
            pool,
            names,
            lib_of_name,
            solvables,
        }
    }

    fn cand(&self, s: SolvableId) -> usize {
        self.pool.resolve_solvable(s).record as usize
    }

    fn requirement(&self, e: &Edge) -> Option<VersionSetId> {
        let lib = e.lib?;
        let members = match self.u.libs[lib].loaded {
            Some(c) => vec![c],
            None => {
                let classified = self.u.classify(e);
                if classified.kind != Kind::Normal {
                    return None;
                }
                classified.members
            }
        };
        let label = if e.version.text.is_empty() {
            "any version".to_owned()
        } else {
            e.version.text.clone()
        };
        Some(
            self.pool
                .intern_version_set(self.names[lib], Members { set: members, label }),
        )
    }
}

impl Interner for Provider<'_> {
    type NameId = NameId;
    type SolvableId = SolvableId;

    fn display_solvable(&self, solvable: SolvableId) -> impl Display + '_ {
        self.u.label(self.cand(solvable))
    }

    fn display_merged_solvables(&self, solvables: &[SolvableId]) -> impl Display + '_ {
        let Some(&first) = solvables.first() else {
            return String::new();
        };
        let versions: Vec<String> = solvables
            .iter()
            .map(|&s| self.u.cands[self.cand(s)].version.text.clone())
            .collect();
        format!(
            "{} {}",
            self.u.libs[self.u.cands[self.cand(first)].lib].name,
            versions.join(" | ")
        )
    }

    fn display_name(&self, name: NameId) -> impl Display + '_ {
        self.pool.resolve_package_name(name).clone()
    }

    fn display_version_set(&self, version_set: VersionSetId) -> impl Display + '_ {
        self.pool.resolve_version_set(version_set).label.clone()
    }

    fn display_string(&self, string_id: StringId) -> impl Display + '_ {
        self.pool.resolve_string(string_id).to_owned()
    }

    fn version_set_name(&self, version_set: VersionSetId) -> NameId {
        self.pool.resolve_version_set_package_name(version_set)
    }

    fn solvable_name(&self, solvable: SolvableId) -> NameId {
        self.pool.resolve_solvable(solvable).name
    }

    fn version_sets_in_union(&self, version_set_union: VersionSetUnionId) -> impl Iterator<Item = VersionSetId> {
        self.pool.resolve_version_set_union(version_set_union)
    }

    fn resolve_condition(&self, condition: ConditionId) -> Condition {
        self.pool.resolve_condition(condition).clone()
    }
}

impl DependencyProvider for Provider<'_> {
    async fn filter_candidates(
        &self,
        candidates: &[SolvableId],
        version_set: VersionSetId,
        inverse: bool,
    ) -> Vec<SolvableId> {
        let set = &self.pool.resolve_version_set(version_set).set;
        candidates
            .iter()
            .copied()
            .filter(|&s| set.contains(&self.cand(s)) != inverse)
            .collect()
    }

    async fn get_candidates(&self, name: NameId) -> Option<Candidates> {
        let lib = &self.u.libs[*self.lib_of_name.get(&name)?];
        let locked = lib.loaded.map(|c| self.solvables[&c]);
        let candidates = match locked {
            Some(s) => vec![s],
            None => lib
                .candidates
                .iter()
                .filter_map(|c| self.solvables.get(c).copied())
                .collect(),
        };
        Some(Candidates {
            candidates,
            locked,
            hint_dependencies_available: HintDependenciesAvailable::All,
            ..Candidates::default()
        })
    }

    async fn sort_candidates(&self, _solver: &SolverCache<Self>, solvables: &mut [SolvableId]) {
        solvables.sort_by(|&a, &b| self.u.prefer(self.cand(a), self.cand(b)));
    }

    async fn get_dependencies(&self, solvable: SolvableId) -> Dependencies {
        let c = self.cand(solvable);
        if self.u.libs[self.u.cands[c].lib].loaded == Some(c) {
            return Dependencies::Known(KnownDependencies::default());
        }
        let requirements = self
            .u
            .edges_of(c)
            .iter()
            .filter_map(|e| self.requirement(e))
            .map(ConditionalRequirement::from)
            .collect();
        Dependencies::Known(KnownDependencies {
            requirements,
            constrains: Vec::new(),
        })
    }
}

fn run(u: &Universe, roots: &[Edge], soft: &[usize]) -> Result<Vec<usize>, String> {
    let provider = Provider::new(u);
    let requirements = roots
        .iter()
        .filter_map(|e| provider.requirement(e))
        .map(ConditionalRequirement::from)
        .collect();
    let soft: Vec<SolvableId> = soft.iter().map(|c| provider.solvables[c]).collect();
    let mut solver = Solver::new(provider);
    match solver.solve(
        resolvo::Problem::new()
            .requirements(requirements)
            .soft_requirements(soft),
    ) {
        Ok(solvables) => Ok(solvables.into_iter().map(|s| solver.provider().cand(s)).collect()),
        Err(UnsolvableOrCancelled::Unsolvable(conflict)) => Err(conflict.display_user_friendly(&solver).to_string()),
        Err(UnsolvableOrCancelled::Cancelled(_)) => Err("Package resolution was cancelled.".to_owned()),
    }
}

/// The edges of the roots and of the chosen versions that were not loaded.
fn edges(u: &Universe, roots: Vec<Edge>, chosen: &[usize]) -> Vec<Edge> {
    let mut all = roots;
    for &c in chosen {
        if u.libs[u.cands[c].lib].loaded != Some(c) {
            all.extend(u.edges_of(c));
        }
    }
    all
}

/// The versions to try in order for an edge that nothing compatible can
/// satisfy: guesses, added only if they fit.
fn guesses(u: &Universe, e: &Edge) -> Vec<usize> {
    let classified = u.classify(e);
    match classified.kind {
        Kind::Normal | Kind::Missing => Vec::new(),
        Kind::Fallback | Kind::Unknown => classified.members,
        Kind::Semver => {
            let mut members = classified.members;
            members.extend(u.branches(e.lib.expect("a classified library")));
            members
        }
    }
}

fn messages(u: &Universe, all: &[Edge], chosen: &[usize]) -> Vec<Message> {
    let selected: BTreeMap<usize, usize> = chosen.iter().map(|&c| (u.cands[c].lib, c)).collect();
    let mut out = BTreeSet::new();
    for e in all {
        let sel = e.lib.and_then(|l| selected.get(&l).copied().or(u.libs[l].loaded));
        let kind = match sel {
            None => Some(MessageKind::Missing),
            Some(c)
                if u.satisfies(c, e)
                    || e.relaxed().is_some_and(|r| u.satisfies(c, &r))
                    || u.libs[u.cands[c].lib].any_version =>
            {
                None
            }
            Some(c) if u.cands[c].version.is_branch() && u.classify(e).kind == Kind::Fallback => {
                Some(MessageKind::BranchFallback)
            }
            Some(_) if e.lib.is_some_and(|l| u.known(l, &e.version)) || e.exact => Some(MessageKind::Incompatible),
            Some(_) => Some(MessageKind::UnknownVersion),
        };
        if let Some(kind) = kind {
            out.insert(Message {
                kind,
                name: e.name.clone(),
                version: e.version.text.clone(),
                selected: sel.map(|c| u.cands[c].version.text.clone()),
                origin: e.origin.clone(),
            });
        }
    }
    out.into_iter().collect()
}

/// The available versions an edge can use, best first; development branches
/// last, as fallbacks.
fn versions(u: &Universe, e: &Edge) -> Vec<String> {
    let classified = u.classify(e);
    let mut members = classified.members;
    if matches!(classified.kind, Kind::Normal | Kind::Semver)
        && let Some(lib) = e.lib
    {
        let branches: Vec<usize> = u.branches(lib).into_iter().filter(|c| !members.contains(c)).collect();
        members.extend(branches);
    }
    members.into_iter().map(|c| u.cands[c].version.text.clone()).collect()
}

/// The first alternative that an available version satisfies, else the
/// first one that can use something, else the first.
fn root(u: &Universe, r: &crate::Requirement) -> Edge {
    let edge = |version: &str| Edge {
        lib: u.by_name.get(&r.name).copied(),
        name: r.name.clone(),
        version: Version::parse(version),
        exact: r.exact,
        strict: true,
        origin: r.origin.clone(),
    };
    let alternatives: Vec<Edge> = if r.versions.is_empty() {
        vec![edge(&r.version)]
    } else {
        r.versions.iter().map(|v| edge(v)).collect()
    };
    let kinds: Vec<Kind> = alternatives.iter().map(|e| u.classify(e).kind).collect();
    let pick = kinds
        .iter()
        .position(|&k| matches!(k, Kind::Normal | Kind::Semver))
        .or_else(|| kinds.iter().position(|&k| k != Kind::Missing))
        .unwrap_or(0);
    alternatives.into_iter().nth(pick).expect("one alternative")
}

/// The chosen versions and the edges between them. For each library that
/// only guesses can satisfy, the guesses are tried in order as soft
/// requirements, which the solver leaves out if they do not fit.
fn solve(u: &Universe, roots: &[Edge]) -> Result<(Vec<usize>, Vec<Edge>), String> {
    let mut soft = Vec::new();
    let mut tried = HashSet::new();
    loop {
        let chosen = run(u, roots, &soft)?;
        let all = edges(u, roots.to_vec(), &chosen);
        let selected: HashSet<usize> = chosen.iter().map(|&c| u.cands[c].lib).collect();
        let mut more = Vec::new();
        for e in all.iter().filter(|e| e.lib.is_some_and(|l| !selected.contains(&l))) {
            if let Some(next) = guesses(u, e).into_iter().find(|c| !tried.contains(c)) {
                tried.insert(next);
                more.push(next);
            }
        }
        if more.is_empty() {
            return Ok((chosen, all));
        }
        soft.extend(more);
    }
}

pub fn resolve(problem: &Problem) -> Solution {
    let u = universe(problem);
    let roots = || problem.requirements.iter().map(|r| root(&u, r)).collect::<Vec<_>>();
    if problem.versions {
        return Solution {
            ok: true,
            versions: roots().first().map_or_else(Vec::new, |e| versions(&u, e)),
            ..Default::default()
        };
    }
    let solved = solve(&u, &roots()).or_else(|error| {
        if !u.exact_uses.get() {
            return Err(error);
        }
        u.exact_uses.set(false);
        solve(&u, &roots())
    });
    let (chosen, all) = match solved {
        Ok(solved) => solved,
        Err(error) => {
            let error = if problem.install {
                error
            } else {
                error.replace("be installed", "be loaded")
            };
            return Solution {
                error: Some(error),
                ..Default::default()
            };
        }
    };
    let mut selected: Vec<Selected> = chosen
        .iter()
        .map(|&c| {
            let cand = &u.cands[c];
            let lib = &u.libs[cand.lib];
            let inst = cand.installed.map(|i| &problem.installed[i]);
            Selected {
                name: lib.name.clone(),
                version: cand.version.text.clone(),
                path: inst.and_then(|i| i.path.clone()),
                installed: inst.is_some(),
                modelica_path_index: inst.and_then(|i| i.modelica_path_index),
                file: inst.and_then(|i| i.file.clone()),
                loaded: lib.loaded == Some(c),
                origin: all
                    .iter()
                    .find(|e| e.lib == Some(cand.lib))
                    .map_or_else(String::new, |e| e.origin.clone()),
            }
        })
        .collect();
    selected.sort_by(|a, b| a.name.cmp(&b.name));
    Solution {
        ok: true,
        error: None,
        selected,
        messages: messages(&u, &all, &chosen),
        ..Default::default()
    }
}
