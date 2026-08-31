//! C's `ParModelica/auto` runtime (`--parmodauto`): the ODE task graph, its
//! clustering passes, the two schedulers and the JSON export/import, ported from
//! `SimulationRuntime/ParModelica/auto/pm_*.hpp`. The graph, costs, clusters and
//! files are the C ones; the clusters are evaluated in dependency order on the
//! runtime's single thread, where C hands them to a TBB thread pool.

use alloc::collections::BTreeSet;
use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec;
use alloc::vec::Vec;
use core::cell::UnsafeCell;
use core::sync::atomic::{AtomicUsize, Ordering};

use openmodelica_solvers::log_line;

use crate::driver::{Result, leak_error, now_ms_host};
use crate::omclog;
use crate::{ParmodInfo, SimMeta};

/// `PM_Model_create`'s cap on the default thread count.
const DEFAULT_THREAD_CAP: usize = 6;

static HW_THREADS: AtomicUsize = AtomicUsize::new(0);

/// The machine's hardware concurrency, the default `-parmodNumThreads` is capped
/// from; unknown (0) counts as plenty.
pub fn set_hw_threads(n: usize) {
    HW_THREADS.store(n, Ordering::Relaxed);
}

fn stdout(s: &str) {
    log_line(omclog::STDOUT, omclog::INFO, s);
}

/// `std::cout << double`: `%g` at the stream's default six digits.
fn g(v: f64) -> String {
    omclog::g(v, 0, 6)
}

struct Config {
    scheduler: String,
    clustering: String,
    clusters_per_level: i32,
    export_taskgraph: Option<String>,
    import_clustering: Option<String>,
    dump_stages: Option<String>,
    num_threads: usize,
}

impl Config {
    fn from_flags() -> Config {
        crate::simflags::with_flags(|f| {
            let hw = HW_THREADS.load(Ordering::Relaxed);
            let default_threads = if hw == 0 { DEFAULT_THREAD_CAP } else { hw.min(DEFAULT_THREAD_CAP) };
            Config {
                scheduler: f.parmod_scheduler.clone().unwrap_or_else(|| "flow".to_string()),
                clustering: f.parmod_clustering.clone().unwrap_or_else(|| "default".to_string()),
                clusters_per_level: f.parmod_clusters_per_level.unwrap_or(0),
                export_taskgraph: f.parmod_export_taskgraph.clone(),
                import_clustering: f.parmod_import_clustering.clone(),
                dump_stages: f.parmod_dump_stages.clone(),
                num_threads: match f.parmod_num_threads {
                    Some(n) if n > 0 => n as usize,
                    _ => default_threads,
                },
            }
        })
    }
}

// ───────────────────────────── task system ─────────────────────────────

#[derive(Clone)]
struct Task {
    task_id: u32,
    index: i32,
    cost: f64,
}

#[derive(Clone)]
struct Cluster {
    tasks: Vec<Task>,
    cost: f64,
    level: i64,
    lane: i32,
}

impl Cluster {
    fn add_task(&mut self, t: Task) {
        self.cost += t.cost;
        self.tasks.push(t);
    }
    fn index_list(&self) -> String {
        let mut s = String::from("$");
        for t in &self.tasks {
            s.push_str(&format!(",{}", t.index));
        }
        s
    }
}

const ROOT: usize = 0;

/// `TaskSystem_v2`: clusters as vertices of a DAG whose root is the parentless
/// tasks' common predecessor. Vertex ids are stable (a removed vertex leaves a
/// hole), so a vertex walk is C's insertion-ordered `listS` walk.
#[derive(Clone)]
struct TaskSystem {
    name: String,
    max_num_threads: usize,
    nodes: Vec<Option<Cluster>>,
    parents: Vec<BTreeSet<usize>>,
    children: Vec<BTreeSet<usize>>,
    /// `clusters_by_level`, level 0 holding only the root.
    levels: Vec<Vec<usize>>,
    level_cost: Vec<f64>,
    levels_valid: bool,
}

impl TaskSystem {
    fn new(name: &str, max_num_threads: usize, info: &ParmodInfo) -> TaskSystem {
        let root = Cluster { tasks: vec![Task { task_id: u32::MAX, index: -1, cost: 0.0 }], cost: 0.0, level: 0, lane: -1 };
        let mut s = TaskSystem {
            name: name.to_string(),
            max_num_threads,
            nodes: vec![Some(root)],
            parents: vec![BTreeSet::new()],
            children: vec![BTreeSet::new()],
            levels: Vec::new(),
            level_cost: Vec::new(),
            levels_valid: false,
        };
        for (k, t) in info.tasks.iter().enumerate() {
            let v = s.nodes.len();
            s.nodes.push(Some(Cluster {
                tasks: vec![Task { task_id: k as u32, index: t.eq_index, cost: 0.0 }],
                cost: 0.0,
                level: 0,
                lane: -1,
            }));
            s.parents.push(BTreeSet::new());
            s.children.push(BTreeSet::new());
            if t.parents.is_empty() {
                s.add_edge(ROOT, v);
            }
            for p in &t.parents {
                s.add_edge(*p as usize + 1, v);
            }
        }
        s
    }

