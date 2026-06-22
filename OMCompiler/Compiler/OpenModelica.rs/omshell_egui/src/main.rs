#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

// ---- Native ----
#[cfg(not(target_arch = "wasm32"))]
fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([800.0, 600.0])
            .with_min_inner_size([400.0, 300.0])
            .with_title("OMShell - OpenModelica Shell"),
        ..Default::default()
    };
    eframe::run_native(
        "OMShell - OpenModelica Shell",
        options,
        Box::new(|cc| Ok(Box::new(omshell_egui::App::new(cc)))),
    )
}

// ---- Web (trunk) ----
#[cfg(target_arch = "wasm32")]
fn main() {
    use eframe::wasm_bindgen::JsCast as _;

    let web_options = eframe::WebOptions::default();
    wasm_bindgen_futures::spawn_local(async {
        let document = web_sys::window()
            .expect("no window")
            .document()
            .expect("no document");
        let canvas = document
            .get_element_by_id("the_canvas_id")
            .expect("missing #the_canvas_id")
            .dyn_into::<web_sys::HtmlCanvasElement>()
            .expect("#the_canvas_id is not a canvas");
        let _ = eframe::WebRunner::new()
            .start(
                canvas,
                web_options,
                Box::new(|cc| Ok(Box::new(omshell_egui::App::new(cc)))),
            )
            .await;
    });
}
