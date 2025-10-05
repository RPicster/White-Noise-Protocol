// Shader originally from https://godotshaders.com/shader/ps1-psx-model/
// CC0 license
// Modified by Raffaele Picca for LD58 with tiling

shader_type spatial;
render_mode blend_mix,
	cull_disabled,
	depth_prepass_alpha,
	specular_disabled;

uniform bool affine_mapping = false;
uniform float scroll_speed = 0.0;
uniform float glow = 0.0;
uniform sampler2D albedo : source_color, filter_nearest;
uniform vec2 tiling = vec2(1.0);
uniform float backlight = 0.0;
uniform float alpha_scissor : hint_range(0, 1) = 0.5;
uniform float jitter: hint_range(0, 1) = 0.25;
uniform ivec2 resolution = ivec2(640, 360);

vec4 snap_to_position(vec4 base_position)
{
	vec4 snapped_position = base_position;
	snapped_position.xyz = base_position.xyz / base_position.w;

	vec2 snap_resulotion = floor(vec2(resolution) * (1.0 - jitter));
	snapped_position.x = floor(snap_resulotion.x * snapped_position.x) / snap_resulotion.x;
	snapped_position.y = floor(snap_resulotion.y * snapped_position.y) / snap_resulotion.y;

	snapped_position.xyz *= base_position.w;
	return snapped_position;
}

void vertex()
{
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (affine_mapping)
	{
		POSITION = snapped_position;
		POSITION /= abs(POSITION.w);
	}
	else
	{
		POSITION = snapped_position;
	}
}

void fragment() {
	vec2 uv_scrolling = UV * tiling + vec2(scroll_speed*fract(TIME), 0.0);
	vec2 uv = UV * tiling;
	vec4 color_base = COLOR;
	vec4 texture_color = texture(albedo, uv_scrolling);

	ALBEDO = (color_base * texture_color).rgb;
	ALPHA = texture_color.a * color_base.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;

	vec2 tex_size = vec2(textureSize(albedo, 0));
	vec2 nearest_texel = (floor(uv * tex_size) + 0.5) / tex_size;
	vec2 offset = nearest_texel - uv;
	vec2 x_derivative = dFdx(uv);
	vec2 y_derivative = dFdy(uv);

	offset /= x_derivative.s*y_derivative.t - y_derivative.s*x_derivative.t;
	vec2 frag_delta = vec2
	(
	offset.x*y_derivative.t - offset.y*y_derivative.s,
	offset.y*x_derivative.s - offset.x*x_derivative.t
	);
	vec3 view_delta = dFdx(VERTEX)*frag_delta.s + dFdy(VERTEX)*frag_delta.t;
	LIGHT_VERTEX += view_delta;
	EMISSION = glow * ALBEDO;
	BACKLIGHT = ALBEDO * backlight;
}