    fn cluster(&self, v: usize) -> &Cluster {
        self.nodes[v].as_ref().expect("live cluster")
    }
    fn cluster_mut(&mut self, v: usize) -> &mut Cluster {
        self.nodes[v].as_mut().expect("live cluster")
    }
    fn vertices(&self) -> impl Iterator<Item = usize> + '_ {
        (1..self.nodes.len()).filter(|&v| self.nodes[v].is_some())
    }
    fn add_edge(&mut self, a: usize, b: usize) {
        self.children[a].insert(b);
        self.parents[b].insert(a);
    }
    fn out_degree(&self, v: usize) -> usize {
        self.children[v].len()
    }
    fn in_degree(&self, v: usize) -> usize {
        self.parents[v].len()
    }

    /// `concat_clusters` / `concat_same_level_clusters` / `concat_with_parent`:
    /// `src`'s tasks and edges move to `dest`, then `src` goes.
    fn concat(&mut self, dest: usize, src: usize) {
        if dest == src {
            return;
        }
        let tasks = core::mem::take(&mut self.cluster_mut(src).tasks);
        for t in tasks {
            self.cluster_mut(dest).add_task(t);
        }
        for c in core::mem::take(&mut self.children[src]) {
            self.parents[c].remove(&src);
            if c != dest {
                self.add_edge(dest, c);
            }
        }
        for p in core::mem::take(&mut self.parents[src]) {
            self.children[p].remove(&src);
            if p != dest {
                self.add_edge(p, dest);
            }
        }
        self.nodes[src] = None;
        self.levels_valid = false;
    }

    /// `update_node_levels`: longest path from the root, then the per-level lists.
    fn update_node_levels(&mut self) {
        let mut critical = 0i64;
        for v in self.topological_order() {
            let lvl = self.parents[v].iter().map(|&p| self.cluster(p).level).max().map_or(0, |m| m + 1);
            self.cluster_mut(v).level = lvl;
            critical = critical.max(lvl);
        }
        self.levels = vec![Vec::new(); critical as usize + 1];
        self.level_cost = vec![0.0; critical as usize + 1];
        self.levels[0].push(ROOT);
        let vs: Vec<usize> = self.vertices().collect();
        for v in vs {
            let (level, cost) = (self.cluster(v).level as usize, self.cluster(v).cost);
            self.levels[level].push(v);
            self.level_cost[level] += cost;
        }
        self.levels_valid = true;
    }

    /// Kahn's order over the live vertices, lowest id first among the ready ones.
    fn topological_order(&self) -> Vec<usize> {
        let mut indeg: Vec<usize> = (0..self.nodes.len()).map(|v| self.parents[v].len()).collect();
        let mut ready: BTreeSet<usize> =
            (0..self.nodes.len()).filter(|&v| self.nodes[v].is_some() && indeg[v] == 0).collect();
        let mut out = Vec::with_capacity(self.nodes.len());
        while let Some(&v) = ready.iter().next() {
            ready.remove(&v);
            out.push(v);
            for &c in &self.children[v] {
                indeg[c] -= 1;
                if indeg[c] == 0 {
                    ready.insert(c);
                }
            }
        }
        out
    }

    fn ensure_levels(&mut self) {
        if !self.levels_valid {
            self.update_node_levels();
        }
    }

    /// `cluster_cost_comparator_by_id`: by cost, then by out-degree.
    fn cost_key(&self, v: usize) -> (f64, usize) {
        (self.cluster(v).cost, self.out_degree(v))
    }
    fn less(&self, a: usize, b: usize) -> bool {
        let (ca, da) = self.cost_key(a);
        let (cb, db) = self.cost_key(b);
        if ca == cb { da < db } else { ca < cb }
    }
    /// `std::sort(rbegin, rend, cccbi)`: decreasing cost.
    fn sort_decreasing(&self, ids: &mut [usize]) {
        ids.sort_by(|&a, &b| {
            let (ca, da) = self.cost_key(a);
            let (cb, db) = self.cost_key(b);
            cb.partial_cmp(&ca).unwrap_or(core::cmp::Ordering::Equal).then(db.cmp(&da))
        });
    }
    fn min_element(&self, ids: &[usize]) -> usize {
        let mut best = ids[0];
        for &v in &ids[1..] {
            if self.less(v, best) {
                best = v;
            }
        }
        best
    }

    /// `TaskCluster::profile_execute`: time every task, the cluster's cost is their sum.
    fn profile_execute(&mut self, v: usize, call: Call) -> Result<()> {
        let n = self.cluster(v).tasks.len();
        let mut total = 0.0;
        for i in 0..n {
            let id = self.cluster(v).tasks[i].task_id;
            let t0 = now_ms_host();
            call(Op::Task(id))?;
            let elapsed = now_ms_host() - t0;
            self.cluster_mut(v).tasks[i].cost = elapsed;
            total += elapsed;
        }
        self.cluster_mut(v).cost = total;
        Ok(())
    }

    /// One evaluation of every task. Task order is a valid schedule on its own
    /// (every edge points forward), and with one thread nothing is gained from the
    /// clustered order, so this is the sequential entry point in one call.
    fn execute_all(&self, call: Call) -> Result<()> {
        call(Op::All)
    }

    fn profile_all(&mut self, call: Call) -> Result<()> {
        call(Op::LocalKnown)?;
        let vs: Vec<usize> = self.vertices().collect();
        for v in vs {
            self.profile_execute(v, call)?;
        }
        Ok(())
    }
}

// ───────────────────────────── clustering ─────────────────────────────

const CLUSTER_MERGE_COMMON: &str = "cluster_merge_common";
const CLUSTER_MERGE_LEVEL_FOR_BINS: &str = "cluster_merge_level_for_bins";
const CLUSTER_FIXED_WIDTH_MIN_HEIGHT: &str = "cluster_fixed_width_min_height";

/// `cluster_merge_common::concat_children_recursive`.
fn merge_common_recursive(s: &mut TaskSystem, curr: usize) -> usize {
    let target_cost = 20.0;
    let mut child_ids: Vec<usize> = s.children[curr].iter().copied().filter(|&c| s.in_degree(c) == 1).collect();
    s.sort_decreasing(&mut child_ids);
    let mut i = 0;
    while i < child_ids.len() {
        let child = child_ids[i];
        let mut gap = target_cost - s.cluster(child).cost;
        if gap >= 0.005 {
            let mut j = i + 1;
            while j < child_ids.len() {
                let other = child_ids[j];
                if s.cluster(other).cost <= gap {
                    gap -= s.cluster(other).cost;
                    s.concat(child, other);
                    child_ids.remove(j);
                } else {
                    j += 1;
                }
            }
        }
        i += 1;
    }
    let children: Vec<usize> = s.children[curr].iter().copied().collect();
    for child in children {
        if s.nodes[child].is_none() || !s.children[curr].contains(&child) {
            continue;
        }
        let nr_of_parents = merge_common_recursive(s, child);
        if nr_of_parents == 1 && s.cluster(curr).cost + s.cluster(child).cost < target_cost {
            s.concat(curr, child);
        }
    }
    s.in_degree(curr)
}

