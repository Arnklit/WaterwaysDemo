shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_roughness : hint_white;
uniform vec4 roughness_texture_channel;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform sampler2D texture_ambient_occlusion : hint_white;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect;

uniform sampler2D texture_depth : hint_black;
uniform float depth_scale;
uniform int depth_min_layers;
uniform int depth_max_layers;
uniform vec2 depth_flip;

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
varying vec3 world_vertex;
uniform float wetness_offset = 0.0;
uniform float wetness_transition_width = 1.0;
uniform sampler2D water_systemmap;
uniform mat4 water_systemmap_coords;

float water_altitude(vec3 pos) {
	vec3 pos_in_aabb = pos - water_systemmap_coords[0].xyz;
	vec2 pos_2d = vec2(pos_in_aabb.x, pos_in_aabb.z);
	float longest_side = water_systemmap_coords[1].x > water_systemmap_coords[1].z ? water_systemmap_coords[1].x : water_systemmap_coords[1].z;
	pos_2d = pos_2d / longest_side;
	float value = texture(water_systemmap, pos_2d).b;
	float height = value * water_systemmap_coords[1].y + water_systemmap_coords[0].y;
	return pos.y - (height + wetness_offset);
}

void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,-1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,-1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	world_vertex = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void fragment() {

	float altitude = clamp(water_altitude(world_vertex) / wetness_transition_width, 0.0, 1.0);
	
	vec4 albedo_tex = triplanar_texture(texture_albedo,uv1_power_normal,uv1_triplanar_pos);
	vec4 albedo_dark = albedo_tex * 0.80;
	ALBEDO = mix(albedo_dark.rgb, albedo.rgb, altitude) * albedo_tex.rgb;
	METALLIC = metallic;
	float roughness_tex = dot(triplanar_texture(texture_roughness,uv1_power_normal,uv1_triplanar_pos),roughness_texture_channel);
	float roughness_tex_dark = roughness_tex * 0.80;
	ROUGHNESS = mix(roughness_tex_dark, roughness_tex, altitude) * roughness;
	SPECULAR = specular;
	NORMALMAP = triplanar_texture(texture_normal,uv1_power_normal,uv1_triplanar_pos).rgb;
	NORMALMAP_DEPTH = normal_scale;
	AO = dot(triplanar_texture(texture_ambient_occlusion,uv1_power_normal,uv1_triplanar_pos),ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;
}
