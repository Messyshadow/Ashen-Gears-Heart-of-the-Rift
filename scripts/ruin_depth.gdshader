shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform sampler2D rough_texture : filter_linear_mipmap;
uniform vec4 base_color : source_color = vec4(1.0);
uniform float metalness = 0.0;
uniform bool has_texture = true;
uniform bool has_normal = false;
uniform bool has_roughness = false;
uniform float base_roughness = 0.80;
varying float world_depth;
void vertex() {
    world_depth = (MODEL_MATRIX * vec4(VERTEX,1.0)).z;
}
void fragment() {
    vec3 stone = base_color.rgb;
    if (has_texture) stone *= texture(base_texture,UV).rgb;
    stone *= COLOR.rgb;
    ALBEDO = stone;
    METALLIC = metalness;
    ROUGHNESS = has_roughness ? texture(rough_texture,UV).g : base_roughness;
    if (has_normal && world_depth > -7.5) NORMAL_MAP = texture(normal_texture,UV).rgb;
    if (world_depth < -8.0) {
        // Keep the cavern's shaded form; haze adds a small scattering floor
        // instead of replacing every face with a flat unlit silhouette.
        float far = clamp((-world_depth-8.0)/18.0,0.0,1.0);
        ALBEDO = stone * vec3(0.50,0.69,0.85) * (1.0-far*0.35);
        METALLIC = 0.0;
        ROUGHNESS = 0.95;
        EMISSION = mix(stone * vec3(0.06,0.12,0.18),vec3(0.011,0.025,0.039),far*0.65);
    }
}