fn cluster_merge_common(s: &mut TaskSystem) {
    let top: Vec<usize> = s.children[ROOT].iter().copied().collect();
    for c in top {
        if s.nodes[c].is_some() {
            merge_common_recursive(s, c);
        }
    }
    s.levels_valid = false;
}

fn cluster_merge_level_for_bins(s: &mut TaskSystem, cfg: &Config) {
    let mut cluster_cap = 8usize;
    if cfg.clusters_per_level > 0 {
        cluster_cap = cfg.clusters_per_level as usize;
    }
    let nr_of_clusters = (s.max_num_threads * 2).min(cluster_cap).max(1);
    s.ensure_levels();
    for l in 1..s.levels.len() {
        if s.levels[l].len() <= nr_of_clusters {
            continue;
        }
        let mut level = core::mem::take(&mut s.levels[l]);
        s.sort_decreasing(&mut level);
        let (accepted, rest) = level.split_at(nr_of_clusters);
        let accepted = accepted.to_vec();
        for &v in rest {
            let smallest = s.min_element(&accepted);
            s.concat(smallest, v);
        }
        s.levels[l] = accepted;
    }
    s.levels_valid = false;
}

fn cluster_fixed_width_min_height(s: &mut TaskSystem) {
    s.ensure_levels();
    let vid: Vec<usize> = s.vertices().collect();
    let n = vid.len();
    if n == 0 {
        s.levels_valid = false;
        return;
    }
    let mut id_to_idx = vec![usize::MAX; s.nodes.len()];
    for (i, &v) in vid.iter().enumerate() {
        id_to_idx[v] = i;
    }
    let level: Vec<i64> = vid.iter().map(|&v| s.cluster(v).level).collect();
    let cost: Vec<f64> = vid.iter().map(|&v| s.out_degree(v) as f64).collect();
    let children: Vec<Vec<usize>> = vid
        .iter()
        .map(|&v| s.children[v].iter().filter_map(|&c| (id_to_idx[c] != usize::MAX).then_some(id_to_idx[c])).collect())
        .collect();
    let max_level = level.iter().copied().max().unwrap_or(0) as usize;
    let mut nodes_by_level: Vec<Vec<usize>> = vec![Vec::new(); max_level + 1];
    for i in 0..n {
        nodes_by_level[level[i] as usize].push(i);
    }
    for i in 0..n {
        for &c in &children[i] {
            if level[c] <= level[i] {
                stdout(&format!(
                    "cluster_fixed_width_min_height: non-forward edge {} -> {} would create a cycle; skipping clustering.\n",
                    level[i], level[c]
                ));
                s.levels_valid = false;
                return;
            }
        }
    }
    let k = s.max_num_threads.max(1);
    let by_cost_desc = |ids: &mut Vec<usize>| ids.sort_by(|&a, &b| cost[b].partial_cmp(&cost[a]).unwrap_or(core::cmp::Ordering::Equal));
    let mut lane = vec![0usize; n];
    for l in 1..=max_level {
        let level_nodes = &mut nodes_by_level[l];
        if level_nodes.is_empty() {
            continue;
        }
        let width = level_nodes.len().min(k);
        by_cost_desc(level_nodes);
        let mut lane_load = vec![0.0; width];
        for &nn in level_nodes.iter() {
            let mut best = 0;
            for l2 in 1..width {
                if lane_load[l2] < lane_load[best] {
                    best = l2;
                }
            }
            lane[nn] = best;
            lane_load[best] += cost[nn];
        }
    }
    let lanes = k;
    let cid_of = |i: usize, lane: &[usize]| level[i] as usize * lanes + lane[i];
    let analyze = |lane: &[usize]| -> (f64, i64, i64) {
        use alloc::collections::BTreeMap;
        let mut ccost: BTreeMap<usize, f64> = BTreeMap::new();
        for i in 0..n {
            *ccost.entry(cid_of(i, lane)).or_insert(0.0) += cost[i];
        }
        let mut preds: BTreeMap<usize, BTreeSet<usize>> = BTreeMap::new();
        for i in 0..n {
            let ci = cid_of(i, lane);
            for &c in &children[i] {
                let cj = cid_of(c, lane);
                if ci != cj {
                    preds.entry(cj).or_default().insert(ci);
                }
            }
        }
        let mut dp: BTreeMap<usize, f64> = BTreeMap::new();
        let mut par: BTreeMap<usize, Option<usize>> = BTreeMap::new();
        let mut height = 0.0;
        let mut end_c = None;
        for (&c, &cc) in &ccost {
            let mut best_pred = 0.0;
            let mut best_pc = None;
            if let Some(ps) = preds.get(&c) {
                for &p in ps {
                    let d = dp.get(&p).copied().unwrap_or(0.0);
                    if d > best_pred {
                        best_pred = d;
                        best_pc = Some(p);
                    }
                }
            }
            dp.insert(c, best_pred + cc);
            par.insert(c, best_pc);
            if dp[&c] > height {
                height = dp[&c];
                end_c = Some(c);
            }
        }
        let (mut hot_level, mut hot_lane, mut hot_cost) = (-1i64, -1i64, -1.0);
        let mut c = end_c;
        while let Some(cc) = c {
            if ccost[&cc] > hot_cost {
                hot_cost = ccost[&cc];
                hot_level = (cc / lanes) as i64;
                hot_lane = (cc % lanes) as i64;
            }
            c = par.get(&cc).copied().flatten();
        }
        (height, hot_level, hot_lane)
    };
    let max_evals = 20000;
    let mut evals = 0;
    while evals < max_evals {
        let (height, hot_level, hot_lane) = analyze(&lane);
        evals += 1;
        if hot_level < 1 {
            break;
        }
        let level_nodes = &nodes_by_level[hot_level as usize];
        let width = level_nodes.len().min(k);
        if width <= 1 {
            break;
        }
        let mut lane_load = vec![0.0; width];
        for &t in level_nodes {
            lane_load[lane[t]] += cost[t];
        }
        let mut target: Option<usize> = None;
        for l in 0..width {
            if l as i64 != hot_lane && target.is_none_or(|t| lane_load[l] < lane_load[t]) {
                target = Some(l);
            }
        }
        let Some(target) = target else { break };
        let mut hot_nodes: Vec<usize> = level_nodes.iter().copied().filter(|&t| lane[t] as i64 == hot_lane).collect();
        by_cost_desc(&mut hot_nodes);
        let mut improved = false;
        for &nn in &hot_nodes {
            if evals >= max_evals {
                break;
            }
            let old = lane[nn];
            lane[nn] = target;
            let (new_height, _, _) = analyze(&lane);
            evals += 1;
            if new_height < height {
                improved = true;
                break;
            }
            lane[nn] = old;
        }
        if !improved {
            break;
        }
    }
    for l in 1..=max_level {
        let level_nodes = nodes_by_level[l].clone();
        let width = level_nodes.len().min(k);
        for target_lane in 0..width {
            let mut rep: Option<usize> = None;
            for &nn in &level_nodes {
                if lane[nn] != target_lane {
                    continue;
                }
                match rep {
                    None => rep = Some(vid[nn]),
                    Some(r) => s.concat(r, vid[nn]),
                }
            }
            if let Some(r) = rep {
                s.cluster_mut(r).lane = target_lane as i32;
            }
        }
    }
    s.levels_valid = false;
}

