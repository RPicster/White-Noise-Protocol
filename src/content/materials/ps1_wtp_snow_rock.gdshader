// Shader originally from https://godotshaders.com/shader/ps1-psx-model/
// CC0 license
// Modified by Raffaele Picca for LD58 with tiling

shader_type spatial;
render_mode blend_mix,
	cull_back,
	depth_prepass_alpha,
	specular_disabled,
	vertex_lighting;

uniform vec3 LIGHT_DIR_WORLD = vec3(0.0, -1.0, 0.0); // direction the light points *toward* in world space

uniform bool affine_mapping = false;
uniform sampler2D snow_sparkle : source_color, filter_nearest_mipmap_anisotropic;
uniform sampler2D albedo : source_color, filter_nearest_mipmap_anisotropic;
uniform sampler2D albedo_side : source_color, filter_nearest_mipmap_anisotropic;
uniform float alpha_scissor : hint_range(0, 1) = 0.5;
uniform float jitter: hint_range(0, 1) = 0.25;
uniform ivec2 resolution = ivec2(320, 240);

uniform float side_offset : hint_range(-1.0, 1.0) = 0.5;
uniform float side_fade : hint_range(0.0, 1.0) = 0.1;

instance uniform vec3 tiling = vec3(1.0);


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
	// normal for up/side rock thingy
	//vec3 bg_normal = normal_tex_bg * 2.0 - 1.0;
	//bg_normal.z = sqrt(1.0 - bg_normal.x * bg_normal.x - bg_normal.y * bg_normal.y);
	vec3 normal_applied = NORMAL;
	vec3 up_vector_viewspace = mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
	float dot_product = dot(up_vector_viewspace, normal_applied);
	float mask = clamp(smoothstep(side_offset - side_fade, side_offset + side_fade, dot_product), 0.0, 1.0);
	
	vec2 uv = UV * tiling.xy;
	vec4 albedo_tex = texture(albedo, uv);
	vec4 albedo_side_tex = texture(albedo_side, uv);
	
	ALBEDO = mix(albedo_side_tex.rgb, albedo_tex.rgb, mask);
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
}