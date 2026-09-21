use eframe::egui_wgpu::{self, wgpu};
use egui::{Color32, FontFamily, FontId, Key, Modifiers, RichText, TextStyle};
use omshell_core::{SegKind, Shell};

pub struct App {
    shell: Shell,
    font_size: f32,
    want_focus: bool,
    about_open: bool,
    webgpu_open: bool,
}

impl App {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let ctx = cc.egui_ctx.clone();
        let shell = Shell::with_backend(omshell_omc::backend(), move || ctx.request_repaint());
        // Build the shared WebGPU demo into the egui_wgpu renderer's resource map
        // so the Help -> WebGPU test's paint callback can fetch it. eframe is
        // built with the wgpu backend (main.rs / WebOptions), so this is present.
        if let Some(rs) = cc.wgpu_render_state.as_ref() {
            let demo = omshell_wgpu::Demo::new(&rs.device, rs.target_format);
            rs.renderer.write().callback_resources.insert(demo);
        }
        Self {
            shell,
            font_size: 13.0,
            want_focus: true,
            about_open: false,
            webgpu_open: false,
        }
    }

    fn menu_bar(&mut self, ui: &mut egui::Ui) {
        let ctx = ui.ctx().clone();
        ui.horizontal(|ui| {
            ui.menu_button("File", |ui| {
                // Native file picker; on web there is no local filesystem dialog.
                #[cfg(not(target_arch = "wasm32"))]
                if ui.button("Open…").clicked() {
                    if let Some(path) = rfd::FileDialog::new()
                        .add_filter("Modelica files", &["mo"])
                        .pick_file()
                    {
                        self.shell
                            .run(&format!("loadFile(\"{}\")", path.display()));
                    }
                }
                if ui.button("Load Modelica Library").clicked() {
                    self.shell.run("loadModel(Modelica)");
                }
                ui.separator();
                if ui.button("Exit").clicked() {
                    ctx.send_viewport_cmd(egui::ViewportCommand::Close);
                }
            });
            ui.menu_button("Edit", |ui| {
                if ui.button("Clear").clicked() {
                    self.shell.clear();
                }
                ui.separator();
                ui.menu_button("Font size", |ui| {
                    ui.add(egui::Slider::new(&mut self.font_size, 8.0..=40.0).text("pt"));
                });
            });
            ui.menu_button("Help", |ui| {
                if ui.button("About OMShell").clicked() {
                    self.about_open = true;
                }
                if ui.button("WebGPU test").clicked() {
                    self.webgpu_open = true;
                }
            });
        });
    }

    fn input_line(&mut self, ui: &mut egui::Ui) {
        ui.add_space(4.0);
        ui.horizontal(|ui| {
            ui.label(RichText::new(">>").monospace().strong());
            let resp = ui.add_enabled(
                !self.shell.busy,
                egui::TextEdit::singleline(&mut self.shell.input)
                    .desired_width(f32::INFINITY)
                    .font(TextStyle::Monospace)
                    .hint_text("enter a command, e.g. help()"),
            );

            if resp.has_focus() {
                let (up, down, tab) = ui.input_mut(|i| {
                    (
                        i.key_pressed(Key::ArrowUp),
                        i.key_pressed(Key::ArrowDown),
                        i.consume_key(Modifiers::NONE, Key::Tab),
                    )
                });
                if up {
                    self.shell.history_prev();
                }
                if down {
                    self.shell.history_next();
                }
                if tab {
                    self.shell.complete();
                }
            }

            if resp.lost_focus() && ui.input(|i| i.key_pressed(Key::Enter)) && !self.shell.busy {
                self.shell.submit();
                self.want_focus = true;
            }

            if !self.shell.busy && self.want_focus {
                resp.request_focus();
                self.want_focus = false;
            }
        });
        ui.add_space(4.0);
    }

    fn scrollback_view(&mut self, ui: &mut egui::Ui) {
        egui::ScrollArea::vertical()
            .auto_shrink([false, false])
            .stick_to_bottom(true)
            .show(ui, |ui| {
                for seg in &self.shell.scrollback {
                    let mut rt = RichText::new(&seg.text).monospace();
                    rt = match seg.kind {
                        SegKind::Error => rt.color(Color32::from_rgb(220, 90, 90)),
                        SegKind::Command => rt.strong(),
                        SegKind::Banner => rt.weak(),
                        SegKind::Result => rt,
                    };
                    ui.add(egui::Label::new(rt).selectable(true));
                }
                // While a command (or start-up) is running, show a spinner below
                // the last line so it is clear omc is working. A download shows a
                // progress bar (determinate when the size is known) instead.
                if self.shell.busy {
                    if let Some(dl) = &self.shell.download {
                        let text = match dl.total {
                            0 => format!("downloading {} ({} KB)", dl.file, dl.done / 1024),
                            t => format!("downloading {} ({}/{} KB)", dl.file, dl.done / 1024, t / 1024),
                        };
                        let bar = match dl.fraction() {
                            Some(f) => egui::ProgressBar::new(f).show_percentage(),
                            None => egui::ProgressBar::new(0.0).animate(true),
                        };
                        ui.add(bar.text(RichText::new(text).monospace()));
                    } else {
                        ui.horizontal(|ui| {
                            ui.spinner();
                            ui.label(RichText::new("running…").weak().monospace());
                        });
                    }
                }
            });
    }
}

