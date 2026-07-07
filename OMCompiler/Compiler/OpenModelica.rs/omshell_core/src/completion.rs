//! Tab completion sourced from `share/omshell/commands.xml`, like the Qt
//! `CommandCompletion`. Simpler than the original (no in-place field navigation):
//! Tab cycles through matching command templates, with `$N` fields replaced by
//! their human labels (e.g. `cd($0)` + field `dir` -> `cd(dir)`).

use std::path::PathBuf;

struct CommandDef {
    /// Original name, e.g. `loadFile($0)` — matched against the typed prefix.
    name: String,
    /// Display/insert form with `$N` replaced by field labels, e.g. `loadFile(name)`.
    template: String,
}

#[derive(Default)]
pub struct Completion {
    commands: Vec<CommandDef>,
    matches: Vec<String>,
    last: String,
    idx: usize,
}

impl Completion {
    pub fn load() -> Self {
        let mut c = Completion::default();
        if let Some(xml) = read_commands_xml() {
            c.commands = parse(&xml);
        }
        c
    }

    pub fn reset(&mut self) {
        self.matches.clear();
        self.last.clear();
    }

    /// Given the current input, return the next completion candidate (cycling on
    /// repeated calls with unchanged input), or `None` if nothing matches.
    pub fn complete(&mut self, input: &str) -> Option<String> {
        let prefix = input.trim();
        if prefix.is_empty() || self.commands.is_empty() {
            return None;
        }
        if self.matches.is_empty() || self.last != input {
            self.matches = self
                .commands
                .iter()
                .filter(|c| c.name.starts_with(prefix))
                .map(|c| c.template.clone())
                .collect();
            self.matches.dedup();
            self.idx = 0;
        } else {
            self.idx = (self.idx + 1) % self.matches.len();
        }
        let cand = self.matches.get(self.idx).cloned();
        if let Some(c) = &cand {
            // Remember the inserted text so the next Tab cycles instead of
            // recomputing from a now-completed line.
            self.last = c.clone();
        }
        cand
    }
}

fn read_commands_xml() -> Option<String> {
    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Ok(p) = std::env::var("OMSHELL_COMMANDS_XML") {
        candidates.push(PathBuf::from(p));
    }
    if let Ok(home) = std::env::var("OPENMODELICAHOME") {
        candidates.push(PathBuf::from(home).join("share/omshell/commands.xml"));
    }
    for c in candidates {
        if let Ok(s) = std::fs::read_to_string(&c) {
            return Some(s);
        }
    }
    None
}

fn parse(xml: &str) -> Vec<CommandDef> {
    let mut out = Vec::new();
    for chunk in xml.split("<command ").skip(1) {
        let Some(name) = attr(chunk, "name=\"") else {
            continue;
        };
        let body = &chunk[..chunk.find("</command>").unwrap_or(chunk.len())];

        let mut template = name.clone();
        for field in body.split("<field ").skip(1) {
            if let (Some(key), Some(label)) = (attr(field, "name=\""), between(field, ">", "</field>"))
            {
                template = template.replace(&key, label.trim());
            }
        }
        out.push(CommandDef { name, template });
    }
    out
}

/// Read the value of an attribute given its `key="` marker.
fn attr(s: &str, marker: &str) -> Option<String> {
    let start = s.find(marker)? + marker.len();
    let rest = &s[start..];
    let end = rest.find('"')?;
    Some(rest[..end].to_owned())
}

fn between<'a>(s: &'a str, open: &str, close: &str) -> Option<&'a str> {
    let start = s.find(open)? + open.len();
    let rest = &s[start..];
    let end = rest.find(close)?;
    Some(&rest[..end])
}
