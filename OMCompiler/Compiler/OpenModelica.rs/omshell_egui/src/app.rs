use egui::{Color32, FontFamily, FontId, Key, Modifiers, RichText, TextStyle};
use omshell_core::{SegKind, Shell};

pub struct App {
    shell: Shell,
    font_size: f32,
    want_focus: bool,
    about_open: bool,
}

impl App {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let ctx = cc.egui_ctx.clone();
        let shell = Shell::with_backend(omshell_omc::backend(), move || ctx.request_repaint());
        Self {
            shell,
            font_size: 13.0,
            want_focus: true,
            about_open: false,
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

        egui::Panel::top("menu_bar").show_inside(ui, |ui| self.menu_bar(ui));
        egui::Panel::bottom("input").show_inside(ui, |ui| self.input_line(ui));
        egui::CentralPanel::default().show_inside(ui, |ui| self.scrollback_view(ui));

        if self.shell.busy {
            ctx.request_repaint();
        }
    }
}