// ───────────────────────────── JSON ─────────────────────────────

enum Json {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    Str(String),
    Arr(Vec<Json>),
    /// Keys kept sorted, as nlohmann's `std::map` object prints them.
    Obj(Vec<(String, Json)>),
}

impl Json {
    fn obj() -> Json {
        Json::Obj(Vec::new())
    }
    fn set(&mut self, key: &str, v: Json) {
        if let Json::Obj(m) = self {
            match m.binary_search_by(|(k, _)| k.as_str().cmp(key)) {
                Ok(i) => m[i].1 = v,
                Err(i) => m.insert(i, (key.to_string(), v)),
            }
        }
    }
    fn get(&self, key: &str) -> Option<&Json> {
        match self {
            Json::Obj(m) => m.iter().find(|(k, _)| k == key).map(|(_, v)| v),
            _ => None,
        }
    }
    fn as_array(&self) -> Option<&[Json]> {
        match self {
            Json::Arr(a) => Some(a),
            _ => None,
        }
    }
    fn as_i64(&self) -> Option<i64> {
        match self {
            Json::Int(i) => Some(*i),
            Json::Float(f) if libm::trunc(*f) == *f => Some(*f as i64),
            _ => None,
        }
    }

    /// `dump(2)`.
    fn dump(&self) -> String {
        let mut out = String::new();
        self.write(&mut out, 0);
        out
    }
    fn write(&self, out: &mut String, depth: usize) {
        let pad = |out: &mut String, d: usize| {
            for _ in 0..d * 2 {
                out.push(' ');
            }
        };
        match self {
            Json::Null => out.push_str("null"),
            Json::Bool(b) => out.push_str(if *b { "true" } else { "false" }),
            Json::Int(i) => out.push_str(&i.to_string()),
            Json::Float(f) => out.push_str(&format!("{f:?}")),
            Json::Str(s) => {
                out.push('"');
                for c in s.chars() {
                    match c {
                        '"' => out.push_str("\\\""),
                        '\\' => out.push_str("\\\\"),
                        '\n' => out.push_str("\\n"),
                        '\t' => out.push_str("\\t"),
                        c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
                        c => out.push(c),
                    }
                }
                out.push('"');
            }
            Json::Arr(a) => {
                if a.is_empty() {
                    out.push_str("[]");
                    return;
                }
                out.push_str("[\n");
                for (i, v) in a.iter().enumerate() {
                    pad(out, depth + 1);
                    v.write(out, depth + 1);
                    out.push_str(if i + 1 < a.len() { ",\n" } else { "\n" });
                }
                pad(out, depth);
                out.push(']');
            }
            Json::Obj(m) => {
                if m.is_empty() {
                    out.push_str("{}");
                    return;
                }
                out.push_str("{\n");
                for (i, (k, v)) in m.iter().enumerate() {
                    pad(out, depth + 1);
                    Json::Str(k.clone()).write(out, depth + 1);
                    out.push_str(": ");
                    v.write(out, depth + 1);
                    out.push_str(if i + 1 < m.len() { ",\n" } else { "\n" });
                }
                pad(out, depth);
                out.push('}');
            }
        }
    }

    fn parse(text: &str) -> core::result::Result<Json, String> {
        let b = text.as_bytes();
        let mut p = 0;
        let v = parse_value(b, &mut p)?;
        skip_ws(b, &mut p);
        if p != b.len() {
            return Err(format!("trailing characters at offset {p}"));
        }
        Ok(v)
    }
}

fn skip_ws(b: &[u8], p: &mut usize) {
    while *p < b.len() && matches!(b[*p], b' ' | b'\t' | b'\n' | b'\r') {
        *p += 1;
    }
}

