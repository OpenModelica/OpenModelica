//! Blitz (dioxus-native) custom widget that composites the shared WebGPU demo
//! ([`omshell_wgpu::Demo`]) into Blitz's scene — the native counterpart of the
//! web build's DOM-canvas path. Native only.
//!
//! The renderer is the same `Demo` the egui and web paths use; only the surface
//! differs. Here we render it into an off-screen wgpu texture each frame and hand
//! the texture to Blitz as an image resource, double-buffering so we never draw
//! into a texture Blitz is still reading. Adapted from DioxusLabs/blitz
//! examples/wgpu_texture (MIT).

use std::time::Instant;

use anyrender::{PaintRef, PaintScene, RenderContext, ResourceId, Scene};
use blitz_dom::node::ComputedStyles;
use blitz_dom::Widget;
use peniko::kurbo::{Affine, Rect};
use peniko::{Fill, ImageBrush, ImageSampler};
use wgpu_context::DeviceHandle;

pub struct DemoWidget {
    state: State,
    start: Instant,
}

enum State {
    Suspended,
    Active(Box<Active>),
}

struct Active {
    device: wgpu::Device,
    queue: wgpu::Queue,
    demo: omshell_wgpu::Demo,
    // The texture currently handed to Blitz, and the one being rendered into.
    displayed: Option<(wgpu::Texture, ResourceId)>,
    next: Option<(wgpu::Texture, ResourceId)>,
}

impl DemoWidget {
    pub fn new() -> Self {
        Self {
            state: State::Suspended,
            start: Instant::now(),
        }
    }
}

impl Widget for DemoWidget {
    fn can_create_surfaces(&mut self, render_ctx: &mut dyn RenderContext) {
        // The wgpu backend exposes its Device/Queue here.
        if let Some(ctx) = render_ctx.renderer_specific_context() {
            if let Ok(handle) = ctx.downcast::<DeviceHandle>() {
                let demo = omshell_wgpu::Demo::new(&handle.device, wgpu::TextureFormat::Rgba8Unorm);
                self.state = State::Active(Box::new(Active {
                    device: handle.device.clone(),
                    queue: handle.queue.clone(),
                    demo,
                    displayed: None,
                    next: None,
                }));
            }
        }
    }

    fn destroy_surfaces(&mut self) {
        self.state = State::Suspended;
    }

    fn paint(
        &mut self,
        render_ctx: &mut dyn RenderContext,
        _styles: &ComputedStyles,
        width: u32,
        height: u32,
        _scale: f64,
    ) -> Scene {
        let mut scene = Scene::new();
        let time = self.start.elapsed().as_secs_f32();
        if let State::Active(active) = &mut self.state {
            if let Some(id) = active.render(render_ctx, time, width, height) {
                scene.fill(
                    Fill::NonZero,
                    Affine::IDENTITY,
                    PaintRef::Resource(ImageBrush {
                        image: id,
                        sampler: ImageSampler::default(),
                    }),
                    None,
                    &Rect::from_origin_size((0.0, 0.0), (width as f64, height as f64)),
                );
            }
        }
        scene
    }
}

impl Active {
    fn render(
        &mut self,
        ctx: &mut dyn RenderContext,
        time: f32,
        width: u32,
        height: u32,
    ) -> Option<ResourceId> {
        if width == 0 || height == 0 {
            return None;
        }

        // Drop the spare texture if the widget was resized.
        if self
            .next
            .as_ref()
            .is_some_and(|(tex, _)| tex.width() != width || tex.height() != height)
        {
            let (_, id) = self.next.take().unwrap();
            ctx.unregister_resource(id);
        }
        // Create + register the render target if we don't have one.
        if self.next.is_none() {
            let tex = create_texture(&self.device, width, height);
            let id = ctx
                .try_register_custom_resource(Box::new(tex.clone()))
                .expect("renderer must accept a wgpu texture resource");
            self.next = Some((tex, id));
        }

        // Take the id + an owned view, then drop the borrow of `self.next` so the
        // swap below can mutate it.
        let (id, view) = {
            let (tex, id) = self.next.as_ref().unwrap();
            (*id, tex.create_view(&wgpu::TextureViewDescriptor::default()))
        };

        self.demo.prepare(&self.queue, time, width as f32, height as f32);
        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor::default());
        {
            let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: None,
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    depth_slice: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: None,
                timestamp_writes: None,
                occlusion_query_set: None,
                multiview_mask: None,
            });
            self.demo.draw(&mut pass);
        }
        self.queue.submit(Some(encoder.finish()));

        // The texture we just drew becomes the displayed one; reuse the old one next.
        std::mem::swap(&mut self.next, &mut self.displayed);
        Some(id)
    }
}

fn create_texture(device: &wgpu::Device, width: u32, height: u32) -> wgpu::Texture {
    device.create_texture(&wgpu::TextureDescriptor {
        label: None,
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format: wgpu::TextureFormat::Rgba8Unorm,
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT
            | wgpu::TextureUsages::TEXTURE_BINDING
            | wgpu::TextureUsages::COPY_SRC,
        view_formats: &[],
    })
}
