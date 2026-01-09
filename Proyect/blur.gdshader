shader_type spatial;
render_mode blend_mix, depth_draw_opaque;

uniform float edge_softness : hint_range(0.0, 1.0) = 0.2;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D noise_tex;

void fragment() {
    vec4 color = albedo;

    // Compute edge fade using object-space position
    vec3 p = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // approximate bounding box fade
    float d = min(
        min(abs(p.x), abs(p.y)),
        abs(p.z)
    );

    float alpha = smoothstep(edge_softness, edge_softness * 0.1, d);

    ALBEDO = color.rgb;
    ALPHA = alpha;
}