fn parse_value(b: &[u8], p: &mut usize) -> core::result::Result<Json, String> {
    skip_ws(b, p);
    let Some(&c) = b.get(*p) else { return Err("unexpected end of input".to_string()) };
    match c {
        b'{' => {
            *p += 1;
            let mut m = Json::obj();
            skip_ws(b, p);
            if b.get(*p) == Some(&b'}') {
                *p += 1;
                return Ok(m);
            }
            loop {
                skip_ws(b, p);
                let Json::Str(k) = parse_value(b, p)? else { return Err(format!("object key expected at offset {p}")) };
                skip_ws(b, p);
                if b.get(*p) != Some(&b':') {
                    return Err(format!("':' expected at offset {p}"));
                }
                *p += 1;
                let v = parse_value(b, p)?;
                m.set(&k, v);
                skip_ws(b, p);
                match b.get(*p) {
                    Some(b',') => *p += 1,
                    Some(b'}') => {
                        *p += 1;
                        return Ok(m);
                    }
                    _ => return Err(format!("',' or '}}' expected at offset {p}")),
                }
            }
        }
        b'[' => {
            *p += 1;
            let mut a = Vec::new();
            skip_ws(b, p);
            if b.get(*p) == Some(&b']') {
                *p += 1;
                return Ok(Json::Arr(a));
            }
            loop {
                a.push(parse_value(b, p)?);
                skip_ws(b, p);
                match b.get(*p) {
                    Some(b',') => *p += 1,
                    Some(b']') => {
                        *p += 1;
                        return Ok(Json::Arr(a));
                    }
                    _ => return Err(format!("',' or ']' expected at offset {p}")),
                }
            }
        }
        b'"' => {
            *p += 1;
            let mut s = String::new();
            loop {
                let Some(&c) = b.get(*p) else { return Err("unterminated string".to_string()) };
                *p += 1;
                match c {
                    b'"' => break,
                    b'\\' => {
                        let Some(&e) = b.get(*p) else { return Err("unterminated string".to_string()) };
                        *p += 1;
                        match e {
                            b'"' => s.push('"'),
                            b'\\' => s.push('\\'),
                            b'/' => s.push('/'),
                            b'n' => s.push('\n'),
                            b't' => s.push('\t'),
                            b'r' => s.push('\r'),
                            b'b' => s.push('\u{8}'),
                            b'f' => s.push('\u{c}'),
                            b'u' => {
                                let hex = b.get(*p..*p + 4).ok_or("bad \\u escape")?;
                                let code = u32::from_str_radix(core::str::from_utf8(hex).map_err(|_| "bad \\u escape")?, 16)
                                    .map_err(|_| "bad \\u escape")?;
                                *p += 4;
                                s.push(char::from_u32(code).unwrap_or('\u{fffd}'));
                            }
                            _ => return Err(format!("bad escape at offset {p}")),
                        }
                    }
                    _ => {
                        let start = *p - 1;
                        let mut end = *p;
                        while end < b.len() && b[end] != b'"' && b[end] != b'\\' {
                            end += 1;
                        }
                        s.push_str(core::str::from_utf8(&b[start..end]).map_err(|_| "invalid utf-8 in string")?);
                        *p = end;
                    }
                }
            }
            Ok(Json::Str(s))
        }
        b't' if b[*p..].starts_with(b"true") => {
            *p += 4;
            Ok(Json::Bool(true))
        }
        b'f' if b[*p..].starts_with(b"false") => {
            *p += 5;
            Ok(Json::Bool(false))
        }
        b'n' if b[*p..].starts_with(b"null") => {
            *p += 4;
            Ok(Json::Null)
        }
        b'-' | b'0'..=b'9' => {
            let start = *p;
            *p += 1;
            while *p < b.len() && matches!(b[*p], b'0'..=b'9' | b'.' | b'e' | b'E' | b'+' | b'-') {
                *p += 1;
            }
            let s = core::str::from_utf8(&b[start..*p]).map_err(|_| "bad number")?;
            if let Ok(i) = s.parse::<i64>() {
                return Ok(Json::Int(i));
            }
            s.parse::<f64>().map(Json::Float).map_err(|_| format!("bad number '{s}'"))
        }
        _ => Err(format!("unexpected character '{}' at offset {p}", c as char)),
    }
}

/// `collect_task_graph_json`: the fine-grained graph, one task per vertex.
fn collect_task_graph_json(s: &mut TaskSystem, out: &mut Json) {
    s.ensure_levels();
    out.set("name", Json::Str(s.name.clone()));
    out.set("num_threads", Json::Int(s.max_num_threads as i64));
    let mut tasks = Vec::new();
    let mut deps = Vec::new();
    for v in s.vertices() {
        let c = s.cluster(v);
        let eq = c.tasks[0].index as i64;
        let mut t = Json::obj();
        t.set("eq", Json::Int(eq));
        t.set("level", Json::Int(c.level));
        t.set("cost", Json::Float(c.cost));
        t.set("out_degree", Json::Int(s.out_degree(v) as i64));
        tasks.push(t);
        for &ch in &s.children[v] {
            deps.push(Json::Arr(vec![Json::Int(eq), Json::Int(s.cluster(ch).tasks[0].index as i64)]));
        }
    }
    out.set("tasks", Json::Arr(tasks));
    out.set("dependencies", Json::Arr(deps));
}

fn collect_clusters_json(s: &TaskSystem, out: &mut Json) {
    let mut clusters = Vec::new();
    for v in s.vertices() {
        let c = s.cluster(v);
        let mut cl = Json::obj();
        cl.set("eqs", Json::Arr(c.tasks.iter().map(|t| Json::Int(t.index as i64)).collect()));
        cl.set("lane", Json::Int(c.lane as i64));
        clusters.push(cl);
    }
    out.set("clusters", Json::Arr(clusters));
}

fn write_json_file(path: &str, j: &Json, what: &str) -> Result<()> {
    let mut text = j.dump();
    text.push('\n');
    if !crate::files::write(path, text.as_bytes()) {
        return Err(leak_error(format!("Fatal : Could not open '{path}' for writing the parmodauto {what}.")));
    }
    stdout(&format!("Exported parmodauto {what} to {path}\n"));
    Ok(())
}

fn stage_snapshot_path(prefix: &str, stage: usize, stage_name: &str) -> String {
    let base = prefix.strip_suffix(".json").unwrap_or(prefix);
    format!("{base}.{stage:02}.{stage_name}.json")
}

/// `ClusteringStageDumper`: `<prefix>.NN.<stage>.json` per clustering pass.
struct StageDumper {
    prefix: Option<String>,
    base_graph: Json,
    stage: usize,
}

