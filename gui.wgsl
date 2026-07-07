struct VertexInput {
    @location(0) pos: vec2<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
    @location(3) mode: f32,
    @location(4) rect_size: vec2<f32>,   // width, height in pixels
    @location(5) corner_radius: f32,      // radius in pixels
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
    @location(1) color: vec4<f32>,
    @location(2) mode: f32,
    @location(3) local_pos: vec2<f32>,   // coordinates relative to center, in pixels
    @location(4) rect_size: vec2<f32>,
    @location(5) corner_radius: f32,
}

@group(0) @binding(0) var<uniform> screen_res: vec2<f32>;
@group(0) @binding(1) var font_sampler: sampler;
@group(0) @binding(2) var font_texture: texture_2d<f32>;

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    
    // Map screen pixel space [0, width] x [0, height] to NDC [-1, 1]
    let ndc_x = (in.pos.x / screen_res.x) * 2.0 - 1.0;
    let ndc_y = 1.0 - (in.pos.y / screen_res.y) * 2.0;
    out.position = vec4<f32>(ndc_x, ndc_y, 0.0, 1.0);
    
    out.uv = in.uv;
    out.color = in.color;
    out.mode = in.mode;
    
    // local_pos centers the coordinates on the quad, ranging from -size/2 to +size/2
    out.local_pos = (in.uv - vec2<f32>(0.5)) * in.rect_size;
    out.rect_size = in.rect_size;
    out.corner_radius = in.corner_radius;
    
    return out;
}

// 2D Signed Distance Field for a rounded box
fn sdRoundBox(p: vec2<f32>, b: vec2<f32>, r: f32) -> f32 {
    let q = abs(p) - b + vec2<f32>(r);
    return length(max(q, vec2<f32>(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    if (in.mode > 0.5) {
        // Text mode: Sample the font atlas (distance field texture)
        let sample_val = textureSample(font_texture, font_sampler, in.uv).r;
        
        // Anti-aliased alpha thresholding for SDF text
        let text_alpha = smoothstep(0.45, 0.55, sample_val);
        return vec4<f32>(in.color.rgb, in.color.a * text_alpha);
    } else {
        // Rounded Rectangle mode
        let half_size = in.rect_size * 0.5;
        let d = sdRoundBox(in.local_pos, half_size, in.corner_radius);
        
        // Anti-alias edge
        let alpha = smoothstep(1.0, -1.0, d);
        if (alpha <= 0.0) {
            discard;
        }
        return vec4<f32>(in.color.rgb, in.color.a * alpha);
    }
}
