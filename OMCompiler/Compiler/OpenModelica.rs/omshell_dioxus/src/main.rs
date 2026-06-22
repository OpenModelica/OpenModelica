use std::cell::RefCell;
use std::rc::Rc;

use dioxus::prelude::*;
use omshell_core::{SegKind, Shell};

fn main() {
    #[cfg(feature = "desktop")]
    {
        // dioxus-desktop attaches a default native window menu (Window/Edit/Help).
        // OMShell draws its own in-app menu bar, so suppress the native one to
        // avoid showing two menu bars stacked on the desktop client.
        use dioxus::desktop::{Config, muda::Menu};
        dioxus::LaunchBuilder::desktop()
            .with_cfg(Config::new().with_menu(Option::<Menu>::None))
            .launch(app);
    }
    #[cfg(not(feature = "desktop"))]
    dioxus::launch(app);
}

/// Cross-target async sleep so the poll loop works on both web and desktop.
async fn sleep_ms(ms: u32) {
    #[cfg(target_arch = "wasm32")]
    gloo_timers::future::TimeoutFuture::new(ms).await;
    #[cfg(not(target_arch = "wasm32"))]
    tokio::time::sleep(std::time::Duration::from_millis(ms as u64)).await;
}

fn app() -> Element {
    // The Shell holds the OMC driver; keep it in a !Send-friendly cell. A `tick`
    // signal forces a re-render whenever the driver produces something new.
    let shell = use_hook(|| Rc::new(RefCell::new(Shell::with_backend(omshell_omc::backend(), || {}))));
    let mut tick = use_signal(|| 0u64);
    let mut about = use_signal(|| false);

    {
        let shell = shell.clone();
        use_future(move || {
            let shell = shell.clone();
            async move {
                loop {
                    sleep_ms(50).await;
                    if shell.borrow_mut().poll() {
                        tick += 1;
                    }
                }
            }
        });
    }
    let _ = tick(); // subscribe so driver updates re-render

    let (segments, input, busy, version) = {
        let s = shell.borrow();
        let segs: Vec<(SegKind, String)> = s
            .scrollback
            .iter()
            .map(|seg| (seg.kind, seg.text.clone()))
            .collect();
        (segs, s.input.clone(), s.busy, s.version.clone())
    };

    let on_input = {
        let shell = shell.clone();
        move |e: FormEvent| shell.borrow_mut().input = e.value()
    };
    let on_keydown = {
        let shell = shell.clone();
        move |e: KeyboardEvent| match e.key() {
            Key::Enter => {
                shell.borrow_mut().submit();
                tick += 1;
            }
            Key::ArrowUp => {
                shell.borrow_mut().history_prev();
                tick += 1;
            }
            Key::ArrowDown => {
                shell.borrow_mut().history_next();
                tick += 1;
            }
            Key::Tab => {
                e.prevent_default();
                shell.borrow_mut().complete();
                tick += 1;
            }
            _ => {}
        }
    };
    let load_msl = {
        let shell = shell.clone();
        move |_| {
            shell.borrow_mut().run("loadModel(Modelica)");
            tick += 1;
        }
    };
    let clear = {
        let shell = shell.clone();
        move |_| {
            shell.borrow_mut().clear();
            tick += 1;
        }
    };

    rsx! {
        style { {CSS} }
        div { id: "omshell",
            div { id: "menubar",
                div { class: "menu",
                    span { class: "menu-title", "File" }
                    div { class: "menu-items",
                        button { onclick: load_msl, "Load Modelica Library" }
                    }
                }
                div { class: "menu",
                    span { class: "menu-title", "Edit" }
                    div { class: "menu-items",
                        button { onclick: clear, "Clear" }
                    }
                }
                div { class: "menu",
                    span { class: "menu-title", "Help" }
                    div { class: "menu-items",
                        button { onclick: move |_| about.set(true), "About OMShell" }
                    }
                }
            }
            div { id: "log",
                for (kind , text) in segments.iter() {
                    pre { class: seg_class(*kind), "{text}" }
                }
                // While a command (or start-up) is running, show a spinner below
                // the last line so it is clear omc is working.
                if busy {
                    div { class: "spinner",
                        span { class: "dot" }
                        span { "running…" }
                    }
                }
            }
            div { id: "inputline",
                span { class: "prompt", ">>" }
                input {
                    r#type: "text",
                    value: "{input}",
                    disabled: busy,
                    autofocus: true,
                    oninput: on_input,
                    onkeydown: on_keydown,
                }
            }
            if about() {
                div {
                    class: "modal-backdrop",
                    onclick: move |_| about.set(false),
                    div {
                        class: "modal",
                        // Clicks inside the dialog must not close it.
                        onclick: move |e| e.stop_propagation(),
                        h3 { "About OMShell" }
                        p { "OMShell (dioxus)" }
                        p { "Connected to {version}" }
                        p { "Distributed under OSMC-PL and AGPL3." }
                        p { "www.openmodelica.org" }
                        button { onclick: move |_| about.set(false), "Close" }
                    }
                }
            }
        }
    }
}

fn seg_class(k: SegKind) -> &'static str {
    match k {
        SegKind::Banner => "banner",
        SegKind::Command => "cmd",
        SegKind::Result => "result",
        SegKind::Error => "error",
    }
}

static CSS: &str = r#"
* { box-sizing: border-box; }
html, body, #main { height: 100%; margin: 0; }
#omshell { display: flex; flex-direction: column; height: 100vh;
           font-family: monospace; background: #1e1e1e; color: #ddd; }
#menubar { display: flex; align-items: center; background: #2d2d2d;
           border-bottom: 1px solid #000; padding: 0 4px; }
#menubar .menu { position: relative; }
#menubar .menu-title { display: inline-block; padding: 6px 10px; cursor: default;
                       user-select: none; }
#menubar .menu:hover .menu-title { background: #094771; }
#menubar .menu-items { display: none; position: absolute; left: 0; top: 100%; z-index: 10;
                       background: #2d2d2d; border: 1px solid #000; min-width: 190px; }
#menubar .menu:hover .menu-items { display: block; }
#menubar .menu-items button { display: block; width: 100%; text-align: left; border: 0;
                              background: transparent; color: #ddd; padding: 6px 12px;
                              cursor: pointer; font-family: monospace; font-size: inherit; }
#menubar .menu-items button:hover { background: #094771; color: #fff; }
.spinner { display: flex; align-items: center; gap: 8px; padding: 6px 0; color: #e0c060; }
.spinner .dot { width: 12px; height: 12px; border: 2px solid #555; border-top-color: #e0c060;
                border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100;
                  display: flex; align-items: center; justify-content: center; }
.modal { background: #252526; border: 1px solid #444; padding: 16px 20px; max-width: 360px; }
.modal h3 { margin: 0 0 8px; color: #4ec9b0; }
.modal p { margin: 4px 0; }
.modal button { margin-top: 12px; padding: 4px 12px; }
#log { flex: 1; overflow-y: auto; padding: 8px; }
#log pre { margin: 0; white-space: pre-wrap; word-break: break-word; }
.banner { color: #888; }
.cmd { color: #fff; font-weight: bold; }
.result { color: #ddd; }
.error { color: #dc5a5a; }
#inputline { display: flex; padding: 6px; background: #2d2d2d; border-top: 1px solid #000; }
#inputline .prompt { font-weight: bold; margin-right: 6px; }
#inputline input { flex: 1; background: #1e1e1e; color: #fff;
                   border: 1px solid #444; font-family: monospace; padding: 2px 4px; }
"#;