impl StageDumper {
    fn new(s: &mut TaskSystem, prefix: Option<&str>) -> StageDumper {
        let prefix = prefix.filter(|p| !p.is_empty()).map(|p| p.to_string());
        let mut base_graph = Json::obj();
        if prefix.is_some() {
            collect_task_graph_json(s, &mut base_graph);
        }
        StageDumper { prefix, base_graph, stage: 0 }
    }
    fn snapshot(&mut self, s: &TaskSystem, stage_name: &str) -> Result<()> {
        let Some(prefix) = &self.prefix else { return Ok(()) };
        let mut snap = self.base_graph.clone_json();
        snap.set("stage", Json::Int(self.stage as i64));
        snap.set("stage_name", Json::Str(stage_name.to_string()));
        collect_clusters_json(s, &mut snap);
        write_json_file(&stage_snapshot_path(prefix, self.stage, stage_name), &snap, &format!("stage '{stage_name}'"))?;
        self.stage += 1;
        Ok(())
    }
}

impl Json {
    fn clone_json(&self) -> Json {
        match self {
            Json::Null => Json::Null,
            Json::Bool(b) => Json::Bool(*b),
            Json::Int(i) => Json::Int(*i),
            Json::Float(f) => Json::Float(*f),
            Json::Str(s) => Json::Str(s.clone()),
            Json::Arr(a) => Json::Arr(a.iter().map(Json::clone_json).collect()),
            Json::Obj(m) => Json::Obj(m.iter().map(|(k, v)| (k.clone(), v.clone_json())).collect()),
        }
    }
}

/// `import_clustering_json`: apply an external clustering, rejecting an unknown or
/// repeated equation and a cluster graph with a cycle.
fn import_clustering_json(s: &mut TaskSystem, path: &str) -> Result<()> {
    let fatal = |m: String| leak_error(format!("Fatal : {m}"));
    let Some(bytes) = crate::files::read(path) else {
        return Err(fatal(format!("Could not open clustering json '{path}'.")));
    };
    let text = String::from_utf8_lossy(&bytes);
    let j = Json::parse(&text).map_err(|e| fatal(format!("Could not parse clustering json '{path}': {e}")))?;
    let Some(clusters) = j.get("clusters").and_then(Json::as_array) else {
        return Err(fatal(format!("Clustering json '{path}' has no 'clusters' array.")));
    };
    s.ensure_levels();
    let mut eq_to_vid: Vec<(i64, usize)> = s.vertices().map(|v| (s.cluster(v).tasks[0].index as i64, v)).collect();
    eq_to_vid.sort();
    let vid_of = |eq: i64| eq_to_vid.binary_search_by_key(&eq, |(e, _)| *e).ok().map(|i| eq_to_vid[i].1);
    let mut eq_to_cluster: Vec<Option<usize>> = vec![None; s.nodes.len()];
    let mut cluster_eqs: Vec<Vec<usize>> = Vec::new();
    for c in clusters {
        let mut eqs = Vec::new();
        for e in c.get("eqs").and_then(Json::as_array).unwrap_or(&[]) {
            let eq = e.as_i64().unwrap_or(i64::MIN);
            let Some(v) = vid_of(eq) else {
                return Err(fatal(format!("Imported clustering references unknown equation {eq}.")));
            };
            if eq_to_cluster[v].is_some() {
                return Err(fatal(format!("Imported clustering assigns equation {eq} to more than one cluster.")));
            }
            eq_to_cluster[v] = Some(cluster_eqs.len());
            eqs.push(v);
        }
        if !eqs.is_empty() {
            cluster_eqs.push(eqs);
        }
    }
    for &(_, v) in &eq_to_vid {
        if eq_to_cluster[v].is_none() {
            eq_to_cluster[v] = Some(cluster_eqs.len());
            cluster_eqs.push(vec![v]);
        }
    }
    let num_clusters = cluster_eqs.len();
    let mut succ: Vec<BTreeSet<usize>> = vec![BTreeSet::new(); num_clusters];
    for v in s.vertices() {
        let ca = eq_to_cluster[v].unwrap();
        for &ch in &s.children[v] {
            let cb = eq_to_cluster[ch].unwrap();
            if ca != cb {
                succ[ca].insert(cb);
            }
        }
    }
    let mut indeg = vec![0usize; num_clusters];
    for a in 0..num_clusters {
        for &b in &succ[a] {
            indeg[b] += 1;
        }
    }
    let mut ready: Vec<usize> = (0..num_clusters).filter(|&a| indeg[a] == 0).collect();
    let mut visited = 0;
    while let Some(a) = ready.pop() {
        visited += 1;
        for &b in &succ[a] {
            indeg[b] -= 1;
            if indeg[b] == 0 {
                ready.push(b);
            }
        }
    }
    if visited != num_clusters {
        return Err(fatal("Imported clustering forms a cycle in the cluster graph; aborting.".to_string()));
    }
    for eqs in &cluster_eqs {
        if eqs.len() <= 1 {
            continue;
        }
        let mut rep = eqs[0];
        for &v in &eqs[1..] {
            if s.cluster(v).level < s.cluster(rep).level {
                rep = v;
            }
        }
        for &v in eqs {
            if v != rep {
                s.concat(rep, v);
            }
        }
    }
    s.levels_valid = false;
    stdout(&format!("Imported parmodauto clustering ({num_clusters} clusters) from {path}\n"));
    Ok(())
}

// ───────────────────────────── schedulers ─────────────────────────────

/// What the scheduler asks the model for: the whole sequential `functionODE`,
/// `functionLocalKnownVars` alone, or one task via `parmodTask`.
pub enum Op {
    All,
    LocalKnown,
    Task(u32),
}

type Call<'a> = &'a mut dyn FnMut(Op) -> Result<()>;

