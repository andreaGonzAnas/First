shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform sampler2D albedo_texture : source_color;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Sample the texture
    vec4 tex = texture(albedo_texture, UV);

    // Object-space view direction
    vec3 view_dir = normalize(-VERTEX); // outward from object center

    // Rim factor: 1 at edges, 0 inside
    float rim = 1.0 - max(0.0, dot(NORMAL, view_dir));

    // Invert rim so inside is fully visible, edges fade
    float alpha = 1.0 - smoothstep(0.0, edge_softness, rim);

    // Apply fade to texture
    ALBEDO = tex.rgb;
    ALPHA = tex.a * alpha;
}
