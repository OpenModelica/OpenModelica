//! UI-agnostic REPL state. The egui and dioxus front-ends own a `Shell`, drive
//! it with `poll()`/`submit()`, and render `scrollback` + `input`.

use crate::backend::OmcBackend;
use crate::completion::Completion;
use crate::driver::{Driver, DriverMsg};

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum SegKind {
    Banner,
    Command,
    Result,
    Error,
}

pub struct Segment {
    pub kind: SegKind,
    pub text: String,
}

/// An in-flight download (wasm web build). `total == 0` means the size is unknown
/// (no Content-Length), so the front-end shows an indeterminate bar.
pub struct Download {
    pub file: String,
    pub done: u64,
    pub total: u64,
}

impl Download {
    /// Completed fraction in `0.0..=1.0`, or `None` when the size is unknown.
    pub fn fraction(&self) -> Option<f32> {
        (self.total > 0).then(|| (self.done as f32 / self.total as f32).clamp(0.0, 1.0))
    }
}

pub struct Shell {
    driver: Driver,
    pub scrollback: Vec<Segment>,
    pub input: String,
    history: Vec<String>,
    hist_idx: Option<usize>,
    completion: Completion,
    pub busy: bool,
    /// The current download while `busy`, if the running command is fetching
    /// (e.g. installPackage). `None` between downloads / on native.
    pub download: Option<Download>,
    pub version: String,
    pub quit: bool,
}

impl Shell {
    /// Start with a caller-supplied backend (e.g. `omshell_omc::backend()`).
    /// `repaint` is called from the worker thread (native) to wake the UI; on
    /// wasm it is unused (the UI polls on a timer).
    pub fn with_backend(
        backend: Box<dyn OmcBackend + Send>,
        repaint: impl Fn() + Send + 'static,
    ) -> Self {
        Self {
            driver: Driver::spawn(backend, repaint),
            scrollback: Vec::new(),
            input: String::new(),
            history: Vec::new(),
            hist_idx: None,
            completion: Completion::load(),
            busy: true,
            download: None,
            version: String::new(),
            quit: false,
        }
    }

    /// Apply any pending replies. Returns true if the state changed.
    pub fn poll(&mut self) -> bool {
        let mut changed = false;
        while let Some(msg) = self.driver.try_recv() {
            changed = true;
            match msg {
                DriverMsg::Ready(Ok(init)) => {
                    self.version = init.version;
                    self.push_banner();
                    // Surface the getErrorString() left over from the start-up
                    // installPackage(Modelica), if any.
                    if !init.message.is_empty() {
                        self.push(SegKind::Error, init.message);
                    }
                    self.busy = false;
                    self.download = None;
                }
                DriverMsg::Ready(Err(e)) => {
                    self.push(SegKind::Error, format!("Failed to start OMC: {e}"));
                    self.busy = false;
                    self.download = None;
                }
                DriverMsg::Done {
                    result,
                    error,
                    keep_running,
                } => {
                    if !result.is_empty() {
                        self.push(SegKind::Result, result);
                    }
                    if !error.is_empty() {
                        self.push(SegKind::Error, error);
                    }
                    self.busy = false;
                    self.download = None;
                    if !keep_running {
                        self.quit = true;
                    }
                }
                DriverMsg::Progress { file, done, total } => {
                    self.download = Some(Download { file, done, total });
                }
            }
        }
        changed
    }

    pub fn submit(&mut self) {
        let cmd = std::mem::take(&mut self.input).trim().to_owned();
        if cmd.is_empty() || self.busy {
            self.input.clear();
            return;
        }
        self.push(SegKind::Command, format!(">> {cmd}"));
        self.history.push(cmd.clone());
        self.hist_idx = None;
        self.completion.reset();
        if cmd == "quit()" {
            self.quit = true;
            return;
        }
        self.driver.submit(cmd);
        self.busy = true;
        self.download = None;
    }

    /// Set the input to `cmd` and submit it (menu actions: loadFile, etc.).
    pub fn run(&mut self, cmd: &str) {
        if self.busy {
            return;
        }
        self.input = cmd.to_owned();
        self.submit();
    }

    pub fn clear(&mut self) {
        self.scrollback.clear();
    }

    pub fn history_prev(&mut self) {
        if self.history.is_empty() {
            return;
        }
        let idx = match self.hist_idx {
            None => self.history.len() - 1,
            Some(i) => i.saturating_sub(1),
        };
        self.hist_idx = Some(idx);
        self.input = self.history[idx].clone();
    }

    pub fn history_next(&mut self) {
        if let Some(i) = self.hist_idx {
            if i + 1 < self.history.len() {
                self.hist_idx = Some(i + 1);
                self.input = self.history[i + 1].clone();
            } else {
                self.hist_idx = None;
                self.input.clear();
            }
        }
    }

    pub fn complete(&mut self) {
        if let Some(c) = self.completion.complete(&self.input) {
            self.input = c;
        }
    }

    fn push(&mut self, kind: SegKind, text: String) {
        self.scrollback.push(Segment { kind, text });
    }

    fn push_banner(&mut self) {
        let text = format!(
            "OMShell (egui/dioxus) — Copyright Open Source Modelica Consortium (OSMC) 2002-2026\n\
             Distributed under OSMC-PL and AGPL3, see www.openmodelica.org\n\n\
             Connected to {}\n\n\
             To get help on using OMShell and OpenModelica, type \"help()\" and press enter.",
            self.version
        );
        self.push(SegKind::Banner, text);
    }
}