/// `StepLevels`: level-synchronous; re-profiles and re-clusters when the
/// evaluation time drifts by more than half.
struct LevelScheduler {
    org: TaskSystem,
    sys: TaskSystem,
    schedule_available: bool,
    total_evaluations: u32,
    parallel_evaluations: u32,
    sequential_evaluations: u32,
    par_avg_at_last_sch: f64,
    par_current_avg: f64,
    total_parallel_cost: f64,
    has_run_parallel: bool,
    execution_time: f64,
    clustering_time: f64,
}

impl LevelScheduler {
    fn new(sys: TaskSystem) -> LevelScheduler {
        LevelScheduler {
            org: sys.clone(),
            sys,
            schedule_available: false,
            total_evaluations: 0,
            parallel_evaluations: 0,
            sequential_evaluations: 0,
            par_avg_at_last_sch: 0.0,
            par_current_avg: 0.0,
            total_parallel_cost: 0.0,
            has_run_parallel: false,
            execution_time: 0.0,
            clustering_time: 0.0,
        }
    }

    fn reschedule_needed(&self) -> bool {
        if !self.schedule_available {
            return true;
        }
        let change = libm::fabs(self.par_avg_at_last_sch - self.par_current_avg) / self.par_avg_at_last_sch;
        change > 0.5
    }

    fn execute(&mut self, cfg: &Config, call: Call) -> Result<()> {
        if self.reschedule_needed() {
            self.sys = self.org.clone();
            self.schedule_available = false;
            self.profile_execute(call)?;
            self.schedule(cfg)?;
            self.par_avg_at_last_sch = self.par_current_avg;
            return Ok(());
        }
        let t0 = now_ms_host();
        self.sys.execute_all(call)?;
        let step_cost = now_ms_host() - t0;
        self.execution_time += step_cost;
        self.total_evaluations += 1;
        self.parallel_evaluations += 1;
        self.total_parallel_cost += step_cost;
        self.par_current_avg = self.total_parallel_cost / self.parallel_evaluations as f64;
        if !self.has_run_parallel {
            self.par_avg_at_last_sch = self.par_current_avg;
            self.has_run_parallel = true;
        }
        Ok(())
    }

    fn profile_execute(&mut self, call: Call) -> Result<()> {
        let t0 = now_ms_host();
        self.sys.profile_all(call)?;
        self.total_evaluations += 1;
        self.sequential_evaluations += 1;
        let step_cost = now_ms_host() - t0;
        self.execution_time += step_cost;
        stdout(&format!(
            "S : {} : {} : {} : {}\n",
            self.total_evaluations,
            g(step_cost),
            g(self.par_current_avg),
            g(self.par_avg_at_last_sch)
        ));
        Ok(())
    }

    fn schedule(&mut self, cfg: &Config) -> Result<()> {
        let t0 = now_ms_host();
        self.sys.ensure_levels();
        let mut stages = StageDumper::new(&mut self.sys, cfg.dump_stages.as_deref());
        stages.snapshot(&self.sys, "initial")?;
        cluster_merge_common(&mut self.sys);
        stages.snapshot(&self.sys, CLUSTER_MERGE_COMMON)?;
        cluster_merge_level_for_bins(&mut self.sys, cfg);
        stages.snapshot(&self.sys, CLUSTER_MERGE_LEVEL_FOR_BINS)?;
        self.schedule_available = true;
        self.sys.levels_valid = false;
        self.sys.update_node_levels();
        // `estimate_speedup` leaves every level sorted by decreasing cost.
        for l in 1..self.sys.levels.len() {
            let mut level = core::mem::take(&mut self.sys.levels[l]);
            self.sys.sort_decreasing(&mut level);
            self.sys.levels[l] = level;
        }
        self.clustering_time += now_ms_host() - t0;
        Ok(())
    }
}

/// `ClusterDynamicScheduler`: clusters as a dependency graph, scheduled once.
struct FlowScheduler {
    sys: TaskSystem,
    flow_graph_created: bool,
    total_evaluations: u32,
    parallel_evaluations: u32,
    sequential_evaluations: u32,
    execution_time: f64,
    clustering_time: f64,
}

impl FlowScheduler {
    fn new(sys: TaskSystem) -> FlowScheduler {
        FlowScheduler {
            sys,
            flow_graph_created: false,
            total_evaluations: 0,
            parallel_evaluations: 0,
            sequential_evaluations: 0,
            execution_time: 0.0,
            clustering_time: 0.0,
        }
    }

    fn execute(&mut self, cfg: &Config, call: Call) -> Result<()> {
        if !self.flow_graph_created {
            self.schedule(cfg, call)?;
        }
        let t0 = now_ms_host();
        self.sys.execute_all(call)?;
        self.execution_time += now_ms_host() - t0;
        self.total_evaluations += 1;
        self.parallel_evaluations += 1;
        Ok(())
    }

    fn schedule(&mut self, cfg: &Config, call: Call) -> Result<()> {
        let t0 = now_ms_host();
        for _ in 0..2 {
            self.sys.execute_all(call)?;
        }
        self.sys.profile_all(call)?;
        self.sequential_evaluations += 1;
        self.total_evaluations += 1;
        self.sys.ensure_levels();
        let mut graph_dump = Json::obj();
        if cfg.export_taskgraph.is_some() {
            collect_task_graph_json(&mut self.sys, &mut graph_dump);
        }
        let mut stages = StageDumper::new(&mut self.sys, cfg.dump_stages.as_deref());
        stages.snapshot(&self.sys, "initial")?;
        if let Some(path) = &cfg.import_clustering {
            import_clustering_json(&mut self.sys, path)?;
            stages.snapshot(&self.sys, "imported")?;
        } else if cfg.clustering == CLUSTER_FIXED_WIDTH_MIN_HEIGHT || cfg.clustering == "fixed_width_min_height" {
            cluster_fixed_width_min_height(&mut self.sys);
            stages.snapshot(&self.sys, CLUSTER_FIXED_WIDTH_MIN_HEIGHT)?;
        } else if cfg.clustering == "none" {
        } else {
            cluster_merge_common(&mut self.sys);
            stages.snapshot(&self.sys, CLUSTER_MERGE_COMMON)?;
            cluster_merge_level_for_bins(&mut self.sys, cfg);
            stages.snapshot(&self.sys, CLUSTER_MERGE_LEVEL_FOR_BINS)?;
        }
        self.sys.levels_valid = false;
        self.sys.update_node_levels();
        if let Some(path) = &cfg.export_taskgraph {
            collect_clusters_json(&self.sys, &mut graph_dump);
            write_json_file(path, &graph_dump, "task graph")?;
        }
        self.flow_graph_created = true;
        self.clustering_time += now_ms_host() - t0;
        Ok(())
    }
}