impl eframe::App for App {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let ctx = ui.ctx().clone();
        self.shell.poll();
        if self.shell.quit {
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
        }

        ctx.global_style_mut(|s| {
            s.text_styles.insert(
                TextStyle::Monospace,
                FontId::new(self.font_size, FontFamily::Monospace),
            );
        });

        if self.about_open {
            egui::Window::new("About OMShell")
                .open(&mut self.about_open)
                .collapsible(false)
                .resizable(false)
                .show(&ctx, |ui| {
                    ui.label(format!(
                        "OMShell (egui)\n\nConnected to {}\n\n\
                         Distributed under OSMC-PL and AGPL3.\nwww.openmodelica.org",
                        self.shell.version
                    ));
                });
        }

        if self.webgpu_open {
            self.webgpu_window(&ctx);
        }

        egui::Panel::top("menu_bar").show_inside(ui, |ui| self.menu_bar(ui));
        egui::Panel::bottom("input").show_inside(ui, |ui| self.input_line(ui));
        egui::CentralPanel::default().show_inside(ui, |ui| self.scrollback_view(ui));

        if self.shell.busy {
            ctx.request_repaint();
        }
    }
}

impl App {
    fn webgpu_window(&mut self, ctx: &egui::Context) {
        let mut open = self.webgpu_open;
        egui::Window::new("WebGPU test")
            .open(&mut open)
            .default_size([460.0, 360.0])
            .show(ctx, |ui| {
                ui.label(
                    RichText::new(
                        "A wgpu scene composited inside egui — the same renderer on native and web.",
                    )
                    .weak(),
                );
                let time = ui.input(|i| i.time) as f32;
                let ppp = ctx.pixels_per_point();
                egui::Frame::canvas(ui.style()).show(ui, |ui| {
                    let (rect, _) = ui.allocate_exact_size(
                        egui::vec2(ui.available_width(), 280.0),
                        egui::Sense::hover(),
                    );
                    let px = rect.size() * ppp;
                    ui.painter().add(egui_wgpu::Callback::new_paint_callback(
                        rect,
                        DemoCallback {
                            time,
                            width: px.x,
                            height: px.y,
                        },
                    ));
                });
            });
        self.webgpu_open = open;
        // Drive the animation while the window is open.
        ctx.request_repaint();
    }
}

/// Per-frame parameters handed to the shared [`omshell_wgpu::Demo`] (stored in
/// the egui_wgpu renderer's resource map) through an egui paint callback.
struct DemoCallback {
    time: f32,
    width: f32,
    height: f32,
}

impl egui_wgpu::CallbackTrait for DemoCallback {
    fn prepare(
        &self,
        _device: &wgpu::Device,
        queue: &wgpu::Queue,
        _screen: &egui_wgpu::ScreenDescriptor,
        _encoder: &mut wgpu::CommandEncoder,
        resources: &mut egui_wgpu::CallbackResources,
    ) -> Vec<wgpu::CommandBuffer> {
        if let Some(demo) = resources.get::<omshell_wgpu::Demo>() {
            demo.prepare(queue, self.time, self.width, self.height);
        }
        Vec::new()
    }

    fn paint(
        &self,
        _info: egui::PaintCallbackInfo,
        render_pass: &mut wgpu::RenderPass<'static>,
        resources: &egui_wgpu::CallbackResources,
    ) {
        if let Some(demo) = resources.get::<omshell_wgpu::Demo>() {
            demo.draw(render_pass);
        }
    }
}
