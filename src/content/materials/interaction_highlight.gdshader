shader_type spatial;
render_mode cull_front, unshaded;

uniform vec3 color : source_color = vec3(0,0,0);
uniform float glow = 4.0;
uniform float thickness : hint_range(0.0, 1.0, 0.01) = 0.05;
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
	VERTEX += thickness*NORMAL*0.1;
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION = snapped_position;
}

void fragment() {
	//if (FRONT_FACING) {
		//ALPHA = 0.1;
		//ALBEDO = color*0.5;
	//} else {
	ALPHA = 1.0;
	ALBEDO = color*glow;
	//}
	ALPHA_SCISSOR_THRESHOLD = 0.1;
	//ALPHA_HASH_SCALE = 1.0;
}