enum Scheduler {
    Level(LevelScheduler),
    Flow(FlowScheduler),
}

struct State {
    cfg: Config,
    sched: Scheduler,
    load_time: f64,
}

struct Store(UnsafeCell<Option<State>>);
unsafe impl Sync for Store {}
static STATE: Store = Store(UnsafeCell::new(None));

// The driver is single-threaded per run (as is the in-wasm session).
fn state() -> &'static mut Option<State> {
    unsafe { &mut *STATE.0.get() }
}

/// `PM_Model_create` + `PM_Model_load_ODE_system`, for a model translated with
/// `--parmodauto`; a plain model leaves `functionODE` alone.
pub fn init(model: &SimMeta) {
    *state() = None;
    let Some(info) = &model.parmod else { return };
    let cfg = Config::from_flags();
    let t0 = now_ms_host();
    let sys = TaskSystem::new(&model.prefix, cfg.num_threads, info);
    stdout(&format!("Number of tasks      = {}\n", info.tasks.len()));
    let load_time = now_ms_host() - t0;
    let sched = match cfg.scheduler.as_str() {
        "level" => Scheduler::Level(LevelScheduler::new(sys)),
        _ => Scheduler::Flow(FlowScheduler::new(sys)),
    };
    *state() = Some(State { cfg, sched, load_time });
}

pub fn active() -> bool {
    state().is_some()
}

/// `PM_evaluate_ODE_system`.
pub fn evaluate_ode(call: Call) -> Result<()> {
    let Some(st) = state().as_mut() else { return Err("parmodauto: no task system loaded") };
    match &mut st.sched {
        Scheduler::Level(s) => s.execute(&st.cfg, call),
        Scheduler::Flow(s) => s.execute(&st.cfg, call),
    }
}

/// `dump_times`, printed once after the run.
pub fn finish() {
    let Some(st) = state().take() else { return };
    let (total, seq, par, exec, clust) = match &st.sched {
        Scheduler::Level(s) => (s.total_evaluations, s.sequential_evaluations, s.parallel_evaluations, s.execution_time, s.clustering_time),
        Scheduler::Flow(s) => (s.total_evaluations, s.sequential_evaluations, s.parallel_evaluations, s.execution_time, s.clustering_time),
    };
    let avg = if par > 0 { exec / par as f64 } else { 0.0 };
    let mut out = String::new();
    out.push_str(&format!(" : Using {} scheduler\n", st.cfg.scheduler));
    out.push_str(&format!(" : Nr.of threads {}\n", st.cfg.num_threads));
    out.push_str(&format!(" : Nr.of ODE evaluations: {total}\n"));
    out.push_str(&format!(" : Nr.of profiling ODE Evaluations: {seq}\n"));
    out.push_str(&format!(" : Total ODE evaluation time : {}\n", g(exec)));
    out.push_str(&format!(" : Avg. ODE evaluation time : {}\n", g(avg)));
    out.push_str(&format!(" : Total ODE loading time: {}\n", g(st.load_time)));
    out.push_str(&format!(" : Total ODE Clustering time: {}\n", g(clust)));
    stdout(&out);
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ParmodTask;

    fn chain_info() -> ParmodInfo {
        // 1 -> 2 -> 3, 4 alone
        ParmodInfo {
            tasks: vec![
                ParmodTask { eq_index: 1, parents: vec![] },
                ParmodTask { eq_index: 2, parents: vec![0] },
                ParmodTask { eq_index: 3, parents: vec![1] },
                ParmodTask { eq_index: 4, parents: vec![] },
            ],
        }
    }

    #[test]
    fn levels_follow_the_longest_path() {
        let mut s = TaskSystem::new("m", 2, &chain_info());
        s.update_node_levels();
        let lv: Vec<i64> = s.vertices().map(|v| s.cluster(v).level).collect();
        assert_eq!(lv, vec![1, 2, 3, 1]);
        assert_eq!(s.levels[1], vec![1, 4]);
    }

    #[test]
    fn merge_common_collapses_the_chain() {
        let mut s = TaskSystem::new("m", 2, &chain_info());
        s.update_node_levels();
        cluster_merge_common(&mut s);
        let live: Vec<usize> = s.vertices().collect();
        assert_eq!(live, vec![1, 4]);
        assert_eq!(s.cluster(1).index_list(), "$,1,2,3");
        assert_eq!(s.topological_order(), vec![0, 1, 4]);
    }

    #[test]
    fn json_round_trips() {
        let text = "{\"clusters\": [{\"eqs\": [1, 2], \"lane\": -1}], \"name\": \"m\\n\", \"x\": 1.5}";
        let j = Json::parse(text).unwrap();
        assert_eq!(j.get("clusters").unwrap().as_array().unwrap()[0].get("eqs").unwrap().as_array().unwrap()[1].as_i64(), Some(2));
        let dumped = j.dump();
        assert!(dumped.starts_with("{\n  \"clusters\": [\n    {\n      \"eqs\": [\n        1,\n        2\n      ],\n      \"lane\": -1\n    }\n  ],\n  \"name\": \"m\\n\",\n  \"x\": 1.5\n}"));
        assert_eq!(Json::parse(&dumped).unwrap().dump(), dumped);
    }

    #[test]
    fn stage_paths() {
        assert_eq!(stage_snapshot_path("stages", 0, "initial"), "stages.00.initial.json");
        assert_eq!(stage_snapshot_path("a/b.json", 12, "x"), "a/b.12.x.json");
    }
}
