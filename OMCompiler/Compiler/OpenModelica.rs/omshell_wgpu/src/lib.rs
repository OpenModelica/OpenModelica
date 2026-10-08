//! A small, self-contained WebGPU demo shared by every OMShell front-end: an
//! animated raymarched gyroid with a cosine colour palette and volumetric glow.
//! It draws a single full-screen triangle and does all the work in the fragment
//! shader (no vertex/index buffers), so the only thing a front-end must supply is
//! a `wgpu::Device`/`Queue`, the target texture format, and a render pass.
//!
//! - egui (native + web): built from `cc.wgpu_render_state` and driven by an
//!   `egui_wgpu` paint callback.
//! - dioxus web: built on a `wgpu::Surface` created from a `<canvas>` and driven
//!   by a `requestAnimationFrame` loop.
//!
//! The wgpu API here mirrors the egui_wgpu (eframe 0.34 / wgpu 29) call shapes so
//! the same types flow through the egui callback.

use bytemuck::{Pod, Zeroable};
use wgpu::util::DeviceExt as _;

#[repr(C)]
#[derive(Clone, Copy, Pod, Zeroable)]
struct Uniforms {
    time: f32,
    width: f32,
    height: f32,
    _pad: f32,
}

/// The demo's GPU resources. Build once with [`Demo::new`], then each frame call
/// [`Demo::prepare`] (writes the time/resolution uniform) and [`Demo::draw`]
/// (records the draw into a render pass).
pub struct Demo {
    pipeline: wgpu::RenderPipeline,
    bind_group: wgpu::BindGroup,
    uniforms: wgpu::Buffer,
}

impl Demo {
    pub fn new(device: &wgpu::Device, target_format: wgpu::TextureFormat) -> Self {
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("omshell-wgpu-demo"),
            source: wgpu::ShaderSource::Wgsl(include_str!("gyroid.wgsl").into()),
        });

        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("omshell-wgpu-demo"),
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStages::FRAGMENT,
                ty: wgpu::BindingType::Buffer {
                    ty: wgpu::BufferBindingType::Uniform,
                    has_dynamic_offset: false,
                    min_binding_size: wgpu::BufferSize::new(std::mem::size_of::<Uniforms>() as u64),
                },
                count: None,
            }],
        });

        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("omshell-wgpu-demo"),
            bind_group_layouts: &[Some(&bind_group_layout)],
            immediate_size: 0,
        });

        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("omshell-wgpu-demo"),
            layout: Some(&pipeline_layout),
            vertex: wgpu::VertexState {
                module: &shader,
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &shader,
                entry_point: Some("fs_main"),
                targets: &[Some(target_format.into())],
                compilation_options: wgpu::PipelineCompilationOptions::default(),
            }),
            primitive: wgpu::PrimitiveState::default(),
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview_mask: None,
            cache: None,
        });

        let uniforms = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("omshell-wgpu-demo"),
            contents: bytemuck::bytes_of(&Uniforms {
                time: 0.0,
                width: 1.0,
                height: 1.0,
                _pad: 0.0,
            }),
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::UNIFORM,
        });

        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("omshell-wgpu-demo"),
            layout: &bind_group_layout,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniforms.as_entire_binding(),
            }],
        });

        Self {
            pipeline,
            bind_group,
            uniforms,
        }
    }

    /// Update the time/resolution uniform for this frame. `time` is in seconds
    /// (it only drives animation, so any monotonic seconds value works);
    /// `width`/`height` are the target's pixel size (for the aspect ratio).
    pub fn prepare(&self, queue: &wgpu::Queue, time: f32, width: f32, height: f32) {
        queue.write_buffer(
            &self.uniforms,
            0,
            bytemuck::bytes_of(&Uniforms {
                time,
                width: width.max(1.0),
                height: height.max(1.0),
                _pad: 0.0,
            }),
        );
    }

    /// Record the full-screen draw into an in-progress render pass.
    pub fn draw(&self, pass: &mut wgpu::RenderPass<'_>) {
        pass.set_pipeline(&self.pipeline);
        pass.set_bind_group(0, &self.bind_group, &[]);
        pass.draw(0..3, 0..1);
    }
}
